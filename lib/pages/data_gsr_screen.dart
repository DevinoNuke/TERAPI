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
    dio.options.baseUrl = 'http://47.238.5.204:3000';
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
        title:const Text(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _data.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.blue[900],
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      'Username: ${_data[index]['username']}',
                      style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'First Data: ${_data[index]['first_data']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Last Data: ${_data[index]['last_data']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Date: ${_data[index]['date']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Tegangan: ${_data[index]['tegangan']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Waktu: ${_data[index]['waktu']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    trailing: const Icon(
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
