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
      String url = '/api/master/unit';
      Response response = await _dio.get(url);

      print("Full API Response: ${response.data}"); // Debugging

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['data'] != null &&
          response.data['data']['unit'] is List) {
        List<dynamic> rawUnits = response.data['data']['unit'];
        return rawUnits.map((e) => e as Map<String, dynamic>).toList();
      } else {
        print("Unexpected response structure: ${response.data}");
      }
    } catch (e) {
      print("Error fetching units: $e");
    }
    return [];
  }
}
