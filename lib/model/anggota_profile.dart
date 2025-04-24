// models/anggota_profile_response.dart

import 'dart:convert'; // For jsonEncode if needed

class AnggotaProfileResponse {
  final bool success;
  final ProfileData? data;
  final String? message;

  AnggotaProfileResponse({required this.success, this.data, this.message});

  factory AnggotaProfileResponse.fromJson(Map<String, dynamic> json) =>
      AnggotaProfileResponse(
        success: json["success"] ?? false,
        data: json["data"] == null ? null : ProfileData.fromJson(json["data"]),
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data?.toJson(),
    "message": message,
  };
}

class ProfileData {
  final AnggotaProfile? anggota;

  ProfileData({this.anggota});

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
    // Handle cases where 'anggota' might be null or not a map
    anggota:
        (json["anggota"] != null && json["anggota"] is Map<String, dynamic>)
            ? AnggotaProfile.fromJson(json["anggota"])
            : null,
  );

  Map<String, dynamic> toJson() => {"anggota": anggota?.toJson()};
}

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
  final int? isRegistered; // Keep as int? to match JSON
  final int? userId;
  final List<dynamic>? atribut; // Use List<dynamic> for safety
  final dynamic unit; // Use dynamic if type is unknown/variable

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
    this.email = '',
    this.mobile = '',
    this.isRegistered = 0,
    this.userId = 0,
    this.atribut = const [], // Default to empty list
    this.unit,
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
    email: (json["email"] as String?) ?? '', // Handle null email
    mobile: (json["mobile"] as String?) ?? '', // Handle null mobile
    isRegistered: (json["is_registered"] as int?) ?? 0,
    userId: (json["user_id"] as int?) ?? 0,
    // Safely handle 'atribut' which is a list
    atribut:
        (json["atribut"] != null && json["atribut"] is List)
            ? List<dynamic>.from(json["atribut"].map((x) => x))
            : [], // Default to empty list if null or not a list
    unit: json["unit"], // Assign directly as dynamic
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
    "is_registered": isRegistered,
    "user_id": userId,
    "atribut":
        atribut == null ? [] : List<dynamic>.from(atribut!.map((x) => x)),
    "unit": unit,
  };

  // Helper to determine registration status maybe?
  bool get isActuallyRegistered => isRegistered == 1;
}
