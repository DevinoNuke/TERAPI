import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'data_gsr_screen.dart';
import 'start_therapy_screen.dart';

class GSRValueScreen extends StatefulWidget {
  const GSRValueScreen({super.key});

  @override
  State<GSRValueScreen> createState() => _GSRValueScreenState();
}

class _GSRValueScreenState extends State<GSRValueScreen> {
  late MqttServerClient client;
  String gsrValue = '0';
  bool mqttConnected = false;
  final String topicName = 'sensor/gsr';

  @override
  void initState() {
    super.initState();
    setupMqttClient();
    connectClient();
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
      debugPrint('Menghubungkan ke MQTT broker...');
      await client.connect();
      
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        debugPrint('Terhubung ke MQTT broker');
        client.subscribe(topicName, MqttQos.atLeastOnce);
        
        client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
          if (c == null) return;
          final recMessage = c[0].payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
          
          if (mounted) {
            setState(() {
              gsrValue = payload;
            });
          }
          debugPrint('Nilai GSR diterima: $payload dari topic: ${c[0].topic}');
        });
      } else {
        debugPrint('Koneksi gagal - memutuskan, status: ${client.connectionStatus}');
        client.disconnect();
        // Mencoba koneksi ulang
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            connectClient();
          }
        });
      }
    } catch (e) {
      debugPrint('Exception: $e');
      client.disconnect();
      // Mencoba koneksi ulang setelah error
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          connectClient();
        }
      });
    }
  }

  void onConnected() {
    setState(() => mqttConnected = true);
    debugPrint('Terhubung ke MQTT Broker');
  }

  void onDisconnected() {
    setState(() => mqttConnected = false);
    debugPrint('Terputus dari MQTT Broker');
  }

  void onSubscribed(String topic) {
    debugPrint('Berlangganan ke topic: $topic');
  }

  void onSubscribeFail(String topic) {
    debugPrint('Gagal berlangganan ke topic: $topic');
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monitor Terapi',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Status Koneksi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: mqttConnected ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: mqttConnected ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mqttConnected ? Icons.wifi : Icons.wifi_off,
                      color: mqttConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mqttConnected ? 'Terhubung' : 'Terputus',
                      style: TextStyle(
                        color: mqttConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Card GSR Value
              Expanded(
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
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.monitor_heart_outlined,
                            size: 48,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nilai GSR',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              gsrValue,
                              style: const TextStyle(
                                fontSize: 64,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                context,
                                Icons.analytics_outlined,
                                'Data GSR',
                                DataGSRScreen(),
                              ),
                              _buildActionButton(
                                context,
                                Icons.play_circle_outline,
                                'Mulai Terapi',
                                const StartTherapyScreen(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Widget nextPage) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white10,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
