// lib/model/anggota_registrasi_response.dart

class AnggotaRegistrasiResponse {
  final bool success;
  final List<AnggotaRegistrasiItem> data;
  final String message;
  final int? currentPage;
  final int? lastPage;
  final int? total;

  AnggotaRegistrasiResponse({
    required this.success,
    required this.data,
    required this.message,
    this.currentPage,
    this.lastPage,
    this.total,
  });

  factory AnggotaRegistrasiResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<AnggotaRegistrasiItem> items = [];
    int? currentPage;
    int? lastPage;
    int? total;

    if (rawData is List) {
      items =
          rawData
              .whereType<Map>()
              .map(
                (e) =>
                    AnggotaRegistrasiItem.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
    } else if (rawData is Map<String, dynamic>) {
      currentPage = rawData['current_page'] as int?;
      lastPage = rawData['last_page'] as int?;
      total = rawData['total'] as int?;
      final inner = rawData['data'];
      if (inner is List) {
        items =
            inner
                .whereType<Map>()
                .map(
                  (e) => AnggotaRegistrasiItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList();
      }
    }

    return AnggotaRegistrasiResponse(
      success: json['success'] == true,
      data: items,
      message: json['message']?.toString() ?? '',
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  bool get hasMore {
    if (currentPage == null || lastPage == null) return false;
    return currentPage! < lastPage!;
  }
}

class AnggotaRegistrasiItem {
  final int pAnggotaId;
  final String? nomorAnggota;
  final String? validFrom;
  final String? validTo;
  final String? tanggalMasuk;
  final String nama;
  final String? nik;
  final String? alamat;
  final String? ktp;
  final String? tempatLahir;
  final String? tglLahir;
  final String? email;
  final String? noHp;
  final String? status;
  final bool? hasUser;

  AnggotaRegistrasiItem({
    required this.pAnggotaId,
    this.nomorAnggota,
    this.validFrom,
    this.validTo,
    this.tanggalMasuk,
    required this.nama,
    this.nik,
    this.alamat,
    this.ktp,
    this.tempatLahir,
    this.tglLahir,
    this.email,
    this.noHp,
    this.status,
    this.hasUser,
  });

  factory AnggotaRegistrasiItem.fromJson(Map<String, dynamic> json) {
    return AnggotaRegistrasiItem(
      pAnggotaId: _parseInt(json['p_anggota_id']) ?? 0,
      nomorAnggota: json['nomor_anggota']?.toString(),
      validFrom: json['valid_from']?.toString(),
      validTo: json['valid_to']?.toString(),
      tanggalMasuk: json['tanggal_masuk']?.toString(),
      nama: json['nama']?.toString() ?? '-',
      nik: json['nik']?.toString(),
      alamat: json['alamat']?.toString(),
      ktp: json['ktp']?.toString(),
      tempatLahir: json['tempat_lahir']?.toString(),
      tglLahir: json['tgl_lahir']?.toString(),
      email: json['email']?.toString(),
      noHp: (json['no_hp'] ?? json['mobile'] ?? json['telepon'])?.toString(),
      status: json['status']?.toString(),
      hasUser: json['has_user'] is bool ? json['has_user'] as bool : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
