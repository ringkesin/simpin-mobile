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
  // Jadikan semua field nullable (?)
  final int? pAnggotaId;
  final String? nomorAnggota;
  final String? tanggalMasuk;
  final String? nama;
  final String? nik;
  final String? alamat;
  final String? ktp;
  final String? tempatLahir;
  final String? tglLahir;
  final String? email; // Tambahkan ?
  final String? mobile; // Tambahkan ?

  // Tambahkan nilai default di constructor
  Anggota({
    this.pAnggotaId = 0, // Default int
    this.nomorAnggota = '', // Default String
    this.tanggalMasuk = '',
    this.nama = '',
    this.nik = '',
    this.alamat = '',
    this.ktp = '',
    this.tempatLahir = '',
    this.tglLahir = '',
    this.email = '', // Default String
    this.mobile = '', // Default String
  });

  factory Anggota.fromJson(Map<String, dynamic> json) {
    return Anggota(
      // Tambahkan cast (as T?) dan null coalescing (??) untuk SEMUA field
      pAnggotaId: (json['p_anggota_id'] as int?) ?? 0,
      nomorAnggota: (json['nomor_anggota'] as String?) ?? '',
      tanggalMasuk: (json['tanggal_masuk'] as String?) ?? '',
      nama: (json['nama'] as String?) ?? '',
      nik: (json['nik'] as String?) ?? '',
      alamat: (json['alamat'] as String?) ?? '',
      ktp: (json['ktp'] as String?) ?? '',
      tempatLahir: (json['tempat_lahir'] as String?) ?? '',
      tglLahir: (json['tgl_lahir'] as String?) ?? '',
      email: (json['email'] as String?) ?? '', // Handle null email
      mobile: (json['mobile'] as String?) ?? '', // Handle null mobile
    );
  }

  // Opsional: Tambahkan toString dan toJson jika perlu
  @override
  String toString() {
    return 'Anggota(pAnggotaId: $pAnggotaId, nomorAnggota: $nomorAnggota, nama: $nama, email: $email, mobile: $mobile, ...)';
  }

  Map<String, dynamic> toJson() {
    return {
      'p_anggota_id': pAnggotaId,
      'nomor_anggota': nomorAnggota,
      'tanggal_masuk': tanggalMasuk,
      'nama': nama,
      'nik': nik,
      'alamat': alamat,
      'ktp': ktp,
      'tempat_lahir': tempatLahir,
      'tgl_lahir': tglLahir,
      'email': email,
      'mobile': mobile,
    };
  }
}

class User {
  final int? id;
  final String? name;
  final String? username;
  final String? email;
  final String? mobile;
  final String? profilePhotoPath;
  final String? profilePhotoUrl;

  // Constructor dengan nilai default untuk parameter opsional
  User({
    this.id = 0, // Default int
    this.name = '', // Default String kosong
    this.username = '', // Default String kosong
    this.email = '', // Default String kosong
    this.mobile = '', // Default String kosong
    this.profilePhotoPath = '', // Default String kosong
    this.profilePhotoUrl = '', // Default String kosong
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Gunakan '??' untuk memberikan default jika hasil cast null
      id: (json['id'] as int?) ?? 0, // Default 0 jika null
      name: (json['name'] as String?) ?? '', // Default '' jika null
      username: (json['username'] as String?) ?? '', // Default '' jika null
      email: (json['email'] as String?) ?? '', // Default '' jika null
      mobile: (json['mobile'] as String?) ?? '', // Default '' jika null
      profilePhotoPath:
          (json['profile_photo_path'] as String?) ?? '', // Default '' jika null
      profilePhotoUrl:
          (json['profile_photo_url'] as String?) ?? '', // Default '' jika null
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, username: $username, email: $email, mobile: $mobile, profilePhotoPath: $profilePhotoPath, profilePhotoUrl: $profilePhotoUrl)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'mobile': mobile,
      'profile_photo_path': profilePhotoPath,
      'profile_photo_url': profilePhotoUrl,
    };
  }
}
