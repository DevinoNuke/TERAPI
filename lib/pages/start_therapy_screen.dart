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
  int timeRemaining = 300; // Default 5 menit dalam detik
  Timer? timer;
  TextEditingController minuteController = TextEditingController(text: '5');
  TextEditingController jeniskelamincontroller = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController teganganController = TextEditingController(text: '12');
  late MqttServerClient client;
  bool mqttConnected = false;
  final String topicName = 'therapy/status';
  final String sensorDataTopic = 'sensor/datagsr';
  final String controlTopic = 'therapy/control';
  
  // Tambahkan variabel untuk menyimpan nilai GSR
  String gsrValue1 = '0';
  String gsrValue2 = '0';
  String voltage = '0';  // Tambahkan untuk menyimpan tegangan
  String duration = '0'; // Tambahkan untuk menyimpan durasi
  
  // Untuk menyimpan data historis GSR selama terapi
  List<double> gsrAvgHistory = [];

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
          
          // Parse JSON dan simpan nilai GSR
          if (c[0].topic == topicName) {
            try {
              final Map<String, dynamic> data = Map<String, dynamic>.from(
                json.decode(payload));
              setState(() {
                gsrValue1 = data['gsr1'].toString();
                gsrValue2 = data['gsr2'].toString();
                
                // Tambahkan untuk menyimpan voltage dan duration jika ada
                if (data.containsKey('voltage')) {
                  voltage = data['voltage'].toString();
                }
                if (data.containsKey('duration')) {
                  duration = data['duration'].toString();
                }
                
                // Jika terapi sedang berjalan, tambahkan nilai GSR sebagai angka asli, bukan pembagian
                if (isTherapyStarted) {
                  double gsr1 = double.tryParse(gsrValue1) ?? 0;
                  double gsr2 = double.tryParse(gsrValue2) ?? 0;
                  // Simpan rata-rata sebagai nilai penuh (bukan dibagi lagi)
                  double avg = (gsr1 + gsr2) / 2;
                  gsrAvgHistory.add(avg);
                }
              });
            } catch (e) {
              debugPrint('Error parsing JSON: $e');
            }
          }
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

    // Publish ke MQTT dengan topic therapy/control
    publishControlMessage('start');

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

    // Publish ke MQTT dengan topic therapy/control
    publishControlMessage('stop');
    
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

  void publishControlMessage(String command) {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      final int duration = int.tryParse(minuteController.text) ?? 5;
      
      final payload = {
        "command": command,
        "duration": duration
      };
      
      builder.addString(json.encode(payload));
      client.publishMessage(controlTopic, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('Pesan kontrol terkirim ke topic: $controlTopic dengan payload: ${json.encode(payload)}');
    }
  }

  void publishSensorData() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      // Perhitungan GSR yang benar
      int gsrAverage = 0;
      if (gsrAvgHistory.isNotEmpty) {
        // Menghitung rata-rata dari history
        double sum = gsrAvgHistory.reduce((a, b) => a + b);
        gsrAverage = (sum / gsrAvgHistory.length).round(); // Dibulatkan ke integer
      } else {
        // Jika tidak ada history, gunakan nilai GSR terakhir
        int gsr1 = int.tryParse(gsrValue1) ?? 0;
        int gsr2 = int.tryParse(gsrValue2) ?? 0;
        gsrAverage = ((gsr1 + gsr2) / 2).round(); // Dibulatkan ke integer
      }
      
      // Pastikan username tidak kosong
      if (usernameController.text.isEmpty) {
        debugPrint('Username kosong, tidak dapat mengirim data');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username tidak boleh kosong'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final builder = MqttClientPayloadBuilder();
      final payload = {
        "username": usernameController.text,
        "jenis_kelamin": jeniskelamincontroller.text,
        "tegangan": voltage != '0' ? "$voltage V" : "${teganganController.text} V",
        "waktu": "${minuteController.text} Menit",
        "data": gsrAverage.toString(), // Kirim sebagai string tapi tanpa desimal
      };
      builder.addString(json.encode(payload));
      client.publishMessage(sensorDataTopic, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('Data sensor terkirim ke topic: $sensorDataTopic dengan nilai rata-rata GSR: $gsrAverage');
    }
  }

  @override
  void dispose() {
    client.disconnect();
    timer?.cancel();
    minuteController.dispose();
    usernameController.dispose();
    teganganController.dispose();
    jeniskelamincontroller.dispose();
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
                    
                    DropdownButtonFormField<String>(
                      value: jeniskelamincontroller.text.isEmpty ? null : jeniskelamincontroller.text,
                      dropdownColor: Colors.blue[900],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kelamin',
                        labelStyle: TextStyle(color: Colors.lightBlueAccent),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.lightBlueAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.lightBlueAccent),
                        ),
                      ),
                      onChanged: (String? value) {
                        setState(() {
                          jeniskelamincontroller.text = value ?? '';
                        });
                      },
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'Laki-laki',
                          child: Text('Laki-laki', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Perempuan',
                          child: Text('Perempuan', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // TextField(
                    //   controller: teganganController,
                    //   keyboardType: TextInputType.number,
                    //   style: const TextStyle(color: Colors.white),
                    //   decoration: const InputDecoration(
                    //     labelText: 'Tegangan (V)',
                    //     labelStyle: TextStyle(color: Colors.lightBlueAccent),
                    //     enabledBorder: UnderlineInputBorder(
                    //       borderSide: BorderSide(color: Colors.lightBlueAccent),
                    //     ),
                    //     focusedBorder: UnderlineInputBorder(
                    //       borderSide: BorderSide(color: Colors.lightBlueAccent),
                    //     ),
                    //   ),
                    // ),
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
