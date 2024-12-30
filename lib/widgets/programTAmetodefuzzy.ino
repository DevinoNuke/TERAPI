#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <Fuzzy.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

const char* ssid = "IZAL_EXT";
const char* password = "anakkeduaganteng";

const char* mqtt_server = "mqtt-dashboard.com";
const int mqtt_port = 1883;

const int gsrPin = 32;
const int relay = 26;
const int pwmPin = 25;
int gsrValue = 0;

WiFiClient espClient;
PubSubClient client(espClient);

unsigned long therapyStartTime = 0;
unsigned long therapyDuration = 60 * 1000; // Akan diupdate oleh fuzzy logic
bool therapyActive = false;

int voltageLevel = 0;
const int maxVoltage = 20;

Fuzzy *fuzzy = new Fuzzy();

// Deklarasi FuzzySet untuk digunakan dalam aturan
FuzzySet *gsrLow, *gsrMedium, *gsrHigh;
FuzzySet *voltageLow, *voltageMedium, *voltageHigh;
FuzzySet *durationShort, *durationMedium, *durationLong;

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  if (strcmp(topic, "therapy/control") == 0) {
    if (message == "start") {
      if (!therapyActive) {
        startTherapy();
      }
    } else if (message == "stop") {
      if (therapyActive) {
        stopTherapy();
      }
    }
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Menghubungkan ke broker MQTT...");
    if (client.connect("ESP32Client", mqtt_username, mqtt_password)) {
      Serial.println("Terhubung");
      client.subscribe("gsr/data");
      client.subscribe("therapy/control"); // Tambahkan subscribe ke topik kontrol
    } else {
      Serial.print("Gagal, rc=");
      Serial.print(client.state());
      Serial.println(" mencoba lagi dalam 5 detik");
      delay(5000);
    }
  }
}

void setVoltage(int level) {
  if (level >= 0 && level <= 100) {
    int voltageInVolts = map(level, 0, 100, 0, 24);
    if (voltageInVolts > maxVoltage) {
      Serial.println("Tegangan melebihi batas! Mematikan power supply.");
      digitalWrite(relay, HIGH);
      therapyActive = false;
    } else {
      voltageLevel = level;
      int dutyCycle = map(voltageLevel, 0, 100, 0, 255);
      ledcWrite(pwmPin, dutyCycle);
      
      display.clearDisplay();
      display.setTextSize(1);
      display.setTextColor(SSD1306_WHITE);
      display.setCursor(0, 0);
      display.print("Tegangan: ");
      display.print(voltageInVolts);
      display.println(" V");
      display.setCursor(0, 20);
      display.print("Level: ");
      display.print(level);
      display.println("%");
      display.display();
      
      Serial.print("Tegangan diatur ke: ");
      Serial.print(voltageInVolts);
      Serial.println("V");
    }
  } else {
    Serial.println("Nilai tegangan tidak valid (0-100).");
  }
}

void startTherapy() {
  therapyStartTime = millis();
  therapyActive = true;
  digitalWrite(relay, LOW);
  Serial.println("Terapi dimulai.");
  Serial.print("Durasi terapi: ");
  Serial.print(therapyDuration / 60000);
  Serial.println(" menit");
  Serial.print("Tegangan: ");
  Serial.print(map(voltageLevel, 0, 100, 0, 24));
  Serial.println(" V");
  
  // Publish status terapi
  client.publish("therapy/status", "running");
}

void stopTherapy() {
  therapyActive = false;
  digitalWrite(relay, HIGH);
  Serial.println("Terapi selesai.");
  
  // Publish status terapi
  client.publish("therapy/status", "stopped");
}

