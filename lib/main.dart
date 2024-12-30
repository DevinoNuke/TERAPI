import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iontophoresis Therapy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Iontophoresis Therapy',
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
            icon: Icon(Icons.play_circle_filled, size: 30, color: Colors.white),
            label: Text(
              'Start Therapy',
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              backgroundColor: Colors.blue[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GSRValueScreen()),
              );
            },
          ),
        ),
      ),
    );
  }
}

class GSRValueScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
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
                    Text(
                      'GSR VALUE',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1250', // Dynamic GSR value here
                      style: TextStyle(
                        fontSize: 48,
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(context, Icons.bar_chart, 'Data GSR',
                            DataGSRScreen()),
                        _buildActionButton(context, Icons.play_arrow,
                            'Start Therapy', StartTherapyScreen()),
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
      label: Text(label, style: TextStyle(color: Colors.lightBlueAccent)),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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

class StartTherapyScreen extends StatefulWidget {
  @override
  _StartTherapyScreenState createState() => _StartTherapyScreenState();
}

class _StartTherapyScreenState extends State<StartTherapyScreen> {
  Timer? _timer;
  int _minutes = 5;
  int _seconds = 0;
  final TextEditingController _controller = TextEditingController(text: '5');
  bool isRunning = false;

  void startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_minutes > 0 || _seconds > 0) {
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else {
            _seconds = 59;
            if (_minutes > 0) {
              _minutes--;
            }
          }
        });
      } else {
        _timer!.cancel();
        setState(() {
          isRunning = false;
        });
      }
    });
  }

  void setTime() {
    setState(() {
      _minutes = int.tryParse(_controller.text) ?? 5;
      _seconds = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Therapy Timer',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
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
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '$_minutes:${_seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Set time (in minutes)',
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.lightBlueAccent),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setTime();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 25),
                          backgroundColor: Colors.blue[800],
                        ),
                        child: Text('Set',
                            style: TextStyle(color: Colors.lightBlueAccent)),
                      ),
                      ElevatedButton(
                        onPressed: isRunning
                            ? null
                            : () {
                                startTimer();
                                setState(() {
                                  isRunning = true;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 25),
                          backgroundColor: Colors.blue[800],
                        ),
                        child: Text('Start',
                            style: TextStyle(color: Colors.lightBlueAccent)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DataGSRScreen extends StatelessWidget {
  final List<Map<String, dynamic>> data = [
    {'no': 1, 'gsr': 1000, 'time': '5 mins', 'voltage': '10V'},
    {'no': 2, 'gsr': 902, 'time': '4 mins', 'voltage': '10V'},
    {'no': 3, 'gsr': 893, 'time': '6 mins', 'voltage': '9V'},
    {'no': 4, 'gsr': 978, 'time': '5 mins', 'voltage': '8V'},
    {'no': 5, 'gsr': 756, 'time': '3 mins', 'voltage': '10V'},
    {'no': 6, 'gsr': 732, 'time': '7 mins', 'voltage': '9V'},
    {'no': 7, 'gsr': 656, 'time': '4 mins', 'voltage': '8V'},
    {'no': 8, 'gsr': 636, 'time': '2 mins', 'voltage': '10V'},
    {'no': 9, 'gsr': 555, 'time': '6 mins', 'voltage': '9V'},
    {'no': 10, 'gsr': 105, 'time': '5 mins', 'voltage': '7V'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data GSR, Therapy Time & Voltage',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
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
        padding: const EdgeInsets.all(0), // Remove padding
        child: LayoutBuilder(
          builder: (context, constraints) {
            double fontSize = constraints.maxWidth > 600 ? 18 : 14;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.blue[900],
                margin: EdgeInsets.all(0), // Remove margin
                child: Padding(
                  padding:
                      const EdgeInsets.all(8.0), // Adjust padding if needed
                  child: DataTable(
                    columnSpacing: 40,
                    dataRowHeight: 50, // Adjust row height if needed
                    columns: [
                      DataColumn(
                          label: Text(
                        'No.',
                        style: TextStyle(
                            fontSize: fontSize, color: Colors.lightBlueAccent),
                      )),
                      DataColumn(
                          label: Text(
                        'GSR Value',
                        style: TextStyle(
                            fontSize: fontSize, color: Colors.lightBlueAccent),
                      )),
                      DataColumn(
                          label: Text(
                        'Therapy Time',
                        style: TextStyle(
                            fontSize: fontSize, color: Colors.lightBlueAccent),
                      )),
                      DataColumn(
                          label: Text(
                        'Voltage',
                        style: TextStyle(
                            fontSize: fontSize, color: Colors.lightBlueAccent),
                      )),
                    ],
                    rows: List.generate(data.length, (index) {
                      return DataRow(cells: [
                        DataCell(Text(
                          data[index]['no'].toString(),
                          style: TextStyle(
                              fontSize: fontSize, color: Colors.amberAccent),
                        )),
                        DataCell(Text(
                          data[index]['gsr'].toString(),
                          style: TextStyle(
                              fontSize: fontSize, color: Colors.amberAccent),
                        )),
                        DataCell(Text(
                          data[index]['time'].toString(),
                          style: TextStyle(
                              fontSize: fontSize, color: Colors.amberAccent),
                        )),
                        DataCell(Text(
                          data[index]['voltage'].toString(),
                          style: TextStyle(
                              fontSize: fontSize, color: Colors.amberAccent),
                        )),
                      ]);
                    }),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
