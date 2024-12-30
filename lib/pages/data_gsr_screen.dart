import 'package:flutter/material.dart';

class DataGSRScreen extends StatelessWidget {
  final List<Map<String, dynamic>> data = [
    {'date': '2024-03-01', 'value': 1250},
    {'date': '2024-03-02', 'value': 1300},
    {'date': '2024-03-03', 'value': 1275},
    {'date': '2024-03-04', 'value': 1225},
    {'date': '2024-03-05', 'value': 1350},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Riwayat Data GSR',
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
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.blue[900],
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                'Date: ${data[index]['date']}',
                style: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'GSR Value: ${data[index]['value']}',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.lightBlueAccent,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }
}
