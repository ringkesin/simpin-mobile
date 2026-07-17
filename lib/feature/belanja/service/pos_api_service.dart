import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PosApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['martBaseUrl'] ?? 'https://kkba-mart.laravel.cloud',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  String? lastErrorMessage;

  Future<Options?> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
  }

  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    try {
      if (data is Map<String, dynamic>) {
        if (data['message'] is String) return data['message'] as String;
        if (data['error'] is String) return data['error'] as String;
        if (data['errors'] is Map) {
          final errs = data['errors'] as Map;
          if (errs.isNotEmpty) {
            final firstKey = errs.keys.first;
            final val = errs[firstKey];
            if (val is List && val.isNotEmpty) return val.first.toString();
            return val.toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getPenjualanDetail(
    String transaksiPenjualanId,
  ) async {
    lastErrorMessage = null;

    if ((_dio.options.baseUrl).trim().isEmpty) {
      lastErrorMessage = 'urlPos belum diatur di file env';
      return null;
    }

    try {
      final options = await _getHeaders();
      final response = await _dio.get(
        '/api/penjualan/$transaksiPenjualanId',
        options: options?.copyWith(validateStatus: (status) => true),
      );

      final body = response.data;
      if (response.statusCode == 200) {
        if (body is Map<String, dynamic>) {
          if (body['status'] == true && body['data'] is Map) {
            return (body['data'] as Map).cast<String, dynamic>();
          }
          lastErrorMessage =
              _extractMessage(body) ?? 'Gagal memuat detail transaksi';
          return null;
        }
      }

      lastErrorMessage =
          _extractMessage(body) ?? 'Gagal memuat detail transaksi';
      return null;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return null;
    } catch (e) {
      lastErrorMessage = e.toString();
      return null;
    }
  }
}
