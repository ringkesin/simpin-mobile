// lib/model/anggota_profile_response.dart

import 'dart:convert'; // Opsional, hanya jika perlu jsonEncode/Decode di tempat lain

// -----------------------------------
// Root Response Model
// -----------------------------------
class AnggotaProfileResponse {
  final bool success;
  final ProfileData? data; // Nullable jika success = false atau data tidak ada
  final String? message;

  AnggotaProfileResponse({required this.success, this.data, this.message});

  factory AnggotaProfileResponse.fromJson(Map<String, dynamic> json) =>
      AnggotaProfileResponse(
        success: json["success"] ?? false, // Default ke false jika null
        // Parse data hanya jika success=true dan data tidak null
        data:
            json["success"] == true && json["data"] != null
                ? ProfileData.fromJson(json["data"])
                : null,
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data?.toJson(),
    "message": message,
  };
}

// -----------------------------------
// Wrapper Data Model
// -----------------------------------
class ProfileData {
  final AnggotaProfile? anggota; // Bisa null

  ProfileData({this.anggota});

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
    // Handle jika 'anggota' null atau bukan map
    anggota:
        (json["anggota"] != null && json["anggota"] is Map<String, dynamic>)
            ? AnggotaProfile.fromJson(json["anggota"])
            : null,
  );

  Map<String, dynamic> toJson() => {"anggota": anggota?.toJson()};
}

// -----------------------------------
// Anggota Profile Model (isRegistered = bool?)
// -----------------------------------
class AnggotaProfile {
  final int? pAnggotaId;
  final String? nomorAnggota;
  final String? tanggalMasuk;
  final String? nama;
  final String? nik;
  final String? alamat;
  final String? ktp;
  final String? tempatLahir;
  final String? tglLahir;
  final String? email;
  final String? mobile;
  final bool? isRegistered; // <-- Tipe diubah menjadi bool?
  final int? userId;
  final List<dynamic>? atribut; // Gunakan List<dynamic>
  final dynamic unit; // Gunakan dynamic jika tipe bervariasi atau tidak pasti

  AnggotaProfile({
    this.pAnggotaId = 0,
    this.nomorAnggota = '',
    this.tanggalMasuk = '',
    this.nama = '',
    this.nik = '',
    this.alamat = '',
    this.ktp = '',
    this.tempatLahir = '',
    this.tglLahir = '',
    this.email, // Default null untuk String?
    this.mobile, // Default null untuk String?
    this.isRegistered = false, // Default ke false untuk bool?
    this.userId = 0,
    this.atribut = const [], // Default list kosong
    this.unit, // Default null untuk dynamic
  });

  factory AnggotaProfile.fromJson(Map<String, dynamic> json) => AnggotaProfile(
    pAnggotaId: (json["p_anggota_id"] as int?) ?? 0,
    nomorAnggota: (json["nomor_anggota"] as String?) ?? '',
    tanggalMasuk: (json["tanggal_masuk"] as String?) ?? '',
    nama: (json["nama"] as String?) ?? '',
    nik: (json["nik"] as String?) ?? '',
    alamat: (json["alamat"] as String?) ?? '',
    ktp: (json["ktp"] as String?) ?? '',
    tempatLahir: (json["tempat_lahir"] as String?) ?? '',
    tglLahir: (json["tgl_lahir"] as String?) ?? '',
    email: json["email"] as String?, // Ambil langsung sebagai String?
    mobile: json["mobile"] as String?, // Ambil langsung sebagai String?
    // Parsing is_registered sebagai bool?, default false jika null
    isRegistered: (json["is_registered"] as bool?) ?? false,

    userId: (json["user_id"] as int?) ?? 0,
    // Parsing list 'atribut' dengan aman
    atribut:
        (json["atribut"] != null && json["atribut"] is List)
            ? List<dynamic>.from(json["atribut"].map((x) => x))
            : [], // Default list kosong jika null atau bukan list
    unit: json["unit"], // Ambil langsung sebagai dynamic
  );

  Map<String, dynamic> toJson() => {
    "p_anggota_id": pAnggotaId,
    "nomor_anggota": nomorAnggota,
    "tanggal_masuk": tanggalMasuk,
    "nama": nama,
    "nik": nik,
    "alamat": alamat,
    "ktp": ktp,
    "tempat_lahir": tempatLahir,
    "tgl_lahir": tglLahir,
    "email": email,
    "mobile": mobile,
    // Serialisasi isRegistered sebagai boolean
    "is_registered": isRegistered,
    "user_id": userId,
    // Serialisasi list 'atribut' dengan aman
    "atribut":
        atribut == null ? [] : List<dynamic>.from(atribut!.map((x) => x)),
    "unit": unit,
  };

  // Getter helper (jika diperlukan)
  bool get isActuallyRegistered => isRegistered == true;
}
