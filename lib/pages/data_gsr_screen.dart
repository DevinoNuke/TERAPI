import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class DataGSRScreen extends StatefulWidget {
  @override
  _DataGSRScreenState createState() => _DataGSRScreenState();
}

class _DataGSRScreenState extends State<DataGSRScreen> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final dio = Dio();
    dio.options.baseUrl = 'http://8.215.9.8:3000';
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 3);
    
    try {
      final response = await dio.get(
        '/api/sensor-data',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': '*/*',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data;
        setState(() {
          _data = jsonData.map((item) => {
            'username': item['username'] ?? '',
            'first_data': item['first_data'] ?? '',
            'last_data': item['last_data'] ?? '',
            'tegangan': item['tegangan'] ?? '',
            'waktu': item['waktu'] ?? '',
            'date': item['createdAt'] != null 
                ? DateTime.parse(item['createdAt']).toString()
                : '',
          }).toList();
          _isLoading = false;
        });
      } else {
        debugPrint('Error status: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      debugPrint('Dio error: ${e.message}');
      debugPrint('Dio error type: ${e.type}');
      debugPrint('Dio error response: ${e.response}');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('General error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Terapi',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _data.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 8,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[800]!, Colors.blue[900]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: Colors.lightBlueAccent,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _data[index]['username'],
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            _buildDataRow(
                              Icons.show_chart,
                              'Sensor GSR 1',
                              _data[index]['first_data'],
                            ),
                            _buildDataRow(
                              Icons.timeline,
                              'Sensor GSR 2',
                              _data[index]['last_data'],
                            ),
                            _buildDataRow(
                              Icons.bolt,
                              'Tegangan',
                              _data[index]['tegangan'],
                            ),
                            _buildDataRow(
                              Icons.access_time,
                              'Waktu',
                              _data[index]['waktu'],
                            ),
                            _buildDataRow(
                              Icons.calendar_today,
                              'Tanggal',
                              DateTime.parse(_data[index]['date']).toLocal().toString().split('.')[0],
                            ),
                            _buildDataRow(
                              Icons.person,
                              'Jenis Kelamin',
                              _data[index]['jeniskelamin'],
                            )
                          ],
                        ),
                        // trailing: Container(
                        //   decoration: BoxDecoration(
                        //     color: Colors.lightBlueAccent.withOpacity(0.2),
                        //     borderRadius: BorderRadius.circular(8),
                        //   ),
                        //   padding: const EdgeInsets.all(8),
                        //   child: const Icon(
                        //     Icons.arrow_forward_ios,
                        //     color: Colors.lightBlueAccent,
                        //     size: 20,
                        //   ),
                        // ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