void setupFuzzy() {
  // Input: GSR
  FuzzyInput *gsr = new FuzzyInput(1);
  gsrLow = new FuzzySet(0, 0, 20, 50);
  gsrMedium = new FuzzySet(80, 100, 150, 200);
  gsrHigh = new FuzzySet(210, 250, 300, 350);
  gsr->addFuzzySet(gsrLow);
  gsr->addFuzzySet(gsrMedium);
  gsr->addFuzzySet(gsrHigh);
  fuzzy->addFuzzyInput(gsr);

  // Output: Voltage
  FuzzyOutput *voltage = new FuzzyOutput(1);
  voltageLow = new FuzzySet(0, 0, 5, 10);
  voltageMedium = new FuzzySet(8, 12, 12, 16);
  voltageHigh = new FuzzySet(14, 18, 24, 24);
  voltage->addFuzzySet(voltageLow);
  voltage->addFuzzySet(voltageMedium);
  voltage->addFuzzySet(voltageHigh);
  fuzzy->addFuzzyOutput(voltage);

  // Output: Duration
  FuzzyOutput *duration = new FuzzyOutput(2);
  durationShort = new FuzzySet(0, 0, 10, 20);
  durationMedium = new FuzzySet(15, 25, 25, 35);
  durationLong = new FuzzySet(30, 40, 60, 60);
  duration->addFuzzySet(durationShort);
  duration->addFuzzySet(durationMedium);
  duration->addFuzzySet(durationLong);
  fuzzy->addFuzzyOutput(duration);

  // Fuzzy Rules
  FuzzyRuleAntecedent *ifGsrLow = new FuzzyRuleAntecedent();
  ifGsrLow->joinSingle(gsrLow);
  FuzzyRuleConsequent *thenVoltageHighDurationLong = new FuzzyRuleConsequent();
  thenVoltageHighDurationLong->addOutput(voltageHigh);
  thenVoltageHighDurationLong->addOutput(durationLong);
  FuzzyRule *fuzzyRule1 = new FuzzyRule(1, ifGsrLow, thenVoltageHighDurationLong);
  fuzzy->addFuzzyRule(fuzzyRule1);

  FuzzyRuleAntecedent *ifGsrMedium = new FuzzyRuleAntecedent();
  ifGsrMedium->joinSingle(gsrMedium);
  FuzzyRuleConsequent *thenVoltageMediumDurationMedium = new FuzzyRuleConsequent();
  thenVoltageMediumDurationMedium->addOutput(voltageMedium);
  thenVoltageMediumDurationMedium->addOutput(durationMedium);
  FuzzyRule *fuzzyRule2 = new FuzzyRule(2, ifGsrMedium, thenVoltageMediumDurationMedium);
  fuzzy->addFuzzyRule(fuzzyRule2);

  FuzzyRuleAntecedent *ifGsrHigh = new FuzzyRuleAntecedent();
  ifGsrHigh->joinSingle(gsrHigh);
  FuzzyRuleConsequent *thenVoltageLowDurationShort = new FuzzyRuleConsequent();
  thenVoltageLowDurationShort->addOutput(voltageLow);
  thenVoltageLowDurationShort->addOutput(durationShort);
  FuzzyRule *fuzzyRule3 = new FuzzyRule(3, ifGsrHigh, thenVoltageLowDurationShort);
  fuzzy->addFuzzyRule(fuzzyRule3);
}

void setup() {
  Serial.begin(115200);
  
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("OLED gagal diinisialisasi"));
    for (;;);
  }

  display.clearDisplay();
  setup_wifi();
  
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);

  pinMode(relay, OUTPUT);
  digitalWrite(relay, HIGH);
  
  ledcAttach(pwmPin, 5000, 8);
  pinMode(gsrPin, INPUT);
  
  setupFuzzy();
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  gsrValue = analogRead(gsrPin);
  
  // Proses fuzzy logic
  fuzzy->setInput(1, gsrValue);
  fuzzy->fuzzify();
  float optimalVoltage = fuzzy->defuzzify(1);
  float optimalDuration = fuzzy->defuzzify(2);

  // Update display dan publish data
  updateDisplay(gsrValue, optimalVoltage, optimalDuration);
  publishData(gsrValue);

  if (therapyActive) {
    if (millis() - therapyStartTime >= therapyDuration) {
      stopTherapy();
    }
  }

  delay(500);
}

void publishData(int gsrValue) {
  String gsrStr = String(gsrValue);
  client.publish("gsr/data", gsrStr.c_str());
  
  if (therapyActive) {
    client.publish("therapy/status", "running");
  }
}

void updateDisplay(int gsrValue, float voltage, float duration) {
  display.clearDisplay();
  display.setCursor(0, 0);
  display.setTextSize(1);
  display.print("GSR: ");
  display.println(gsrValue);
  display.print("Voltage: ");
  display.print(voltage);
  display.println("V");
  display.print("Duration: ");
  display.print(duration);
  display.println("min");
  display.print("Status: ");
  display.println(therapyActive ? "Running" : "Stopped");
  display.display();
}