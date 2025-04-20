// models/login_response.dart

class LoginResponse {
  final bool success;
  final LoginData? data;
  final String? message;
  final String? error;

  LoginResponse({required this.success, this.data, this.message, this.error});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
      message: json['message'],
      error: json['error'],
    );
  }
}

class LoginData {
  final String token;
  final String role;
  final Anggota anggota;
  final User user;

  LoginData({
    required this.token,
    required this.role,
    required this.anggota,
    required this.user,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: json['token'],
      role: json['role'],
      anggota: Anggota.fromJson(json['anggota']),
      user: User.fromJson(json['user']),
    );
  }
}

class Anggota {
  final int pAnggotaId;
  final String nomorAnggota;
  final String tanggalMasuk;
  final String nama;
  final String nik;
  final String alamat;
  final String ktp;
  final String tempatLahir;
  final String tglLahir;
  final String email;
  final String mobile;

  Anggota({
    required this.pAnggotaId,
    required this.nomorAnggota,
    required this.tanggalMasuk,
    required this.nama,
    required this.nik,
    required this.alamat,
    required this.ktp,
    required this.tempatLahir,
    required this.tglLahir,
    required this.email,
    required this.mobile,
  });

  factory Anggota.fromJson(Map<String, dynamic> json) {
    return Anggota(
      pAnggotaId: json['p_anggota_id'],
      nomorAnggota: json['nomor_anggota'],
      tanggalMasuk: json['tanggal_masuk'],
      nama: json['nama'],
      nik: json['nik'],
      alamat: json['alamat'],
      ktp: json['ktp'],
      tempatLahir: json['tempat_lahir'],
      tglLahir: json['tgl_lahir'],
      email: json['email'],
      mobile: json['mobile'],
    );
  }
}

class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String mobile;
  final String profilePhotoPath;
  final String profilePhotoUrl;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.mobile,
    required this.profilePhotoPath,
    required this.profilePhotoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      mobile: json['mobile'],
      profilePhotoPath: json['profile_photo_path'],
      profilePhotoUrl: json['profile_photo_url'],
    );
  }
}
