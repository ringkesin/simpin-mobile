import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkba_mobile/model/anggota_profile.dart';
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
        '/api/login', // Pastikan endpoint benar
        data: {"username": username, "password": password},
        // Optional: Tambahkan header jika diperlukan (misal, Content-Type)
        // options: Options(headers: {'Content-Type': 'application/json'}),
      );

      // statusCode == 200 sudah ditangani oleh Dio jika validateStatus true (default)
      // Jika sampai sini, berarti sukses (2xx)
      final data =
          response.data as Map<String, dynamic>; // Pastikan di-cast ke Map

      // ----- Sebaiknya Hapus Penyimpanan SharedPreferences di Sini -----
      // Penyimpanan lebih baik dilakukan di _handleLogin setelah parsing berhasil
      // final token = data['data']['token'];
      // final name = data['data']['user']['name'];
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.setString('token', token);
      // await prefs.setString('name', name);
      // -------------------------------------------------------------

      return data;
    } on DioException catch (e) {
      // Lempar kembali DioException agar bisa ditangkap di UI
      // Anda bisa menambahkan logging di sini jika perlu
      print('ApiService Error: ${e.message}');
      print(
        'ApiService Response Data: ${e.response?.data}',
      ); // Lihat body response error jika ada
      rethrow; // <-- Lempar kembali errornya
    } catch (e) {
      // Tangkap error lain yang mungkin terjadi (selain DioException)
      print('ApiService Generic Error: $e');
      // Kembalikan Map error generik atau lempar custom exception
      // return {"error": "Terjadi kesalahan tidak terduga: $e"};
      throw Exception(
        "Terjadi kesalahan tidak terduga: $e",
      ); // Lempar error generik
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

  Future<AnggotaProfileResponse> getAnggotaProfile() async {
    // Return type tetap AnggotaProfile
    try {
      // Mulai blok try
      final prefs = await SharedPreferences.getInstance();
      final int? anggotaId = prefs.getInt("p_anggota_id");
      final String? token = prefs.getString("token");

      // Validasi token dan ID di awal (ini praktik yang baik)
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }
      if (anggotaId == null || anggotaId == 0) {
        throw Exception('ID Anggota tidak ditemukan di SharedPreferences.');
      }

      final String path = '/api/anggota/$anggotaId';
      print("Fetching profile from path: $path (using Dio)");

      // Lakukan GET request menggunakan _dio
      // Dio secara default akan throw DioException untuk status code non-2xx
      final response = await _dio.get(
        path,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Jika kode sampai sini, berarti response.statusCode adalah 2xx (sukses)
      print("Profile Response Status (Dio): ${response.statusCode}");

      // Langsung parse data karena diasumsikan sukses
      // Tambahkan pengecekan tipe data jika perlu, meskipun Dio biasanya handle
      if (response.data != null && response.data is Map<String, dynamic>) {
        final profileResponse = AnggotaProfileResponse.fromJson(response.data);

        if (profileResponse.success && profileResponse.data?.anggota != null) {
          return profileResponse; // Kembalikan data anggota
        } else {
          // Jika success false atau data anggota null dari response API yg sukses (status 200)
          throw Exception(
            profileResponse.message ??
                "Gagal mengambil data profil anggota dari response.",
          );
        }
      } else {
        // Kasus aneh: status 200 tapi data null atau bukan map
        throw Exception("Format respons tidak valid dari server.");
      }
    } catch (e) {
      // Tangkap semua jenis error (DioException, Exception, parsing error, dll)
      print('Error getAnggotaProfile: $e'); // Cetak error ke konsol
      // Jika error adalah DioException dan memiliki response, cetak detailnya (opsional)
      if (e is DioException && e.response != null) {
        print('DioError Response: ${e.response?.data}');
      }
      rethrow; // Lempar ulang error asli agar bisa ditangani oleh pemanggil (UI)
    }
  }
}
