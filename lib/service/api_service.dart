import 'dart:ffi';
import 'dart:convert';
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
import '../model/pinjaman_list.dart';
import '../model/tagihan_anggota.dart';
import '../model/ticket_response.dart';
import 'package:image_picker/image_picker.dart';

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

  static Future<ProfileResponseComplex> getProfile() async {
    final String endpoint = "/api/profile"; // Endpoint relatif terhadap baseUrl

    try {
      // 1. Ambil instance SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // 2. Ambil token. Ganti "AUTH_TOKEN" dengan key yang Anda gunakan saat menyimpan token.
      final String? token = prefs.getString("token");

      // 3. Handle jika token tidak ditemukan
      if (token == null || token.isEmpty) {
        print('Error: Token tidak ditemukan di SharedPreferences.');
        // Anda bisa melempar exception spesifik atau mengembalikan respons error
        // Di sini kita lempar exception agar bisa ditangkap oleh pemanggil
        throw Exception(
          'Sesi tidak valid atau token tidak ditemukan. Silakan login kembali.',
        );
      }

      // 4. Lanjutkan dengan request Dio menggunakan token yang diambil
      final Response response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'Authorization':
                'Bearer $token', // Menyertakan token dari SharedPreferences
            'Accept': 'application/json',
          },
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        return ProfileResponseComplex.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception(
          'Gagal mengambil profil: Format respons tidak valid atau data kosong.',
        );
      }
    } on DioException catch (e) {
      print('DioException saat getProfile: ${e.message}');
      if (e.response != null) {
        print('DioException - Data: ${e.response?.data}');
        print('DioException - Status Code: ${e.response?.statusCode}');
        String errorMessage =
            'Gagal mengambil profil. Status: ${e.response?.statusCode}';

        if (e.response?.data is Map && e.response?.data['message'] != null) {
          errorMessage =
              'Gagal: ${e.response?.data['message']} (Status: ${e.response?.statusCode})';
        } else if (e.response?.data != null) {
          errorMessage =
              'Gagal mengambil profil: ${e.response?.data.toString()} (Status: ${e.response?.statusCode})';
        }

        if (e.response?.statusCode == 401) {
          errorMessage =
              'Unauthorized: Token tidak valid atau kadaluwarsa. (Status: 401)';
          // Pertimbangkan untuk memanggil fungsi logout otomatis di sini atau
          // memberi tahu pengguna untuk login ulang.
        }
        throw Exception(errorMessage);
      } else {
        print('DioException (tanpa respons): ${e.message}');
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            throw Exception('Gagal terhubung ke server: Waktu koneksi habis.');
          case DioExceptionType.cancel:
            throw Exception('Permintaan ke server dibatalkan.');
          case DioExceptionType.connectionError:
            throw Exception('Gagal terhubung ke server: Masalah koneksi.');
          default:
            throw Exception(
              'Gagal terhubung ke server atau terjadi kesalahan jaringan: ${e.message}',
            );
        }
      }
    } catch (e) {
      // Menangani error umum lainnya (misalnya, dari SharedPreferences jika ada)
      print('Error umum saat getProfile: $e');
      // Jika error berasal dari Exception yang sudah kita lempar (misal, token tidak ada),
      // kita bisa melemparnya kembali atau membuat pesan baru.
      if (e is Exception && e.toString().contains("Sesi tidak valid")) {
        throw e; // Lempar kembali exception asli
      }
      throw Exception(
        'Terjadi kesalahan tidak terduga saat mengambil profil: $e',
      );
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
      print('ini data ${response.data}');
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

  static Future<Map<String, dynamic>> updateProfilePhoto(
    XFile imageFile,
  ) async {
    final String endpoint = "/api/profile/update-photo";
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString(
        "token",
      ); // Pastikan key token benar

      if (token == null || token.isEmpty) {
        throw Exception(
          'Sesi tidak valid. Silakan login kembali untuk mengubah foto.',
        );
      }

      String fileName = imageFile.path.split('/').last;

      // !! PERUBAHAN DI SINI !!
      // Mengubah nama field dari "photo" menjadi "profile_photo" sesuai pesan error backend
      Map<String, dynamic> formDataMap = {
        "profile_photo": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        // Jika API Anda menggunakan metode POST untuk operasi PUT/PATCH (umum di Laravel),
        // Anda mungkin perlu menambahkan field _method seperti ini:
        // "_method": "POST", // atau "PUT", "PATCH" tergantung bagaimana backend menghandlenya
        // Biasanya jika endpointnya POST tapi aksinya update, _method bisa jadi PUT/PATCH
        // Jika endpointnya memang sudah POST untuk update foto, ini tidak perlu.
      };

      FormData formData = FormData.fromMap(formDataMap);

      print("ApiService: Mengirim FormData untuk update foto:");
      formData.fields.forEach((field) {
        print("  Field: ${field.key} = ${field.value}");
      });
      for (var file in formData.files) {
        print(
          "  File: key=${file.key}, filename=${file.value.filename}, contentType=${file.value.contentType}",
        );
      }

      final Response response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
        onSendProgress: (int sent, int total) {
          print(
            'Progres upload: ${(sent / total * 100).toStringAsFixed(0)}% ($sent/$total)',
          );
        },
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        if (response.data['success'] == true ||
            response.statusCode == 200 ||
            response.statusCode == 201) {
          print(
            "ApiService: Foto berhasil diunggah. Respons: ${response.data}",
          );
          return response.data as Map<String, dynamic>;
        } else {
          String serverMessage =
              response.data['message'] ?? 'Gagal mengunggah foto dari server.';
          if (response.data['errors'] != null &&
              response.data['errors'] is Map) {
            Map<String, dynamic> errors = response.data['errors'];
            serverMessage +=
                "\nDetail: " +
                errors.entries
                    .map(
                      (entry) =>
                          '${entry.key}: ${(entry.value as List).join(', ')}',
                    )
                    .join('; ');
          }
          print(
            "ApiService: Gagal mengunggah foto. Pesan server: $serverMessage",
          );
          throw Exception(serverMessage);
        }
      } else {
        print(
          "ApiService: Gagal mengunggah foto. Respons tidak valid dari server.",
        );
        throw Exception(
          'Gagal mengunggah foto: Respons tidak valid dari server.',
        );
      }
    } on DioException catch (e) {
      print('DioException saat updateProfilePhoto: ${e.message}');
      String errorMessage =
          'Gagal mengunggah foto. Status: ${e.response?.statusCode ?? 'N/A'}';
      if (e.response != null) {
        print('DioException - Data Respons Error: ${e.response?.data}');
        if (e.response?.data is Map) {
          final responseData = e.response?.data as Map<String, dynamic>;
          if (responseData['message'] != null &&
              responseData['message'].toString().isNotEmpty) {
            errorMessage =
                'Gagal: ${responseData['message']} (Status: ${e.response?.statusCode})';
          }
          if (responseData['errors'] != null && responseData['errors'] is Map) {
            Map<String, dynamic> errors = responseData['errors'];
            String details = errors.entries
                .map(
                  (entry) =>
                      '${entry.key}: ${(entry.value as List).join(', ')}',
                )
                .join('; ');
            errorMessage += "\nDetail: $details";
          }
        } else if (e.response?.data != null) {
          errorMessage =
              'Gagal mengunggah foto: ${e.response?.data.toString()} (Status: ${e.response?.statusCode})';
        }

        if (e.response?.statusCode == 401) {
          errorMessage =
              'Unauthorized: Token tidak valid atau kadaluwarsa. (Status: 401)';
        } else if (e.response?.statusCode == 400) {
          errorMessage =
              'Permintaan tidak valid atau form tidak lengkap (Status: 400). ${errorMessage.contains("Detail:") ? "" : "Pastikan semua field yang dibutuhkan API telah dikirim."}';
        } else if (e.response?.statusCode == 422) {
          errorMessage =
              'Data tidak valid (Status: 422). ${errorMessage.contains("Detail:") ? "" : "Periksa kembali data yang dikirim."}';
        }
      } else {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Gagal terhubung ke server: Waktu koneksi habis.';
            break;
          case DioExceptionType.cancel:
            errorMessage = 'Permintaan ke server dibatalkan.';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Gagal terhubung ke server: Masalah koneksi.';
            break;
          default:
            errorMessage =
                'Gagal terhubung ke server atau terjadi kesalahan jaringan: ${e.message}';
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('Error umum saat updateProfilePhoto: $e');
      if (e is Exception && e.toString().contains("Sesi tidak valid")) {
        throw e;
      }
      throw Exception(
        'Terjadi kesalahan tidak terduga saat mengunggah foto: $e',
      );
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String nama,
    required String alamatEmail,
    required String nomorHp,
    required String nomorPegawai,
    required String nomorKtp,
    String? tempatLahir, // Opsional
    required String tanggalLahir, // Format YYYY-MM-DD
    String? alamat, // Opsional
    required int pUnitId,
    XFile? attachmentKtpFile, // File KTP opsional
    XFile? attachmentKartuPegawaiFile, // File Kartu Pegawai opsional
    // Tambahkan parameter lain jika diperlukan, misalnya password
    // required String password,
    // required String passwordConfirmation,
  }) async {
    final String endpoint =
        "/api/anggota/register"; // Pastikan endpoint ini benar

    try {
      // Membuat Map untuk field teks
      Map<String, dynamic> textFields = {
        "nama": nama,
        "alamat_email": alamatEmail,
        "nomor_hp": nomorHp,
        "nomor_pegawai": nomorPegawai,
        "nomor_ktp": nomorKtp,
        "tanggal_lahir": tanggalLahir, // Pastikan format YYYY-MM-DD
        "p_unit_id":
            pUnitId.toString(), // API mungkin mengharapkan String untuk ID
        // Tambahkan field opsional jika ada nilainya
        if (tempatLahir != null && tempatLahir.isNotEmpty)
          "tempat_lahir": tempatLahir,
        if (alamat != null && alamat.isNotEmpty) "alamat": alamat,
        // Tambahkan field password jika API Anda memerlukannya saat registrasi
        // "password": password,
        // "password_confirmation": passwordConfirmation,
      };

      // Membuat FormData dan menambahkan field teks
      FormData formData = FormData.fromMap(textFields);

      // Menambahkan file KTP jika ada
      if (attachmentKtpFile != null) {
        String ktpFileName = attachmentKtpFile.path.split('/').last;
        formData.files.add(
          MapEntry(
            "attachment_ktp", // Pastikan nama field ini sesuai dengan API backend
            await MultipartFile.fromFile(
              attachmentKtpFile.path,
              filename: ktpFileName,
            ),
          ),
        );
      }

      // Menambahkan file Kartu Pegawai jika ada
      if (attachmentKartuPegawaiFile != null) {
        String kartuPegawaiFileName =
            attachmentKartuPegawaiFile.path.split('/').last;
        formData.files.add(
          MapEntry(
            "attachment_kartu_pegawai", // Pastikan nama field ini sesuai dengan API backend
            await MultipartFile.fromFile(
              attachmentKartuPegawaiFile.path,
              filename: kartuPegawaiFileName,
            ),
          ),
        );
      }

      print("ApiService: Mengirim FormData untuk registrasi:");
      formData.fields.forEach((field) {
        print("  Field: ${field.key} = ${field.value}");
      });
      for (var file in formData.files) {
        print(
          "  File: key=${file.key}, filename=${file.value.filename}, contentType=${file.value.contentType}",
        );
      }

      final Response response = await _dio.post(
        endpoint,
        data: formData, // Mengirim FormData
        options: Options(
          headers: {
            'Accept': 'application/json',
            // Dio akan otomatis mengatur 'Content-Type' ke 'multipart/form-data'
            // Token biasanya tidak diperlukan untuk endpoint registrasi
          },
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        if (response.data['success'] == true ||
            response.statusCode == 200 ||
            response.statusCode == 201) {
          print("ApiService: Registrasi berhasil. Respons: ${response.data}");
          return response.data as Map<String, dynamic>;
        } else {
          String serverMessage =
              response.data['message'] ?? 'Gagal melakukan registrasi.';
          if (response.data['errors'] != null &&
              response.data['errors'] is Map) {
            Map<String, dynamic> errors = response.data['errors'];
            serverMessage +=
                "\nDetail: " +
                errors.entries
                    .map(
                      (entry) =>
                          '${entry.key}: ${(entry.value as List).join(', ')}',
                    )
                    .join('; ');
          }
          print("ApiService: Gagal registrasi. Pesan server: $serverMessage");
          throw Exception(serverMessage);
        }
      } else {
        print("ApiService: Gagal registrasi. Respons tidak valid dari server.");
        throw Exception(
          'Gagal melakukan registrasi: Respons tidak valid dari server.',
        );
      }
    } on DioException catch (e) {
      print('DioException saat registerUser: ${e.message}');
      String errorMessage =
          'Gagal melakukan registrasi. Status: ${e.response?.statusCode ?? 'N/A'}';
      if (e.response != null) {
        print(
          'DioException - Data Respons Error Registrasi: ${e.response?.data}',
        );
        if (e.response?.data is Map) {
          final responseData = e.response?.data as Map<String, dynamic>;
          if (responseData['message'] != null &&
              responseData['message'].toString().isNotEmpty) {
            errorMessage =
                'Gagal: ${responseData['message']} (Status: ${e.response?.statusCode})';
          }
          if (responseData['errors'] != null && responseData['errors'] is Map) {
            Map<String, dynamic> errors = responseData['errors'];
            String details = errors.entries
                .map(
                  (entry) =>
                      '${entry.key}: ${(entry.value as List).join(', ')}',
                )
                .join('; ');
            errorMessage += "\nDetail: $details";
          }
        } else if (e.response?.data != null) {
          errorMessage =
              'Gagal registrasi: ${e.response?.data.toString()} (Status: ${e.response?.statusCode})';
        }
        if (e.response?.statusCode == 422) {
          errorMessage =
              'Data registrasi tidak valid (Status: 422). ${errorMessage.contains("Detail:") ? "" : "Periksa kembali data yang Anda masukkan."}';
        } else if (e.response?.statusCode == 400) {
          errorMessage =
              'Permintaan registrasi tidak valid (Status: 400). ${errorMessage.contains("Detail:") ? "" : "Pastikan semua field yang dibutuhkan API telah diisi dengan benar."}';
        }
      } else {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Gagal terhubung ke server: Waktu koneksi habis.';
            break;
          case DioExceptionType.cancel:
            errorMessage = 'Permintaan ke server dibatalkan.';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Gagal terhubung ke server: Masalah koneksi.';
            break;
          default:
            errorMessage =
                'Gagal terhubung ke server atau terjadi kesalahan jaringan: ${e.message}';
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('Error umum saat registerUser: $e');
      throw Exception('Terjadi kesalahan tidak terduga saat registrasi: $e');
    }
  }

  // --- METODE BARU UNTUK PENGAJUAN PINJAMAN ---
  static Future<Map<String, dynamic>> submitLoanApplication({
    required int pAnggotaId,
    required int pJenisPinjamanId,
    List<int>? pPinjamanKeperluanIds,
    String? jenisBarang,
    String? merkType,
    required int tenor,
    required double raJumlahPinjaman,
    required double biayaAdmin,
    required String jaminan,
    required String jaminanKeterangan,
    required double jaminanPerkiraanNilai,
    required String noRekening,
    required String bank,
    XFile? docSlipGaji,
  }) async {
    final String endpoint = "/api/pinjaman/pengajuan";

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        throw Exception(
          'Sesi tidak valid. Silakan login kembali untuk mengajukan pinjaman.',
        );
      }

      // Pisahkan field yang nilainya tunggal
      Map<String, dynamic> singleValueFields = {
        "p_anggota_id": pAnggotaId.toString(),
        "p_jenis_pinjaman_id": pJenisPinjamanId.toString(),
        "tenor": tenor.toString(),
        "ra_jumlah_pinjaman": raJumlahPinjaman.toString(),
        "biaya_admin": biayaAdmin.toString(),
        "jaminan": jaminan,
        "jaminan_keterangan": jaminanKeterangan,
        "jaminan_perkiraan_nilai": jaminanPerkiraanNilai.toString(),
        "no_rekening": noRekening,
        "bank": bank,
      };

      // Tambahkan field kondisional yang nilainya tunggal
      if (pJenisPinjamanId == 3) {
        if (jenisBarang == null ||
            jenisBarang.isEmpty ||
            merkType == null ||
            merkType.isEmpty) {
          throw Exception(
            "Untuk jenis pinjaman ini, jenis barang dan merk/tipe wajib diisi.",
          );
        }
        singleValueFields["jenis_barang"] = jenisBarang;
        singleValueFields["merk_type"] = merkType;
      } else if (pJenisPinjamanId == 1 || pJenisPinjamanId == 2) {
        // pPinjamanKeperluanIds akan ditangani secara khusus di bawah
        if (pPinjamanKeperluanIds == null || pPinjamanKeperluanIds.isEmpty) {
          throw Exception(
            "Untuk jenis pinjaman ini, keperluan pinjaman wajib diisi.",
          );
        }
      } else {
        throw Exception("Jenis pinjaman tidak valid: $pJenisPinjamanId");
      }

      FormData formData = FormData.fromMap(singleValueFields);

      // --- PERUBAHAN UTAMA DI SINI ---
      // Tangani p_pinjaman_keperluan_ids secara khusus untuk memastikan format array
      if ((pJenisPinjamanId == 1 || pJenisPinjamanId == 2) &&
          pPinjamanKeperluanIds != null &&
          pPinjamanKeperluanIds.isNotEmpty) {
        // Mengirim setiap ID sebagai field terpisah dengan nama 'p_pinjaman_keperluan_ids[]'
        // Ini adalah cara umum agar backend (misalnya PHP) mengenalinya sebagai array.
        for (int id in pPinjamanKeperluanIds) {
          formData.fields.add(
            MapEntry('p_pinjaman_keperluan_ids[]', id.toString()),
          );
        }
        // Jika backend Anda mengharapkan format p_pinjaman_keperluan_ids[0], p_pinjaman_keperluan_ids[1], dst.
        // Anda bisa menggunakan loop dengan index:
        // for (int i = 0; i < pPinjamanKeperluanIds.length; i++) {
        //   formData.fields.add(MapEntry('p_pinjaman_keperluan_ids[$i]', pPinjamanKeperluanIds[i].toString()));
        // }
      }
      // --- AKHIR PERUBAHAN UTAMA ---

      if (docSlipGaji != null) {
        String fileName = docSlipGaji.path.split('/').last;
        formData.files.add(
          MapEntry(
            "doc_slip_gaji",
            await MultipartFile.fromFile(docSlipGaji.path, filename: fileName),
          ),
        );
      }

      print(
        "ApiService: Mengirim FormData untuk pengajuan pinjaman (setelah modifikasi p_pinjaman_keperluan_ids):",
      );
      formData.fields.forEach((field) {
        print("  Field: ${field.key} = ${field.value}");
      });
      for (var file in formData.files) {
        print(
          "  File: key=${file.key}, filename=${file.value.filename}, contentType=${file.value.contentType}",
        );
      }

      final Response response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
        onSendProgress: (int sent, int total) {
          print(
            'Progres upload pengajuan: ${(sent / total * 100).toStringAsFixed(0)}% ($sent/$total)',
          );
        },
      );

      // ... sisa kode handling response Anda ...
      if (response.data != null && response.data is Map<String, dynamic>) {
        if (response.data['success'] == true ||
            response.statusCode == 200 ||
            response.statusCode == 201) {
          print(
            "ApiService: Pengajuan pinjaman berhasil. Respons: ${response.data}",
          );
          return response.data as Map<String, dynamic>;
        } else {
          // ... (error handling yang sudah ada)
          String serverMessage =
              response.data['message'] ?? 'Gagal mengajukan pinjaman.';
          if (response.data['errors'] != null &&
              response.data['errors'] is Map) {
            Map<String, dynamic> errors = response.data['errors'];
            serverMessage +=
                "\nDetail: " +
                errors.entries
                    .map(
                      (entry) =>
                          '${entry.key}: ${(entry.value as List).join(', ')}',
                    )
                    .join('; ');
          }
          print(
            "ApiService: Gagal mengajukan pinjaman. Pesan server: $serverMessage",
          );
          throw Exception(serverMessage);
        }
      } else {
        print(
          "ApiService: Gagal mengajukan pinjaman. Respons tidak valid dari server.",
        );
        throw Exception(
          'Gagal mengajukan pinjaman: Respons tidak valid dari server.',
        );
      }
    } on DioException catch (e) {
      // ... (error handling DioException Anda yang sudah ada) ...
      print('DioException saat submitLoanApplication: ${e.message}');
      String errorMessage =
          'Gagal mengajukan pinjaman. Status: ${e.response?.statusCode ?? 'N/A'}';
      if (e.response != null) {
        print(
          'DioException - Data Respons Error Pengajuan: ${e.response?.data}',
        );
        if (e.response?.data is Map) {
          final responseData = e.response?.data as Map<String, dynamic>;
          if (responseData['message'] != null &&
              responseData['message'].toString().isNotEmpty) {
            errorMessage =
                'Gagal: ${responseData['message']} (Status: ${e.response?.statusCode})';
          }
          if (responseData['errors'] != null && responseData['errors'] is Map) {
            Map<String, dynamic> errors = responseData['errors'];
            String details = errors.entries
                .map(
                  (entry) =>
                      '${entry.key}: ${(entry.value as List).join(', ')}',
                )
                .join('; ');
            errorMessage += "\nDetail: $details";
          }
        } else if (e.response?.data != null) {
          errorMessage =
              'Gagal mengajukan pinjaman: ${e.response?.data.toString()} (Status: ${e.response?.statusCode})';
        }
        // ... (sisa if statusCode)
        if (e.response?.statusCode == 400 &&
            errorMessage.contains("p_pinjaman_keperluan_ids") &&
            errorMessage.contains("must be an array")) {
          errorMessage =
              "API Error: p_pinjaman_keperluan_ids harus berupa array. (Status: 400)";
        } else if (e.response?.statusCode == 400) {
          errorMessage =
              'Permintaan pengajuan tidak valid (Status: 400). ${errorMessage.contains("Detail:") ? "" : "Pastikan semua field yang dibutuhkan API telah diisi dengan benar."}';
        }
      } else {
        throw Exception(
          'Gagal terhubung ke server atau terjadi kesalahan jaringan: ${e.message}',
        );
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('Error umum saat submitLoanApplication: $e');
      if (e is Exception && e.toString().contains("Sesi tidak valid")) {
        throw e;
      }
      throw Exception(
        'Terjadi kesalahan tidak terduga saat mengajukan pinjaman: $e',
      );
    }
  }

  static Future<PinjamanListResponse> getListPengajuanPinjaman({
    int page = 1,
    int? pStatusPengajuanId, // Opsional
    int? pJenisPinjamanId, // Opsional
    String?
    pPinjamanKeperluanId, // Opsional, dan tetap String karena payload Anda "2"
    int? month, // Opsional
    int? year, // Opsional
  }) async {
    final String endpoint = "/api/pinjaman/list";

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        throw Exception('Sesi tidak valid. Silakan login kembali.');
      }

      // Membuat map untuk queryParameters, hanya menambahkan jika tidak null
      Map<String, dynamic> queryParameters = {'page': page};
      if (pStatusPengajuanId != null) {
        queryParameters['p_status_pengajuan_id'] = pStatusPengajuanId;
      }
      if (pJenisPinjamanId != null) {
        queryParameters['p_jenis_pinjaman_id'] = pJenisPinjamanId;
      }
      if (pPinjamanKeperluanId != null && pPinjamanKeperluanId.isNotEmpty) {
        // Pastikan tidak string kosong juga
        queryParameters['p_pinjaman_keperluan_id'] = pPinjamanKeperluanId;
      }
      if (month != null) {
        queryParameters['month'] = month;
      }
      if (year != null) {
        queryParameters['year'] = year;
      }

      print(
        'ApiService: Mengambil daftar pinjaman dengan filter: $queryParameters',
      );
      final Response response = await _dio.post(
        endpoint,
        queryParameters: queryParameters, // Mengirim parameter filter
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        print(
          'ApiService: Respons diterima dari $endpoint: ${response.statusCode}',
        );
        return PinjamanListResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        print('ApiService: Respons tidak valid dari $endpoint');
        throw Exception(
          'Gagal mengambil daftar pinjaman: Respons tidak valid dari server.',
        );
      }
    } on DioException catch (e) {
      print(
        'ApiService: DioException saat getListPengajuanPinjaman: ${e.message}',
      );
      if (e.response != null) {
        print('ApiService: DioException response data: ${e.response?.data}');
        String errorMessage =
            e.response?.data?['message'] ?? 'Gagal mengambil data dari server.';
        if (e.response?.statusCode == 401) {
          errorMessage = 'Sesi berakhir atau tidak valid. Silakan login ulang.';
        }
        throw Exception('$errorMessage (Status: ${e.response?.statusCode})');
      } else {
        throw Exception(
          'Gagal terhubung ke server atau terjadi kesalahan jaringan: ${e.message}',
        );
      }
    } catch (e) {
      print('ApiService: Error umum saat getListPengajuanPinjaman: $e');
      throw Exception('Terjadi kesalahan tidak terduga: $e');
    }
  }

  static Future<List<MasterStatusPengajuanSimpleModel>>
  getMasterStatusPengajuan() async {
    final String endpoint = "/api/master/status-pengajuan-pinjaman";
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      Options? options;
      if (token != null && token.isNotEmpty) {
        options = Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      } else {
        options = Options(headers: {'Accept': 'application/json'});
        print(
          "ApiService: Warning - Token tidak ditemukan untuk getMasterStatusPengajuan. Mencoba tanpa token.",
        );
        // throw Exception('Sesi tidak valid untuk mengambil data master.'); // Uncomment jika token wajib
      }

      print(
        'ApiService: Mengambil daftar master status pengajuan dari $endpoint',
      );
      final Response response = await _dio.get(endpoint, options: options);

      if (response.data != null && response.data is Map<String, dynamic>) {
        print(
          'ApiService: Respons master status pengajuan diterima: ${response.statusCode}',
        );

        // --- PERBAIKAN UTAMA DI SINI ---
        // Gunakan StatusPengajuanMasterListResponse untuk mem-parsing seluruh objek JSON
        StatusPengajuanMasterListResponse listResponse =
            StatusPengajuanMasterListResponse.fromJson(
              response.data as Map<String, dynamic>,
            );

        if (listResponse.success) {
          // Kembalikan list status pengajuan dari dalam objek data
          return listResponse.statusPengajuan;
        } else {
          throw Exception(
            listResponse.message ??
                'Gagal mengambil data status pengajuan dari API.',
          );
        }
        // --- AKHIR PERBAIKAN UTAMA ---
      } else {
        throw Exception(
          'Gagal mengambil master status pengajuan: Respons tidak valid dari server.',
        );
      }
    } on DioException catch (e) {
      print(
        'ApiService: DioException saat getMasterStatusPengajuan: ${e.message}',
      );
      if (e.response != null) {
        print(
          'ApiService: DioException response data (master status): ${e.response?.data}',
        );
        String errorMessage =
            (e.response?.data as Map<String, dynamic>?)?['message']
                as String? ?? // Akses message dengan aman
            'Gagal mengambil data master status.';
        if (e.response?.statusCode == 401) {
          errorMessage = 'Sesi berakhir atau tidak valid. Silakan login ulang.';
        }
        // Anda bisa menambahkan parsing error yang lebih detail dari e.response?.data jika ada
        throw Exception('$errorMessage (Status: ${e.response?.statusCode})');
      } else {
        throw Exception(
          'Gagal terhubung ke server atau terjadi kesalahan jaringan (master status): ${e.message}',
        );
      }
    } catch (e) {
      print('ApiService: Error umum saat getMasterStatusPengajuan: $e');
      throw Exception(
        'Terjadi kesalahan tidak terduga saat mengambil master status: $e',
      );
    }
  }

  Future<TagihanAnggotaResponse> getTagihanByAnggota({
    int? bulan, // Opsional
    int? tahun, // Opsional
    int? pAnggotaId, // Opsional
  }) async {
    const String endpoint = '/api/tagihan/anggota';
    String? authToken;

    try {
      authToken = await _getAuthToken();

      if (authToken == null || authToken.isEmpty) {
        print(
          "[ApiService.getTagihanByAnggota] ERROR: Auth Token is required.",
        );
        // Anda bisa melempar error atau mengembalikan response error default
        throw Exception("Sesi tidak valid. Silakan login kembali.");
      }

      print("[ApiService.getTagihanByAnggota] Using Auth Token.");

      // Membuat payload dinamis, hanya menyertakan field yang tidak null
      Map<String, dynamic> payload = {};
      if (bulan != null) {
        payload['bulan'] = bulan;
      }
      if (tahun != null) {
        payload['tahun'] = tahun;
      }
      if (pAnggotaId != null) {
        payload['p_anggota_id'] = pAnggotaId;
      }
      // Jika semua optional, dan payload kosong, API mungkin tetap mengembalikan sesuatu
      // atau Anda bisa menambahkan logika untuk kasus payload kosong jika diperlukan.
      // Untuk saat ini, kita kirim payload apa adanya (bisa kosong).

      print(
        "[ApiService.getTagihanByAnggota] Submitting to $endpoint with payload: $payload",
      );

      final response = await _dio.post(
        // Asumsi endpoint ini menggunakan metode POST
        endpoint,
        data:
            payload.isNotEmpty
                ? payload
                : null, // Kirim null jika payload kosong, atau {} tergantung API
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
            if (payload.isNotEmpty) 'Content-Type': 'application/json',
          },
        ),
      );

      print(
        "[ApiService.getTagihanByAnggota] Response status: ${response.statusCode}",
      );
      // print("[ApiService.getTagihanByAnggota] Response data: ${response.data}"); // Hati-hati jika data besar

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return TagihanAnggotaResponse.fromJson(
            response.data as Map<String, dynamic>,
          );
        } else {
          print(
            "[ApiService.getTagihanByAnggota] ERROR: Unexpected response data format.",
          );
          throw Exception(
            "Format respons server tidak valid untuk data tagihan.",
          );
        }
      } else {
        // Dio biasanya sudah throw error untuk status non-2xx
        String message = "Gagal memuat data tagihan.";
        if (response.data is Map<String, dynamic> &&
            (response.data as Map<String, dynamic>)['message'] != null) {
          message = (response.data as Map<String, dynamic>)['message'];
        }
        print(
          "[ApiService.getTagihanByAnggota] ERROR: Failed with status ${response.statusCode}. Message: $message",
        );
        throw Exception("$message (Status: ${response.statusCode})");
      }
    } on DioException catch (e) {
      print("[ApiService.getTagihanByAnggota] DioException caught!");
      print("  -> DioException Type: ${e.type}");
      print("  -> Request URL: ${e.requestOptions.uri}");
      print("  -> Request Payload: ${e.requestOptions.data}");
      if (e.response != null) {
        print("  -> Response Status: ${e.response?.statusCode}");
        print("  -> Response Data: ${e.response?.data}");
      } else {
        print("  -> No response from server.");
      }
      print("  -> DioException Message: ${e.message}");

      String errorMessage = "Gagal mengambil data tagihan.";
      if (e.response?.statusCode == 401) {
        errorMessage =
            "Sesi Anda telah berakhir atau token tidak valid. Silakan login kembali.";
      } else if (e.response?.data is Map<String, dynamic>) {
        final responseData = e.response!.data as Map<String, dynamic>;
        errorMessage = responseData['message'] as String? ?? errorMessage;
        if (e.response?.statusCode == 422 &&
            responseData['errors'] is Map<String, dynamic>) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            final firstErrorField = errors.keys.first;
            final firstErrorMessage =
                (errors[firstErrorField] as List).isNotEmpty
                    ? (errors[firstErrorField] as List).first
                    : "Data tidak valid.";
            errorMessage = "Validasi gagal: $firstErrorMessage";
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Koneksi timeout. Periksa jaringan Anda dan coba lagi.";
      } else if (e.type == DioExceptionType.unknown ||
          e.type == DioExceptionType.connectionError) {
        errorMessage =
            "Koneksi internet bermasalah atau server tidak dapat dijangkau.";
      }
      throw Exception(errorMessage);
    } catch (e) {
      print("[ApiService.getTagihanByAnggota] General Exception caught: $e");
      throw Exception("Terjadi kesalahan sistem: $e");
    }
  }

  Future<TagihanAnggotaResponse> getTagihanByNomorPinjaman({
    required String nomorPinjaman, // Parameter wajib
    int? bulan, // Opsional
    int? tahun, // Opsional
  }) async {
    const String endpoint = '/api/tagihan/pinjaman'; // Endpoint baru
    String? authToken;

    try {
      authToken = await _getAuthToken();

      if (authToken == null || authToken.isEmpty) {
        print(
          "[ApiService.getTagihanByNomorPinjaman] ERROR: Auth Token is required.",
        );
        throw Exception("Sesi tidak valid. Silakan login kembali.");
      }

      print("[ApiService.getTagihanByNomorPinjaman] Using Auth Token.");

      // Membuat payload dinamis
      Map<String, dynamic> payload = {
        'nomor_pinjaman': nomorPinjaman, // Parameter wajib
      };
      if (bulan != null) {
        payload['bulan'] = bulan;
      }
      if (tahun != null) {
        payload['tahun'] = tahun;
      }

      print(
        "[ApiService.getTagihanByNomorPinjaman] Submitting to $endpoint with payload: $payload",
      );

      final response = await _dio.post(
        // Asumsi endpoint ini juga menggunakan metode POST
        endpoint,
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(
        "[ApiService.getTagihanByNomorPinjaman] Response status: ${response.statusCode}",
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          // Menggunakan model yang sama karena struktur respons identik
          return TagihanAnggotaResponse.fromJson(
            response.data as Map<String, dynamic>,
          );
        } else {
          print(
            "[ApiService.getTagihanByNomorPinjaman] ERROR: Unexpected response data format.",
          );
          throw Exception(
            "Format respons server tidak valid untuk data tagihan pinjaman.",
          );
        }
      } else {
        String message = "Gagal memuat data tagihan pinjaman.";
        if (response.data is Map<String, dynamic> &&
            (response.data as Map<String, dynamic>)['message'] != null) {
          message = (response.data as Map<String, dynamic>)['message'];
        }
        print(
          "[ApiService.getTagihanByNomorPinjaman] ERROR: Failed with status ${response.statusCode}. Message: $message",
        );
        throw Exception("$message (Status: ${response.statusCode})");
      }
    } on DioException catch (e) {
      print("[ApiService.getTagihanByNomorPinjaman] DioException caught!");
      // ... (logging error DioException yang detail seperti pada metode getTagihanByAnggota) ...

      String errorMessage = "Gagal mengambil data tagihan pinjaman.";
      if (e.response?.statusCode == 401) {
        errorMessage =
            "Sesi Anda telah berakhir atau token tidak valid. Silakan login kembali.";
      } else if (e.response?.data is Map<String, dynamic>) {
        final responseData = e.response!.data as Map<String, dynamic>;
        errorMessage = responseData['message'] as String? ?? errorMessage;
        if (e.response?.statusCode == 422 &&
            responseData['errors'] is Map<String, dynamic>) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            final firstErrorField = errors.keys.first;
            final firstErrorMessage =
                (errors[firstErrorField] as List).isNotEmpty
                    ? (errors[firstErrorField] as List).first
                    : "Data tidak valid.";
            errorMessage = "Validasi gagal: $firstErrorMessage";
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Koneksi timeout. Periksa jaringan Anda dan coba lagi.";
      } else if (e.type == DioExceptionType.unknown ||
          e.type == DioExceptionType.connectionError) {
        errorMessage =
            "Koneksi internet bermasalah atau server tidak dapat dijangkau.";
      }
      throw Exception(errorMessage);
    } catch (e) {
      print(
        "[ApiService.getTagihanByNomorPinjaman] General Exception caught: $e",
      );
      throw Exception("Terjadi kesalahan sistem: $e");
    }
  }

  Future<List<ChatReferenceTableItem>> getChatReferenceTable() async {
    const String endpoint = '/api/master/chat-reference-table';
    try {
      final String? token = await _getAuthToken();
      // Diasumsikan endpoint ini memerlukan token, jika tidak, hapus pengecekan token
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final chatRefResponse = ChatReferenceTableResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        if (chatRefResponse.success) {
          return chatRefResponse.data;
        } else {
          throw Exception(chatRefResponse.message);
        }
      } else {
        throw Exception(
          'Gagal mengambil data referensi chat. Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('[ApiService.getChatReferenceTable] DioError: ${e.message}');
      print('[ApiService.getChatReferenceTable] Response: ${e.response?.data}');
      throw Exception(
        'Gagal mengambil data referensi chat: ${e.response?.data?['message'] ?? e.message}',
      );
    } catch (e) {
      print('[ApiService.getChatReferenceTable] Error: $e');
      rethrow;
    }
  }

  Future<CreateTicketResponse> createTicket({
    required int pChatReferenceTableId,
    required int transactionId,
    required String subject,
  }) async {
    const String endpoint = '/api/chat/ticket/add';
    try {
      final String? token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      final Map<String, dynamic> payload = {
        "p_chat_reference_table_id": pChatReferenceTableId,
        "transaction_id": transactionId,
        "subject": subject,
      };

      final response = await _dio.post(
        endpoint,
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return CreateTicketResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        String errorMessage =
            'Gagal membuat tiket. Status: ${response.statusCode}';
        if (response.data is Map<String, dynamic> &&
            response.data['message'] != null) {
          errorMessage =
              'Gagal membuat tiket: ${response.data['message']} (Status: ${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('[ApiService.createTicket] DioError: ${e.message}');
      print('[ApiService.createTicket] Response: ${e.response?.data}');
      throw Exception(
        'Gagal membuat tiket: ${e.response?.data?['message'] ?? e.message}',
      );
    } catch (e) {
      print('[ApiService.createTicket] Error: $e');
      rethrow;
    }
  }

  // --- METODE BARU UNTUK MENGAMBIL DAFTAR TIKET ---
  Future<TicketListResponseModel> getTicketList({
    required int page,
    required int perpage,
    TicketListFilterPayload? filter, // Filter opsional
  }) async {
    const String endpoint = '/api/chat/ticket/grid';
    try {
      final String? token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      Map<String, dynamic> payload = {"page": page, "perpage": perpage};

      // Jika ada filter, tambahkan ke dalam sub-objek 'data'
      // Jika filter null atau semua field di dalamnya null, kirim objek 'data' kosong
      // Atau, jika API tidak mau objek 'data' jika kosong, jangan kirim sama sekali.
      // Asumsi: API mengharapkan objek 'data' ada.
      if (filter != null) {
        payload['data'] = filter.toJson();
      } else {
        // Jika tidak ada filter, API mungkin tetap mengharapkan objek 'data' (kosong atau dengan default)
        // Sesuai payload: "data" : { "p_chat_reference_table_id" : 1, // optional ... }
        // Jika tidak ada filter, kita bisa kirim objek data kosong, atau tidak mengirim key 'data' sama sekali.
        // Untuk amannya, kita kirim objek 'data' kosong jika filter null.
        payload['data'] =
            {}; // Objek data kosong jika tidak ada filter spesifik
      }

      final response = await _dio.post(
        endpoint,
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return TicketListResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        String errorMessage =
            'Gagal mengambil daftar tiket. Status: ${response.statusCode}';
        if (response.data is Map<String, dynamic> &&
            response.data['message'] != null) {
          errorMessage =
              'Gagal mengambil daftar tiket: ${response.data['message']} (Status: ${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('[ApiService.getTicketList] DioError: ${e.message}');
      print('[ApiService.getTicketList] Response: ${e.response?.data}');
      throw Exception(
        'Gagal mengambil daftar tiket: ${e.response?.data?['message'] ?? e.message}',
      );
    } catch (e) {
      print('[ApiService.getTicketList] Error: $e');
      rethrow;
    }
  }

  Future<ChatMessagesResponseModel> getChatMessages(
    String tChatId, {
    int? currentUserId,
  }) async {
    final String endpoint = '/api/chat/message/open/$tChatId';
    try {
      final String? token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return ChatMessagesResponseModel.fromJson(
          response.data as Map<String, dynamic>,
          currentUserId: currentUserId,
        );
      } else {
        throw Exception(
          'Gagal mengambil pesan chat: ${response.data?['message'] ?? 'Status ${response.statusCode}'}',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        'Gagal mengambil pesan chat: ${e.response?.data?['message'] ?? e.message}',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<SendMessageResponseModel> sendChatMessage({
    required String tChatId,
    required String messageText,
    int? currentUserId, // Untuk menandai pesan baru sebagai milik currentUser
  }) async {
    const String endpoint = '/api/chat/message/add';
    try {
      final String? token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }
      final Map<String, dynamic> payload = {
        "t_chat_id": tChatId.trim(), // Pastikan tChatId di-trim
        "message_text": messageText,
      };
      final response = await _dio.post(
        endpoint,
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return SendMessageResponseModel.fromJson(
          response.data as Map<String, dynamic>,
          currentUserId: currentUserId,
        );
      } else {
        throw Exception(
          'Gagal mengirim pesan: ${response.data?['message'] ?? 'Status ${response.statusCode}'}',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        'Gagal mengirim pesan: ${e.response?.data?['message'] ?? e.message}',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfileAnggota({
    required int pAnggotaId,
    required String tglLahir, // Format Wajib: "YYYY-MM-DD"
    String? alamat, // Opsional
    String? alamatEmail, // Opsional
    String? nomorHp, // Opsional
  }) async {
    const String endpoint = '/api/profile';
    String? authToken;

    try {
      authToken = await _getAuthToken();

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }

      // Membuat payload. Field opsional hanya ditambahkan jika tidak null.
      // Ini mencegah pengiriman key dengan nilai null ke backend.
      final Map<String, dynamic> payload = {
        'p_anggota_id': pAnggotaId,
        'tgl_lahir': tglLahir,
      };
      if (alamat != null) payload['alamat'] = alamat;
      if (alamatEmail != null) payload['alamat_email'] = alamatEmail;
      if (nomorHp != null) payload['nomor_hp'] = nomorHp;

      print(
        "[ApiService.updateProfileAnggota] Mengirim PUT ke $endpoint dengan payload: ${json.encode(payload)}",
      );

      // Menggunakan dio.put
      final response = await _dio.put(
        endpoint,
        data: payload, // Mengirim payload sebagai data
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(
        "[ApiService.updateProfileAnggota] Response status: ${response.statusCode}",
      );
      print(
        "[ApiService.updateProfileAnggota] Response data: ${response.data}",
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else {
          throw Exception(
            "Format respons server tidak valid setelah pembaruan profil.",
          );
        }
      } else {
        // Fallback, meskipun DioException akan menangani ini
        throw Exception(
          "Gagal memperbarui profil (Status: ${response.statusCode})",
        );
      }
    } on DioException catch (e) {
      print("[ApiService.updateProfileAnggota] DioException caught!");
      print("  -> Response Status: ${e.response?.statusCode}");
      print("  -> Response Data: ${e.response?.data}");

      String errorMessage = "Gagal memperbarui profil.";
      if (e.response?.data is Map<String, dynamic>) {
        final responseData = e.response!.data as Map<String, dynamic>;
        errorMessage = responseData['message'] as String? ?? errorMessage;
        if (e.response?.statusCode == 422 &&
            responseData['errors'] is Map<String, dynamic>) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            final firstErrorField = errors.keys.first;
            final firstErrorMessage =
                (errors[firstErrorField] as List).isNotEmpty
                    ? (errors[firstErrorField] as List).first
                    : "Data tidak valid.";
            errorMessage = "Validasi gagal: $firstErrorMessage";
          }
        }
      } else if (e.response?.statusCode == 401) {
        errorMessage = "Sesi Anda telah berakhir. Silakan login kembali.";
      }

      throw Exception(errorMessage);
    } catch (e) {
      print("[ApiService.updateProfileAnggota] General Exception caught: $e");
      throw Exception("Terjadi kesalahan sistem saat memperbarui profil: $e");
    }
  }
}
