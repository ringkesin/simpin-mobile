import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static Dio _dio = Dio(
    BaseOptions(
      baseUrl:
          dotenv.env['baseUrl'] ??
          'https://web-simpin-dev-akbar-lgpepu.laravel.cloud',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      Response response = await _dio.post(
        '/api/login',
        data: {"username": username, "password": password},
      );

      if (response.statusCode == 200) {
        return response.data; // Mengembalikan data response API
      } else {
        return {"error": "Login gagal, periksa kembali kredensial Anda"};
      }
    } catch (e) {
      return {"error": "Terjadi kesalahan saat login: $e"};
    }
  }

  static Future<List<Map<String, dynamic>>> getUnit() async {
    try {
      String url = '/api/unit'; // Pastikan endpoint ini benar
      Response response = await _dio.get(url);

      // print("Requesting URL: ${_dio.options.baseUrl}$url");
      // print("Response Status Code: ${response.statusCode}");
      print("Response Data: ${response.data}");

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    } catch (e) {
      print("Error fetching units: $e");
    }
    return [];
  }
}
