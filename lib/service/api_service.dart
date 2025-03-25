import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final Dio _dio = Dio(
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
}
