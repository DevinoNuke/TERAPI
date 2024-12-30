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
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.blue[900],
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Nilai GSR',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      gsrValue,
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                            context, Icons.bar_chart, 'Data GSR', DataGSRScreen()),
                        _buildActionButton(context, Icons.play_arrow,
                            'Mulai Terapi', const StartTherapyScreen()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlinedButton _buildActionButton(
      BuildContext context, IconData icon, String label, Widget nextPage) {
    return OutlinedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.lightBlueAccent)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        backgroundColor: Colors.blue[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(color: Colors.blue[600]!, width: 2),
      ),
      onPressed: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => nextPage));
      },
    );
  }
}
