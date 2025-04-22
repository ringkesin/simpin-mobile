import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/jenis_pinjaman.dart';
import '../model/keperluan_pinjaman.dart';
import '../model/tabungan.dart';
import '../model/shu.dart';

class ApiService {
  static Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['baseUrl'] ?? 'https://kkba-simpin.laravel.cloud',
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
        final data = response.data;

        // Ambil token dan nama dari response
        final token = data['data']['token'];
        final name = data['data']['user']['name'];

        // Simpan ke SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('name', name);

        return data;
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

  Future<List<JenisPinjamanModel>> getMasterJenisPinjaman() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      Response response = await _dio.get(
        '/api/master/jenis-pinjaman',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success']) {
        List<dynamic> list = response.data['data']['jenis_pinjaman'];
        return list.map((e) => JenisPinjamanModel.fromJson(e)).toList();
      } else {
        throw Exception('Gagal memuat data jenis pinjaman.');
      }
    } catch (e) {
      print('Error getMasterJenisPinjaman: $e');
      rethrow;
    }
  }

  Future<List<KeperluanPinjamanModel>> getMasterKeperluanPinjaman() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      Response response = await _dio.get(
        '/api/master/keperluan-pinjaman',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success']) {
        List<dynamic> list = response.data['data']['keperluan_pinjaman'];
        return list.map((e) => KeperluanPinjamanModel.fromJson(e)).toList();
      } else {
        throw Exception('Gagal memuat data keperluan pinjaman.');
      }
    } catch (e) {
      print('Error getMasterKeperluanPinjaman: $e');
      rethrow;
    }
  }

  Future<TabunganData> getTabungan({
    required String bulan,
    required String tahun,
    int? pAnggotaId,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      // Prepare the payload
      Map<String, dynamic> payload = {"bulan": bulan, "tahun": tahun};

      // Add p_anggota_id if provided
      if (pAnggotaId != null) {
        payload["p_anggota_id"] = pAnggotaId;
      }

      Response response = await _dio.post(
        '/api/tabungan',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return TabunganData.fromJson(response.data);
      } else {
        throw Exception(
          response.data['message'] ?? 'Gagal memuat data tabungan.',
        );
      }
    } catch (e) {
      print('Error getTabungan: $e');
      rethrow;
    }
  }

  Future<InfoSHU> getShu({
    // Ubah nama fungsi dan return type
    required String tahun,
    int? pAnggotaId,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      // Prepare the payload
      Map<String, dynamic> payload = {"tahun": tahun};

      // Add p_anggota_id if provided
      if (pAnggotaId != null) {
        payload["p_anggota_id"] = pAnggotaId;
      }

      Response response = await _dio.post(
        '/api/shu', // Ubah endpoint ke /api/shu
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        //  print("Response Data: ${response.data}"); //for debugging
        return InfoSHU.fromJson(response.data); // Gunakan InfoSHU.fromJson
      } else {
        throw Exception(response.data['message'] ?? 'Gagal memuat data SHU.');
      }
    } catch (e) {
      print('Error getShu: $e');
      rethrow;
    }
  }
}
