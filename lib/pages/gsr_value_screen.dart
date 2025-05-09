import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'data_gsr_screen.dart';
import 'start_therapy_screen.dart';

class GSRValueScreen extends StatefulWidget {
  const GSRValueScreen({super.key});

  @override
  State<GSRValueScreen> createState() => _GSRValueScreenState();
}

class _GSRValueScreenState extends State<GSRValueScreen> {
  late MqttServerClient client;
  String gsrValue1 = '0';
  String gsrValue2 = '0';
  bool mqttConnected = false;
  final String topicName = 'sensor/realtimegsr';

  String getPatientStatus() {
    try {
      double gsr1 = double.parse(gsrValue1);
      double gsr2 = double.parse(gsrValue2);
      double rataRata = (gsr1 + gsr2) / 2;
      
      if (rataRata > 300) {
        return 'Resistansi Kulit Tinggi';
      } else if (rataRata > 150) {
        return 'Resistansi Kulit Sedang';
      } else {
        return 'Resistansi Kulit Normal';
      }
    } catch (e) {
      return 'Tidak Diketahui';
    }
  }

  Color getStatusColor() {
    try {
      double gsr1 = double.parse(gsrValue1);
      double gsr2 = double.parse(gsrValue2);
      double rataRata = (gsr1 + gsr2) / 2;
      
      if (rataRata > 300) {
        return Colors.blue;
      } else if (rataRata > 150) {
        return Colors.amber;
      } else {
        return Colors.green;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

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
            try {
              // Parse payload sebagai JSON
              final Map<String, dynamic> data = Map<String, dynamic>.from(
                  json.decode(payload));
              setState(() {
                gsrValue1 = data['gsr1'].toString();
                gsrValue2 = data['gsr2'].toString();
              });
            } catch (e) {
              debugPrint('Error parsing JSON: $e');
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data GSR diterima dari topic: ${c[0].topic}'),
            ),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Koneksi gagal - memutuskan, status: ${client.connectionStatus}'),
          ),
        );
        client.disconnect();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            connectClient();
          }
        });
      }
    } catch (e) {
      debugPrint('Exception: $e');
      client.disconnect();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          connectClient();
        }
      });
    }
  }

  void onConnected() {
    setState(() => mqttConnected = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terhubung ke MQTT Broker'),
      ),
    );
  }

  void onDisconnected() {
    setState(() => mqttConnected = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terputus dari MQTT Broker'),
      ),
    );
  }

  void onSubscribed(String topic) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berlangganan ke topic: $topic'),
      ),
    );
  }

  void onSubscribeFail(String topic) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal berlangganan ke topic: $topic'),
      ),
    );
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
              colors: [Colors.blue[500]!, Colors.blue[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await connectClient();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
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
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[500]!, Colors.blue[600]!],
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
                          
                          // GSR 1 Value
                          const Text(
                            'Nilai GSR 1',
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
                              gsrValue1,
                              style: const TextStyle(
                                fontSize: 64,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // GSR 2 Value
                          const SizedBox(height: 24),
                          const Text(
                            'Nilai GSR 2',
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
                              gsrValue2,
                              style: const TextStyle(
                                fontSize: 64,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // Status pasien berdasarkan nilai GSR
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: getStatusColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: getStatusColor(),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  getPatientStatus() == 'Resistansi Kulit Tinggi' 
                                      ? Icons.signal_cellular_alt 
                                      : getPatientStatus() == 'Resistansi Kulit Sedang'
                                          ? Icons.signal_cellular_alt_2_bar
                                          : Icons.signal_cellular_alt_1_bar,
                                  color: getStatusColor(),
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Kondisi Pasien',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        getPatientStatus(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: getStatusColor(),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Widget nextPage) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue[900],
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
