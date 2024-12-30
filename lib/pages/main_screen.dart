import 'package:flutter/material.dart';
import 'gsr_value_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terapi Iontophoresis',
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.play_circle_filled, size: 30, color: Colors.white),
            label: const Text(
              'Mulai Terapi',
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              backgroundColor: Colors.blue[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GSRValueScreen()),
              );
            },
          ),
        ),
      ),
    );
  }
}
