import 'dart:convert';

// Fungsi helper (opsional)
ProfileResponseComplex profileResponseComplexFromJson(String str) =>
    ProfileResponseComplex.fromJson(json.decode(str));
String profileResponseComplexToJson(ProfileResponseComplex data) =>
    json.encode(data.toJson());

class ProfileResponseComplex {
  final bool success;
  final ProfileDataComplex? data;
  final String message;

  ProfileResponseComplex({
    required this.success,
    this.data,
    required this.message,
  });

  factory ProfileResponseComplex.fromJson(Map<String, dynamic> json) =>
      ProfileResponseComplex(
        success: json["success"] ?? false,
        data:
            json["data"] == null
                ? null
                : ProfileDataComplex.fromJson(json["data"]),
        message: json["message"] ?? "",
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data?.toJson(),
    "message": message,
  };
}

class ProfileDataComplex {
  final ProfileUser? profileUser;
  final ProfileAnggota? profileAnggota;

  ProfileDataComplex({this.profileUser, this.profileAnggota});

  factory ProfileDataComplex.fromJson(Map<String, dynamic> json) =>
      ProfileDataComplex(
        profileUser:
            json["profile_user"] == null
                ? null
                : ProfileUser.fromJson(json["profile_user"]),
        profileAnggota:
            json["profile_anggota"] == null
                ? null
                : ProfileAnggota.fromJson(json["profile_anggota"]),
      );

  Map<String, dynamic> toJson() => {
    "profile_user": profileUser?.toJson(),
    "profile_anggota": profileAnggota?.toJson(),
  };
}

class ProfileUser {
  final int id;
  final String? name;
  final String? username;
  final String? email;
  final DateTime? emailVerifiedAt; // Diparsing sebagai DateTime
  final String? mobile;
  final int? currentTeamId;
  final String? remarks;
  final DateTime? validFrom; // Diparsing sebagai DateTime
  final DateTime? validUntil; // Diparsing sebagai DateTime
  final String? profilePhotoPath;
  final DateTime? twoFactorConfirmedAt; // Diparsing sebagai DateTime
  final String? profilePhotoUrl;

  ProfileUser({
    required this.id,
    this.name,
    this.username,
    this.email,
    this.emailVerifiedAt,
    this.mobile,
    this.currentTeamId,
    this.remarks,
    this.validFrom,
    this.validUntil,
    this.profilePhotoPath,
    this.twoFactorConfirmedAt,
    this.profilePhotoUrl,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) => ProfileUser(
    id: json["id"] ?? 0,
    name: json["name"],
    username: json["username"],
    email: json["email"],
    emailVerifiedAt:
        json["email_verified_at"] == null
            ? null
            : DateTime.tryParse(json["email_verified_at"]),
    mobile: json["mobile"],
    currentTeamId: json["current_team_id"],
    remarks: json["remarks"],
    validFrom:
        json["valid_from"] == null
            ? null
            : DateTime.tryParse(json["valid_from"]),
    validUntil:
        json["valid_until"] == null
            ? null
            : DateTime.tryParse(json["valid_until"]),
    profilePhotoPath: json["profile_photo_path"],
    twoFactorConfirmedAt:
        json["two_factor_confirmed_at"] == null
            ? null
            : DateTime.tryParse(json["two_factor_confirmed_at"]),
    profilePhotoUrl: json["profile_photo_url"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "username": username,
    "email": email,
    "email_verified_at": emailVerifiedAt?.toIso8601String(),
    "mobile": mobile,
    "current_team_id": currentTeamId,
    "remarks": remarks,
    "valid_from": validFrom?.toIso8601String(),
    "valid_until": validUntil?.toIso8601String(),
    "profile_photo_path": profilePhotoPath,
    "two_factor_confirmed_at": twoFactorConfirmedAt?.toIso8601String(),
    "profile_photo_url": profilePhotoUrl,
  };
}

class ProfileAnggota {
  final int pAnggotaId;
  final String? nomorAnggota;
  final String? tanggalMasuk; // Tetap String, atau parse ke DateTime jika perlu
  final String? nama;
  final String? nik;
  final String? alamat;
  final String? ktp;
  final String? tempatLahir;
  final String? tglLahir; // Tetap String, atau parse ke DateTime jika perlu
  final String? email;
  final String? mobile;
  final bool isRegistered;
  final int userId;
  final List<dynamic> atribut;
  final dynamic unit;

  ProfileAnggota({
    required this.pAnggotaId,
    this.nomorAnggota,
    this.tanggalMasuk,
    this.nama,
    this.nik,
    this.alamat,
    this.ktp,
    this.tempatLahir,
    this.tglLahir,
    this.email,
    this.mobile,
    required this.isRegistered,
    required this.userId,
    required this.atribut,
    this.unit,
  });

  factory ProfileAnggota.fromJson(Map<String, dynamic> json) => ProfileAnggota(
    pAnggotaId: json["p_anggota_id"] ?? 0,
    nomorAnggota: json["nomor_anggota"],
    tanggalMasuk: json["tanggal_masuk"],
    nama: json["nama"],
    nik: json["nik"],
    alamat: json["alamat"],
    ktp: json["ktp"],
    tempatLahir: json["tempat_lahir"],
    tglLahir: json["tgl_lahir"],
    email: json["email"],
    mobile: json["mobile"],
    isRegistered: json["is_registered"] ?? false,
    userId: json["user_id"] ?? 0,
    atribut:
        json["atribut"] == null
            ? []
            : List<dynamic>.from(json["atribut"].map((x) => x)),
    unit: json["unit"],
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
    "atribut": List<dynamic>.from(atribut.map((x) => x)),
    "unit": unit,
  };
}
