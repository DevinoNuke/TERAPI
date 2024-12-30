import 'package:flutter/material.dart';
import 'data_gsr_screen.dart';
import 'start_therapy_screen.dart';

class GSRValueScreen extends StatelessWidget {
  const GSRValueScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GSR Value Monitoring',
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
                      'GSR VALUE',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '1250', // Dynamic GSR value here
                      style: TextStyle(
                        fontSize: 48,
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(context, Icons.bar_chart, 'Data GSR',
                            DataGSRScreen()),
                        _buildActionButton(context, Icons.play_arrow,
                            'Start Therapy', const StartTherapyScreen()),
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
