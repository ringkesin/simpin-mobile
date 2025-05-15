import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkba_mobile/model/anggota_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/jenis_pinjaman.dart';
import '../model/keperluan_pinjaman.dart';
import '../model/tabungan.dart';
import '../model/shu.dart';
import '../model/tenor_response.dart';
import '../model/simulasi_pinjaman_response.dart';
import '../model/tabungan_tahunan_response.dart';
import '../model/berita.dart';
import '../model/jenis_tabungan.dart';
import '../model/pengajuan_pencairan.dart';
import '../model/list_pengajuan.dart';
import '../model/base_response.dart';
import '../model/mutasi_tabungan_response.dart';

class ApiService {
  static final Dio _dio = Dio(
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

  Future<TabunganBulananResponse> getTabungan({
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

      // ---- Konversi ke Integer ----
      final int? tahunInt = int.tryParse(tahun);
      final int? bulanInt = int.tryParse(
        bulan,
      ); // int.tryParse("01") akan menghasilkan 1

      if (tahunInt == null || bulanInt == null) {
        // Atau jika bulanInt di luar 1-12
        throw Exception("Format tahun atau bulan tidak valid untuk payload.");
      }
      // -----------------------------

      Map<String, dynamic> payload = {
        "tahun": tahunInt,
        "bulan": bulanInt,
      }; // <-- Kirim integer
      if (pAnggotaId != null) {
        payload["p_anggota_id"] = pAnggotaId;
      }

      Response response = await _dio.post(
        '/api/tabungan/saldo/bulanan',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('ini ${response.data}');

      if (response.statusCode == 200) {
        return TabunganBulananResponse.fromJson(response.data);
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

  // --- METHOD UNTUK GET TENOR ---
  Future<List<TenorItem>> getAvailableTenors({
    required int jenisPinjamanId,
  }) async {
    try {
      final String? token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      final int currentYear = DateTime.now().year;
      final Map<String, dynamic> payload = {
        "tahun": currentYear,
        "jenis_pinjaman_id": jenisPinjamanId,
      };

      final String path = '/api/simulasi/tenor';
      print(
        "[ApiService.getAvailableTenors] Fetching tenors from path: $path with payload: $payload",
      );

      final response = await _dio.post(
        // Menggunakan _dio instance dari class
        path,
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(
        "[ApiService.getAvailableTenors] Response Status (Dio POST): ${response.statusCode}",
      );
      print("[ApiService.getAvailableTenors] Response Data: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        // Menggunakan model TenorResponse yang Anda berikan
        final tenorResponse = TenorResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        if (tenorResponse.success && tenorResponse.data != null) {
          // Sorting berdasarkan nilai tenor
          tenorResponse.data!.sort(
            (a, b) => (a.tenor ?? 0).compareTo(b.tenor ?? 0),
          );
          return tenorResponse.data!;
        } else {
          throw Exception(
            tenorResponse.message ?? "Gagal mengambil daftar tenor.",
          );
        }
      } else {
        String serverError = 'Format respons tenor tidak valid.';
        if (response.data is Map<String, dynamic> &&
            (response.data as Map<String, dynamic>)['message'] != null) {
          serverError = (response.data as Map<String, dynamic>)['message'];
        } else if (response.data is Map<String, dynamic> &&
            (response.data as Map<String, dynamic>)['error'] != null) {
          serverError = (response.data as Map<String, dynamic>)['error'];
        }
        throw Exception(serverError);
      }
    } catch (e) {
      print('[ApiService.getAvailableTenors] Error: $e');
      if (e is DioException) {
        print(
          '[ApiService.getAvailableTenors] DioError Response: ${e.response?.data}',
        );
        String serverError = 'Gagal mengambil data tenor.';
        if (e.response?.data is Map<String, dynamic>) {
          final responseData = e.response!.data as Map<String, dynamic>;
          if (responseData['message'] != null) {
            serverError = responseData['message'];
          } else if (responseData['error'] != null) {
            serverError = responseData['error'];
          }
        } else if (e.message != null && e.message!.isNotEmpty) {
          serverError = e.message!;
        }
        throw Exception(serverError);
      }
      rethrow;
    }
  }

  // --- METHOD POST SIMULASI PINJAMAN (dari respons sebelumnya, sudah menggunakan SimulasiResult yang diperbarui) ---
  Future<SimulasiResult> postSimulasiPinjaman({
    required int jumlahPinjaman,
    required int tenor,
    required int jenisPinjamanId,
  }) async {
    try {
      final String? token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      final int currentYear = DateTime.now().year;
      final Map<String, dynamic> payload = {
        "tahun": currentYear,
        "jumlah_pinjaman": jumlahPinjaman,
        "tenor": tenor,
        "jenis_pinjaman_id": jenisPinjamanId,
      };

      print(
        "[ApiService.postSimulasiPinjaman] Posting simulation with payload: $payload",
      );
      final String path = '/api/simulasi/pinjaman';

      final response = await _dio.post(
        // Menggunakan _dio instance dari class
        path,
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(
        "[ApiService.postSimulasiPinjaman] Simulation Response Status (Dio): ${response.statusCode}",
      );
      print(
        "[ApiService.postSimulasiPinjaman] Simulation Response Data: ${response.data}",
      );

      if (response.statusCode == 200 && response.data != null) {
        final simulasiResponse = SimulasiPinjamanResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        if (simulasiResponse.success && simulasiResponse.data != null) {
          return simulasiResponse.data!;
        } else {
          throw Exception(
            simulasiResponse.message ?? "Gagal menghitung simulasi.",
          );
        }
      } else {
        String serverError = 'Gagal menghitung simulasi.';
        if (response.data is Map<String, dynamic> &&
            (response.data as Map<String, dynamic>)['message'] != null) {
          serverError = (response.data as Map<String, dynamic>)['message'];
        }
        throw Exception(serverError);
      }
    } catch (e) {
      print('[ApiService.postSimulasiPinjaman] Error: $e');
      if (e is DioException && e.response != null) {
        print(
          '[ApiService.postSimulasiPinjaman] DioError Response (Simulasi): ${e.response?.data}',
        );
        String serverError = 'Gagal menghitung simulasi.';
        if (e.response?.data is Map<String, dynamic>) {
          final responseData = e.response!.data as Map<String, dynamic>;
          if (responseData['message'] != null) {
            serverError = responseData['message'];
          } else if (responseData['error'] != null) {
            serverError = responseData['error'];
          }
        } else if (e.message != null && e.message!.isNotEmpty) {
          serverError = e.message!;
        }
        throw Exception(serverError);
      }
      rethrow;
    }
  }

  Future<TabunganTahunanResponse> getTabunganTahunan({
    required int tahun, // Terima tahun sebagai int
    int? pAnggotaId, // pAnggotaId opsional di parameter
  }) async {
    // --- Bagian ini sudah benar ---
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      // Tentukan p_anggota_id yang akan digunakan: dari parameter atau prefs
      int? targetPAnggotaId = pAnggotaId ?? prefs.getInt('p_anggota_id');

      if (targetPAnggotaId == null || targetPAnggotaId == 0) {
        throw Exception(
          'ID Anggota (p_anggota_id) tidak valid atau tidak ditemukan.',
        );
      }
      // --- Akhir bagian yang sudah benar ---

      // --- PERUBAHAN DI SINI ---
      // Tidak perlu lagi parsing 'tahun', karena sudah bertipe int
      // Hapus blok kode ini:
      // final int? tahunInt = int.tryParse(tahun);
      // if (tahunInt == null) {
      //   throw Exception("Format tahun tidak valid untuk payload.");
      // }

      // Siapkan payload dengan 'tahun' dari parameter
      final Map<String, dynamic> payload = {
        "tahun": tahun, // Gunakan parameter 'tahun' langsung
        "p_anggota_id": targetPAnggotaId,
      };
      // --- Akhir Perubahan ---

      final String path = '/api/tabungan/saldo/tahunan';
      print(
        "Fetching tabungan tahunan from path: $path with payload: $payload",
      );

      // Lakukan POST request (bagian ini sudah benar)
      final response = await _dio.post(
        path,
        data: payload, // Kirim payload yang sudah benar
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json', // Pastikan content type
          },
        ),
      );

      print("Tabungan Tahunan Response Status (Dio): ${response.statusCode}");

      // Parsing response (bagian ini sudah benar)
      if (response.data != null && response.data is Map<String, dynamic>) {
        final tabunganResponse = TabunganTahunanResponse.fromJson(
          response.data,
        );
        return tabunganResponse;
      } else {
        throw Exception(
          "Format respons tabungan tahunan tidak valid dari server.",
        );
      }
    } catch (e) {
      // Error handling (bagian ini sudah cukup baik)
      print('Error getTabunganTahunan: $e');
      if (e is DioException) {
        print('DioError Response (Tabungan Tahunan): ${e.response?.data}');
        String serverErrorMsg = 'Gagal mengambil data tabungan tahunan.';
        if (e.response?.data is Map) {
          serverErrorMsg =
              e.response!.data['message'] ??
              e.response!.data['error'] ??
              serverErrorMsg;
        } else if (e.message != null) {
          serverErrorMsg = e.message!;
        }
        throw Exception(serverErrorMsg);
      }
      rethrow; // Lempar ulang error asli jika bukan DioException
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // GANTI 'auth_token' dengan key yang Anda gunakan
      return prefs.getString('token');
    } catch (e) {
      print("Error getting auth token from SharedPreferences: $e");
      return null;
    }
  }

  Future<BeritaResponse> getListBerita() async {
    const String endpoint = '/api/konten';
    Options? requestOptions; // Deklarasikan options sebagai nullable

    try {
      // 1. Ambil token SEBELUM request
      String? token = await _getAuthToken();

      // (Opsional) Throw error jika token wajib tapi tidak ada
      // if (token == null || token.isEmpty) {
      //   throw Exception("Token otentikasi diperlukan untuk mengakses berita.");
      // }

      // 2. Siapkan header jika token ada
      if (token != null && token.isNotEmpty) {
        print("ApiService (getListBerita): Using Auth Token.");
        requestOptions = Options(
          headers: {
            'Authorization': 'Bearer $token',
            // Tambahkan header lain jika perlu
            // 'Accept': 'application/json',
          },
        );
      } else {
        print(
          "ApiService (getListBerita): No Auth Token found. Request might fail if token is required.",
        );
        // Biarkan requestOptions null jika tidak ada token
      }

      print("ApiService: Fetching list berita from $endpoint");
      // 3. Kirim request dengan options (yang mungkin berisi header)
      final response = await _dio.get(endpoint, options: requestOptions);

      if (response.statusCode == 200) {
        return BeritaResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error:
              'Failed to load berita list: Status code ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print("ApiService Error (getListBerita): ${e.message}");
      print("ApiService Error Response: ${e.response?.data}");
      String errorMessage = "Terjadi kesalahan jaringan atau server.";
      // Penanganan error 401/403 tetap relevan
      if (e.response?.statusCode == 401) {
        errorMessage =
            "Akses ditolak. Sesi Anda mungkin telah berakhir, silakan login kembali.";
      } else if (e.response?.statusCode == 403) {
        errorMessage =
            "Anda tidak memiliki izin untuk mengakses sumber daya ini.";
      } else if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type ==
              DioExceptionType.connectionTimeout || /* ... timeout checks ... */
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Koneksi timeout. Periksa jaringan internet Anda.";
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = "Koneksi internet bermasalah.";
      }
      throw Exception(errorMessage);
    } catch (e) {
      print("ApiService Error (getListBerita - Unknown): $e");
      throw Exception("Terjadi kesalahan tidak diketahui: $e");
    }
  }

  /// Mengambil detail berita/konten berdasarkan ID (MEMERLUKAN TOKEN)
  Future<SingleBeritaResponse> getBeritaById(int id) async {
    final String endpoint = '/api/konten/$id';
    Options? requestOptions; // Deklarasikan options sebagai nullable

    try {
      // 1. Ambil token SEBELUM request
      String? token = await _getAuthToken();

      // (Opsional) Throw error jika token wajib tapi tidak ada
      // if (token == null || token.isEmpty) {
      //   throw Exception("Token otentikasi diperlukan untuk mengakses detail berita.");
      // }

      // 2. Siapkan header jika token ada
      if (token != null && token.isNotEmpty) {
        print("ApiService (getBeritaById): Using Auth Token.");
        requestOptions = Options(
          headers: {
            'Authorization': 'Bearer $token',
            // 'Accept': 'application/json',
          },
        );
      } else {
        print(
          "ApiService (getBeritaById): No Auth Token found. Request might fail if token is required.",
        );
      }

      print("ApiService: Fetching berita by ID from $endpoint");
      // 3. Kirim request dengan options
      final response = await _dio.get(endpoint, options: requestOptions);

      if (response.statusCode == 200) {
        return SingleBeritaResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error:
              'Failed to load berita detail: Status code ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print("ApiService Error (getBeritaById): ${e.message}");
      print("ApiService Error Response: ${e.response?.data}");
      String errorMessage =
          "Terjadi kesalahan jaringan atau server saat mengambil detail.";
      // Penanganan error 401/403/404 tetap relevan
      if (e.response?.statusCode == 401) {
        errorMessage =
            "Akses ditolak. Sesi Anda mungkin telah berakhir, silakan login kembali.";
      } else if (e.response?.statusCode == 403) {
        errorMessage = "Anda tidak memiliki izin untuk mengakses detail ini.";
      } else if (e.response?.statusCode == 404) {
        errorMessage = "Data berita dengan ID $id tidak ditemukan.";
      } else if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type ==
              DioExceptionType.connectionTimeout || /* ... timeout checks ... */
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Koneksi timeout. Periksa jaringan internet Anda.";
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = "Koneksi internet bermasalah.";
      }
      throw Exception(errorMessage);
    } catch (e) {
      print("ApiService Error (getBeritaById - Unknown): $e");
      throw Exception(
        "Terjadi kesalahan tidak diketahui saat mengambil detail: $e",
      );
    }
  }

  Future<JenisTabunganResponse> getJenisTabungan() async {
    const String endpoint = '/api/master/jenis-tabungan';
    Options? requestOptions;
    String? token; // Untuk logging jika perlu

    try {
      // 1. Ambil token
      token = await _getAuthToken();

      // (Sangat disarankan) Throw error jika token wajib tapi tidak ada
      if (token == null || token.isEmpty) {
        print(
          "[ApiService.getJenisTabungan] ERROR: Auth Token is required but not found.",
        );
        throw Exception("Token otentikasi diperlukan untuk data ini.");
      }

      // 2. Siapkan header
      print("[ApiService.getJenisTabungan] Using Auth Token.");
      requestOptions = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // Header umum yang baik ditambahkan
        },
      );

      print("ApiService: Fetching jenis tabungan from $endpoint");
      // 3. Kirim request dengan options
      final response = await _dio.get(endpoint, options: requestOptions);

      print(
        "[ApiService.getJenisTabungan] Response status: ${response.statusCode}",
      );
      // 4. Handle response
      if (response.statusCode == 200) {
        return JenisTabunganResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        // Jarang tercapai karena Dio throw error, tapi sebagai fallback
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error:
              'Gagal memuat jenis tabungan: Status code ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      String errorMessage = "Terjadi kesalahan jaringan atau server.";
      if (e.response?.statusCode == 401) {
        errorMessage =
            "Akses jenis tabungan ditolak (401). Token: ${token ?? 'Tidak ada'}. Sesi Anda mungkin telah berakhir.";
      } else if (e.response?.statusCode == 403) {
        errorMessage =
            "Anda tidak memiliki izin untuk mengakses jenis tabungan.";
      } else if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type ==
              DioExceptionType.connectionTimeout || /* ... timeout checks ... */
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Koneksi timeout saat mengambil jenis tabungan.";
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = "Koneksi internet bermasalah.";
      }
      throw Exception(errorMessage); // Re-throw pesan error
    } catch (e) {
      print("[ApiService.getJenisTabungan] Non-Dio Exception caught: $e");
      throw Exception(
        "Terjadi kesalahan tidak diketahui saat mengambil jenis tabungan: $e",
      );
    }
  }

  Future<PengajuanPencairanResponse> submitPengajuanPencairan({
    required int pAnggotaId,
    required int pJenisTabunganId,
    required num jumlahDiambil, // Gunakan num untuk fleksibilitas int/double
    required String rekeningBank,
    required String rekeningNo,
    String? keterangan, // Keterangan opsional (nullable)
  }) async {
    const String endpoint = '/api/tabungan/pencairan/pengajuan';
    Options? requestOptions;
    String? token; // Untuk logging jika perlu

    try {
      // 1. Ambil token
      token = await _getAuthToken();

      // (Sangat disarankan) Throw error jika token wajib tapi tidak ada
      if (token == null || token.isEmpty) {
        print(
          "[ApiService.submitPengajuanPencairan] ERROR: Auth Token is required but not found.",
        );
        throw Exception(
          "Token otentikasi diperlukan untuk mengajukan pencairan.",
        );
      }

      // 2. Siapkan header
      print("[ApiService.submitPengajuanPencairan] Using Auth Token.");
      requestOptions = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type':
              'application/json', // Penting untuk POST dengan body JSON
        },
      );

      // 3. Siapkan payload
      final Map<String, dynamic> payload = {
        'p_anggota_id': pAnggotaId,
        'p_jenis_tabungan_id': pJenisTabunganId,
        'jumlah_diambil': jumlahDiambil,
        'rekening_bank': rekeningBank,
        'rekening_no': rekeningNo,
      };
      // Tambahkan keterangan hanya jika tidak null atau tidak kosong
      if (keterangan != null && keterangan.isNotEmpty) {
        payload['keterangan'] = keterangan;
      }

      print("ApiService: Submitting Pengajuan Pencairan to $endpoint");
      print("ApiService: Payload: $payload"); // Log payload

      // 4. Kirim request POST dengan payload dan options
      final response = await _dio.post(
        endpoint,
        data: payload, // Kirim payload sebagai data
        options: requestOptions,
      );

      print(
        "[ApiService.submitPengajuanPencairan] Response status: ${response.statusCode}",
      );
      print(
        "[ApiService.submitPengajuanPencairan] Response data: ${response.data}",
      ); // Log response data

      // 5. Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 201 Created juga sering digunakan untuk POST
        // Cek apakah response.data adalah Map sebelum parsing
        if (response.data is Map<String, dynamic>) {
          return PengajuanPencairanResponse.fromJson(
            response.data as Map<String, dynamic>,
          );
        } else {
          // Handle jika response.data bukan Map (misalnya String atau null)
          print(
            "[ApiService.submitPengajuanPencairan] ERROR: Unexpected response data format.",
          );
          throw Exception("Format respons tidak valid dari server.");
        }
      } else {
        // Jarang tercapai karena Dio throw error, tapi sebagai fallback
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error:
              'Gagal submit pengajuan pencairan: Status code ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print("[ApiService.submitPengajuanPencairan] DioException caught!");
      print("  -> Request URL: ${e.requestOptions.uri}");
      print("  -> Request Headers: ${e.requestOptions.headers}");
      print(
        "  -> Request Payload: ${e.requestOptions.data}",
      ); // Log payload saat error
      print("  -> Response Status: ${e.response?.statusCode}");
      print("  -> Response Data: ${e.response?.data}");
      print("  -> DioException Type: ${e.type}");
      print("  -> DioException Message: ${e.message}");

      String errorMessage = "Gagal mengirim pengajuan pencairan.";
      if (e.response?.statusCode == 401) {
        errorMessage =
            "Akses ditolak (401). Token: ${token ?? 'Tidak ada'}. Sesi Anda mungkin telah berakhir.";
      } else if (e.response?.statusCode == 403) {
        errorMessage = "Anda tidak memiliki izin untuk melakukan aksi ini.";
      } else if (e.response?.statusCode == 422) {
        // Unprocessable Entity (Validation Error)
        errorMessage =
            "Data yang dikirim tidak valid. Periksa kembali isian Anda.";
        // Anda bisa mencoba mem-parsing pesan error validasi dari backend jika ada
        if (e.response?.data is Map<String, dynamic>) {
          var errors = e.response?.data['errors'];
          if (errors is Map<String, dynamic> && errors.isNotEmpty) {
            // Ambil pesan error pertama
            errorMessage += "\n${errors.values.first[0]}";
          } else if (e.response?.data['message'] != null) {
            errorMessage =
                e.response?.data['message']; // Ambil pesan utama jika ada
          }
        }
      } else if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type ==
              DioExceptionType.connectionTimeout || /* ... timeout checks ... */
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Koneksi timeout saat mengirim pengajuan.";
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = "Koneksi internet bermasalah.";
      }
      throw Exception(errorMessage); // Re-throw pesan error
    } catch (e) {
      print(
        "[ApiService.submitPengajuanPencairan] Non-Dio Exception caught: $e",
      );
      throw Exception(
        "Terjadi kesalahan tidak diketahui saat mengirim pengajuan: $e",
      );
    }
  }

  Future<ListPengajuanResponse> getListPengajuanPencairan({
    int page = 1,
    int perPage = 10, // Default per page
  }) async {
    const String endpoint = '/api/tabungan/pencairan/pengajuan/list';
    Options? requestOptions;
    String? token;

    try {
      // 1. Ambil token
      token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        print("[ApiService.getListPengajuan] ERROR: Auth Token required.");
        throw Exception("Token otentikasi diperlukan.");
      }

      // 2. Siapkan header
      print("[ApiService.getListPengajuan] Using Auth Token.");
      requestOptions = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // 3. Siapkan query parameters untuk pagination
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'per_page': perPage,
      };

      print("ApiService: Fetching List Pengajuan from $endpoint");
      print("ApiService: Query Params: $queryParameters");

      // 4. Kirim request GET
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: requestOptions,
      );

      print(
        "[ApiService.getListPengajuan] Response status: ${response.statusCode}",
      );
      // print("[ApiService.getListPengajuan] Response data: ${response.data}"); // Hati-hati jika data besar

      // 5. Handle response
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          // Parse JSON ke model
          return ListPengajuanResponse.fromJson(response.data);
        } else {
          print(
            "[ApiService.getListPengajuan] ERROR: Unexpected response format.",
          );
          throw Exception("Format respons tidak valid dari server.");
        }
      } else {
        // Handle status code lain jika diperlukan (meskipun Dio biasanya throw error)
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error:
              'Gagal mengambil daftar pengajuan: Status code ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print("[ApiService.getListPengajuan] DioException caught!");
      print("  -> Request URL: ${e.requestOptions.uri}");
      // ... (logging error DioException lainnya seperti di submitPengajuanPencairan) ...

      String errorMessage = "Gagal mengambil daftar pengajuan.";
      if (e.response?.statusCode == 401) {
        errorMessage = "Akses ditolak (401). Sesi Anda mungkin telah berakhir.";
      } else if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Koneksi timeout.";
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = "Koneksi internet bermasalah.";
      }
      throw Exception(
        errorMessage,
      ); // Re-throw pesan error yang lebih user-friendly
    } catch (e) {
      print("[ApiService.getListPengajuan] Non-Dio Exception caught: $e");
      throw Exception("Terjadi kesalahan tidak diketahui: $e");
    }
  }

  Future<BaseResponse> cancelPengajuanPencairan(String pengambilanId) async {
    // Endpoint dinamis berdasarkan ID
    final String endpoint = '/api/tabungan/pencairan/pembatalan/$pengambilanId';
    Options? requestOptions;
    String? token;

    try {
      // 1. Ambil token
      token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        print("[ApiService.cancelPengajuan] ERROR: Auth Token required.");
        throw Exception("Token otentikasi diperlukan.");
      }

      // 2. Siapkan header
      print(
        "[ApiService.cancelPengajuan] Using Auth Token for $pengambilanId.",
      );
      requestOptions = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        // Penting: Tentukan metode DELETE
        method: 'DELETE',
      );

      print(
        "ApiService: Cancelling Pengajuan $pengambilanId via DELETE $endpoint",
      );

      // 4. Kirim request DELETE
      // Dio.delete() adalah shortcut untuk request(method: 'DELETE')
      final response = await _dio.delete(endpoint, options: requestOptions);

      print(
        "[ApiService.cancelPengajuan] Response status: ${response.statusCode}",
      );
      print("[ApiService.cancelPengajuan] Response data: ${response.data}");

      // 5. Handle response
      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content juga umum untuk DELETE
        // Jika backend mengembalikan body JSON (seperti success: true), parse.
        // Jika tidak (status 204), anggap sukses.
        if (response.data is Map<String, dynamic>) {
          return BaseResponse.fromJson(response.data);
        } else if (response.data == null || response.data == '') {
          // Anggap sukses jika tidak ada body tapi status OK/No Content
          return BaseResponse(
            success: true,
            message: "Pengajuan berhasil dibatalkan.",
          );
        } else {
          print(
            "[ApiService.cancelPengajuan] WARNING: Unexpected success response format.",
          );
          // Tetap anggap sukses berdasarkan status code
          return BaseResponse(
            success: true,
            message: "Pembatalan berhasil (status: ${response.statusCode}).",
          );
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error:
              'Gagal membatalkan pengajuan: Status code ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print(
        "[ApiService.cancelPengajuan] DioException caught for ID $pengambilanId!",
      );
      // ... (logging error DioException serupa dengan metode lain) ...

      String errorMessage = "Gagal membatalkan pengajuan.";
      if (e.response?.statusCode == 401) {
        errorMessage = "Akses ditolak (401). Sesi Anda mungkin telah berakhir.";
      } else if (e.response?.statusCode == 404) {
        errorMessage = "Pengajuan tidak ditemukan.";
      } else if (e.response?.statusCode == 403) {
        errorMessage = "Anda tidak diizinkan membatalkan pengajuan ini.";
      } else if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } // ... (handle error koneksi/timeout lainnya) ...
      throw Exception(errorMessage);
    } catch (e) {
      print("[ApiService.cancelPengajuan] Non-Dio Exception caught: $e");
      throw Exception("Terjadi kesalahan tidak diketahui: $e");
    }
  }

  Future<Map<String, dynamic>> changePassword({
    // Mengembalikan Map<String, dynamic>
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    const String endpoint = '/api/change-password';
    Options? requestOptions;
    String? authTokenForLogging;

    try {
      authTokenForLogging = await _getAuthToken();

      if (authTokenForLogging == null || authTokenForLogging.isEmpty) {
        print(
          "[ApiService.changePassword] ERROR: Auth Token is required but not found.",
        );
        throw Exception(
          "Sesi tidak valid. Silakan login kembali.",
        ); // Throw Exception
      }

      print("[ApiService.changePassword] Using Auth Token.");
      requestOptions = Options(
        headers: {
          'Authorization': 'Bearer $authTokenForLogging',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      final Map<String, dynamic> payload = {
        'old_password': oldPassword,
        'new_password': newPassword,
        'password_confirmation': confirmNewPassword,
      };

      print("[ApiService.changePassword] Submitting to $endpoint");
      print("[ApiService.changePassword] Payload: $payload");

      final response = await ApiService._dio.post(
        endpoint,
        data: payload,
        options: requestOptions,
      );

      print(
        "[ApiService.changePassword] Response status: ${response.statusCode}",
      );
      print("[ApiService.changePassword] Response data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>; // Kembalikan data Map
        } else {
          print(
            "[ApiService.changePassword] ERROR: Unexpected response data format.",
          );
          throw Exception(
            "Format respons server tidak valid setelah mengubah password.",
          );
        }
      } else {
        // Ini biasanya tidak akan tercapai jika validateStatus default Dio digunakan (hanya 2xx)
        // Dio akan throw DioException untuk status non-2xx.
        String message = "Gagal mengubah password.";
        if (response.data is Map<String, dynamic> &&
            (response.data as Map<String, dynamic>)['message'] != null) {
          message = (response.data as Map<String, dynamic>)['message'];
        }
        throw Exception("$message (Status: ${response.statusCode})");
      }
    } on DioException catch (e) {
      print("[ApiService.changePassword] DioException caught!");
      print("  -> Request URL: ${e.requestOptions.uri}");
      print("  -> Request Payload: ${e.requestOptions.data}");
      print("  -> Response Status: ${e.response?.statusCode}");
      print("  -> Response Data: ${e.response?.data}");
      print("  -> DioException Type: ${e.type}");
      print("  -> DioException Message: ${e.message}");

      String errorMessage = "Gagal mengubah password.";
      Map<String, dynamic>? responseData =
          (e.response?.data is Map<String, dynamic>)
              ? e.response!.data as Map<String, dynamic>
              : null;

      if (responseData != null && responseData['message'] is String) {
        errorMessage = responseData['message'];
      }

      if (e.response?.statusCode == 401) {
        errorMessage =
            "Sesi Anda telah berakhir atau token tidak valid. Silakan login kembali.";
      } else if (e.response?.statusCode == 403) {
        errorMessage = "Anda tidak memiliki izin untuk mengubah password.";
      } else if (e.response?.statusCode == 422) {
        // Unprocessable Entity (Validation Error)
        if (responseData != null &&
            responseData['errors'] is Map<String, dynamic>) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            final firstErrorField = errors.keys.first;
            final firstErrorMessage =
                (errors[firstErrorField] as List).isNotEmpty
                    ? (errors[firstErrorField] as List).first
                    : "Data tidak valid.";
            errorMessage = "Validasi gagal: $firstErrorMessage";
          } else {
            // Jika 'errors' kosong tapi ada 'message' utama di 422
            errorMessage =
                responseData['message'] as String? ??
                "Data yang Anda masukkan tidak valid.";
          }
        } else {
          errorMessage =
              responseData?['message'] as String? ??
              "Data yang Anda masukkan tidak valid.";
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Koneksi timeout. Periksa jaringan Anda dan coba lagi.";
      } else if (e.type == DioExceptionType.unknown ||
          e.type == DioExceptionType.connectionError) {
        errorMessage =
            "Koneksi internet bermasalah atau server tidak dapat dijangkau.";
      } else if (errorMessage == "Gagal mengubah password." &&
          e.message != null &&
          e.message!.isNotEmpty) {
        // Fallback ke pesan error Dio jika belum ada pesan yang lebih spesifik
        errorMessage = e.message!;
      }
      throw Exception(errorMessage); // Throw Exception
    } catch (e) {
      print("[ApiService.changePassword] Non-Dio Exception caught: $e");
      throw Exception("Terjadi kesalahan sistem: $e"); // Throw Exception
    }
  }

  Future<MutasiTabunganResponse> getMutasiTabungan({
    required String bulan,
    required String tahun,
    int? pAnggotaId,
    int page = 1, // Parameter untuk pagination, default halaman 1
  }) async {
    const String endpoint = '/api/tabungan/mutasi/list';
    String? authTokenForLogging;

    print(
      "[ApiService.getMutasiTabungan] Called with: bulan='$bulan', tahun='$tahun', pAnggotaId=$pAnggotaId, page=$page",
    );

    if (pAnggotaId == null) {
      print("[ApiService.getMutasiTabungan] ERROR: pAnggotaId is null.");
      return MutasiTabunganResponse(
        success: false,
        message: "ID Anggota tidak valid.",
      );
    }

    try {
      authTokenForLogging = await _getAuthToken();

      if (authTokenForLogging == null || authTokenForLogging.isEmpty) {
        print(
          "[ApiService.getMutasiTabungan] ERROR: Auth Token is required but not found.",
        );
        return MutasiTabunganResponse(
          success: false,
          message: "Sesi tidak valid. Silakan login kembali.",
        );
      }

      print("[ApiService.getMutasiTabungan] Using Auth Token.");

      final int? tahunInt = int.tryParse(tahun);
      final int? bulanInt = int.tryParse(bulan);

      if (tahunInt == null || bulanInt == null) {
        print(
          "[ApiService.getMutasiTabungan] ERROR: Invalid format for tahun ('$tahun') or bulan ('$bulan').",
        );
        throw Exception("Format tahun atau bulan tidak valid untuk payload.");
      }
      print(
        "[ApiService.getMutasiTabungan] Parsed date: tahun=$tahunInt, bulan=$bulanInt",
      );

      Map<String, dynamic> payload = {
        "tahun": tahunInt,
        "bulan": bulanInt,
        "p_anggota_id": pAnggotaId,
        // "page": page, // Kirim parameter page jika backend Anda mendukungnya di payload POST
      };

      final response = await ApiService._dio.get(
        endpoint, // Jika 'page' adalah query param, gunakan requestEndpoint
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authTokenForLogging',
            'Content-Type': 'application/json',
          },
        ),
      );

      // LogInterceptor sudah menampilkan status dan body respons
      print(
        "[ApiService.getMutasiTabungan] Response status: ${response.statusCode}",
      );
      // print("[ApiService.getMutasiTabungan] Response data: ${response.data}"); // Dilog oleh Interceptor

      if (response.statusCode == 200) {
        print(
          "[ApiService.getMutasiTabungan] Success response (200). Parsing data...",
        );
        if (response.data is Map<String, dynamic>) {
          return MutasiTabunganResponse.fromJson(
            response.data as Map<String, dynamic>,
          );
        } else {
          print(
            "[ApiService.getMutasiTabungan] ERROR: Unexpected response data format. Expected Map but got ${response.data.runtimeType}",
          );
          return MutasiTabunganResponse(
            success: false,
            message: "Format respons server tidak valid untuk data mutasi.",
          );
        }
      } else {
        String message = "Gagal memuat data mutasi tabungan.";
        if (response.data is Map<String, dynamic> &&
            (response.data as Map<String, dynamic>)['message'] != null) {
          message = (response.data as Map<String, dynamic>)['message'];
        }
        print(
          "[ApiService.getMutasiTabungan] ERROR: Failed with status ${response.statusCode}. Message: $message",
        );
        return MutasiTabunganResponse(
          success: false,
          message: "$message (Status: ${response.statusCode})",
        );
      }
    } on DioException catch (e) {
      print("[ApiService.getMutasiTabungan] DioException caught!");
      print("  -> DioException Type: ${e.type}");
      print("  -> Request URL: ${e.requestOptions.uri}");
      print("  -> Request Data: ${e.requestOptions.data}");
      if (e.response != null) {
        print("  -> Response Status: ${e.response?.statusCode}");
        // print("  -> Response Data: ${e.response?.data}"); // Dilog oleh Interceptor
      } else {
        print("  -> No response from server.");
      }
      print("  -> DioException Message: ${e.message}");

      String errorMessage = "Gagal memuat rincian mutasi tabungan.";
      // ... (logika penanganan error DioException yang lebih detail seperti pada getTabungan)
      Map<String, dynamic>? errors;

      if (e.response?.data is Map<String, dynamic>) {
        final responseData = e.response!.data as Map<String, dynamic>;
        errorMessage = responseData['message'] as String? ?? errorMessage;
        if (responseData['errors'] is Map<String, dynamic>) {
          errors = responseData['errors'] as Map<String, dynamic>;
        }
      }
      if (e.response?.statusCode == 401) {
        errorMessage =
            "Sesi Anda telah berakhir atau token tidak valid. Silakan login kembali.";
      } else if (e.response?.statusCode == 422 &&
          errors != null &&
          errors.isNotEmpty) {
        final firstErrorField = errors.keys.first;
        final firstErrorMessage =
            (errors[firstErrorField] as List).isNotEmpty
                ? (errors[firstErrorField] as List).first
                : "Data tidak valid.";
        errorMessage = "Validasi gagal: $firstErrorMessage";
      } else if (e.type ==
              DioExceptionType
                  .connectionTimeout || /* ... timeout, connectionError ... */
          e.type == DioExceptionType.unknown) {
        errorMessage =
            "Koneksi bermasalah atau server tidak merespons. Periksa jaringan Anda.";
      }
      return MutasiTabunganResponse(success: false, message: errorMessage);
    } catch (e) {
      print("[ApiService.getMutasiTabungan] General Exception caught: $e");
      return MutasiTabunganResponse(
        success: false,
        message: "Terjadi kesalahan sistem: $e",
      );
    }
  }
}
