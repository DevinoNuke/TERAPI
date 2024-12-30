import 'package:flutter/material.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
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

  void startTherapy() {
    setState(() {
      isTherapyStarted = true;
    });

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

  @override
  void dispose() {
    timer?.cancel();
    minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Therapy Session',
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
        child: SingleChildScrollView(
          child: Padding(
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
                          'Time Remaining',
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
                        const SizedBox(height: 10),
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
                                labelText: 'Minute',
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
                          const SizedBox(height: 20),
                        ],
                        OutlinedButton.icon(
                          icon: Icon(
                            isTherapyStarted ? Icons.stop : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          label: Text(
                            isTherapyStarted ? 'Stop Therapy' : 'Start Therapy',
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
              ],
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
        '$minutes min',
        style: const TextStyle(color: Colors.lightBlueAccent),
      ),
    );
  }
}
