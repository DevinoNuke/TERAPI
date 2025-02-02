import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

class StartTherapyScreen extends StatefulWidget {
  const StartTherapyScreen({super.key});

  @override
  State<StartTherapyScreen> createState() => StartTherapyScreenState();
}

class StartTherapyScreenState extends State<StartTherapyScreen> {
  bool isTherapyStarted = false;
  int timeRemaining = 1800; // Default 30 menit dalam detik
  Timer? timer;
  TextEditingController minuteController = TextEditingController(text: '30');
  TextEditingController usernameController = TextEditingController();
  TextEditingController teganganController = TextEditingController(text: '20');
  late MqttServerClient client;
  bool mqttConnected = false;
  final String topicName = 'therapy/status';
  final String sensorDataTopic = 'sensor/data';

  @override
  void initState() {
    super.initState();
    setupMqttClient();
    connectClient();
    minuteController.addListener(() {
      if (!isTherapyStarted) {
        int? minutes = int.tryParse(minuteController.text);
        if (minutes != null) {
          setState(() {
            timeRemaining = minutes * 60;
          });
        }
      }
    });
  }

  Future<void> setupMqttClient() async {
    client = MqttServerClient.withPort('broker.emqx.io', 'flutter_client', 1883);
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    
    client.connectionMessage = connMessage;
  }

  Future<void> connectClient() async {
    try {
      debugPrint('Connecting to MQTT broker...');
      await client.connect();
      
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        debugPrint('Connected to MQTT broker successfully');
        client.subscribe(topicName, MqttQos.atLeastOnce);
        
        client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
          if (c == null) return;
          final recMessage = c[0].payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
          debugPrint('Pesan diterima: $payload dari topic: ${c[0].topic}');
        });
      } else {
        debugPrint('Connection failed - disconnecting, status is ${client.connectionStatus}');
        client.disconnect();
      }
    } catch (e) {
      debugPrint('Exception: $e');
      client.disconnect();
    }
  }

  // Callback functions
  void onConnected() {
    setState(() => mqttConnected = true);
    debugPrint('Connected to MQTT Broker');
  }

  void onDisconnected() {
    setState(() => mqttConnected = false);
    debugPrint('Disconnected from MQTT Broker');
  }

  void onSubscribed(String topic) {
    debugPrint('Subscribed to topic: $topic');
  }

  void onSubscribeFail(String topic) {
    debugPrint('Failed to subscribe to topic: $topic');
  }

  void startTherapy() {
    setState(() {
      isTherapyStarted = true;
    });

    // Publish status ke MQTT
    publishMessage('start');

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeRemaining > 0) {
          timeRemaining--;
        } else {
          stopTherapy();
        }
      });
    });
  }

  void stopTherapy() {
    setState(() {
      isTherapyStarted = false;
      timer?.cancel();
      // Reset ke waktu yang diinput user
      int? minutes = int.tryParse(minuteController.text);
      timeRemaining = (minutes ?? 30) * 60;
    });

    // Publish status ke MQTT
    publishMessage('stop');
    
    // Publish data sensor ke topic sensor/data
    publishSensorData();

    // Tampilkan dialog notifikasi
    showTherapyCompletionDialog();
  }

  void showTherapyCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User harus menekan tombol untuk menutup
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Container(
            color: Colors.black,
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text('Terapi Selesai', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          content: Container(
            color: Colors.black,
            child: const Text(
              'Sesi terapi Anda telah selesai. Terima kasih telah menggunakan layanan kami.',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Tutup',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
          backgroundColor: Colors.black,
          elevation: 5,
        );
      },
    );
  }

  void setTime(int minutes) {
    if (!isTherapyStarted) {
      setState(() {
        minuteController.text = minutes.toString();
        timeRemaining = minutes * 60;
      });
    }
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void publishMessage(String message) {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      final payload = {
        "username": usernameController.text,
        "tegangan": "${teganganController.text} V",
        "waktu": "${minuteController.text} Menit",
        "data": "20.2"
      };
      builder.addString(json.encode(payload));
      client.publishMessage(topicName, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void publishSensorData() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      final payload = {
        "username": usernameController.text,
        "tegangan": "${teganganController.text} V",
        "waktu": "${minuteController.text} Menit",
        "data": "20.2"
      };
      builder.addString(json.encode(payload));
      client.publishMessage(sensorDataTopic, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('Data sensor terkirim ke topic: $sensorDataTopic');
    }
  }

  @override
  void dispose() {
    client.disconnect();
    timer?.cancel();
    minuteController.dispose();
    usernameController.dispose();
    teganganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sesi Terapi',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[800]!, Colors.blue[900]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: Colors.lightBlueAccent),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.lightBlueAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.lightBlueAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: teganganController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Tegangan (V)',
                        labelStyle: TextStyle(color: Colors.lightBlueAccent),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.lightBlueAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.lightBlueAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Waktu Terapi',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatTime(timeRemaining),
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    if (!isTherapyStarted) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeButton(20),
                          const SizedBox(width: 10),
                          _buildTimeButton(40),
                          const SizedBox(width: 10),
                          _buildTimeButton(60),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: minuteController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Menit',
                            labelStyle: TextStyle(color: Colors.lightBlueAccent),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.lightBlueAccent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.lightBlueAccent),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    
                    OutlinedButton.icon(
                      icon: Icon(
                        isTherapyStarted ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      label: Text(
                        isTherapyStarted ? 'Berhenti Terapi' : 'Mulai Terapi',
                        style: const TextStyle(color: Colors.lightBlueAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        backgroundColor: isTherapyStarted
                            ? Colors.red[800]
                            : Colors.blue[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                            color: isTherapyStarted
                                ? Colors.red[600]!
                                : Colors.blue[600]!,
                            width: 2),
                      ),
                      onPressed: () {
                        if (usernameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mohon isi username terlebih dahulu'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (isTherapyStarted) {
                          stopTherapy();
                        } else {
                          startTherapy();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(int minutes) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        backgroundColor: Colors.blue[800],
        side: BorderSide(color: Colors.blue[600]!, width: 1),
      ),
      onPressed: () => setTime(minutes),
      child: Text(
        '$minutes Menit',
        style: const TextStyle(color: Colors.lightBlueAccent),
      ),
    );
  }
}
