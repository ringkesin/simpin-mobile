// --- Model Utama untuk Response Keseluruhan ---
class TabunganBulananResponse {
  final bool success;
  final TabunganBulananData? data; // Ubah tipe Data dan buat nullable
  final String? message; // Buat nullable

  TabunganBulananResponse({
    required this.success,
    this.data, // Tidak required lagi
    this.message, // Tidak required lagi
  });

  factory TabunganBulananResponse.fromJson(Map<String, dynamic> json) {
    return TabunganBulananResponse(
      // Beri default false jika success null
      success: json['success'] ?? false,
      // Cek jika data null atau bukan Map sebelum parsing
      data:
          json['data'] == null || json['data'] is! Map<String, dynamic>
              ? null
              : TabunganBulananData.fromJson(json['data']),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data?.toJson(),
    "message": message,
  };
}

// --- Model untuk Object 'data' ---
class TabunganBulananData {
  final int? bulan; // Tipe data int? sesuai JSON
  final int? tahun; // Tipe data int? sesuai JSON
  final TotalTabungan? total; // Objek baru untuk total
  final List<DetailTabunganItem>? detail; // List objek baru untuk detail

  TabunganBulananData({this.bulan, this.tahun, this.total, this.detail});

  factory TabunganBulananData.fromJson(Map<String, dynamic> json) {
    // Parsing list detail dengan aman
    List<DetailTabunganItem> detailList = [];
    if (json['detail'] != null && json['detail'] is List) {
      detailList = List<DetailTabunganItem>.from(
        json["detail"].map((x) => DetailTabunganItem.fromJson(x)),
      );
    }

    return TabunganBulananData(
      bulan: (json['bulan'] as int?) ?? 0, // Default 0 jika null
      tahun: (json['tahun'] as int?) ?? 0, // Default 0 jika null
      // Parsing objek total, beri default jika null
      total:
          json['total'] == null || json['total'] is! Map<String, dynamic>
              ? TotalTabungan() // Default object kosong
              : TotalTabungan.fromJson(json['total']),
      detail: detailList, // Gunakan list yang sudah diparsing
    );
  }

  Map<String, dynamic> toJson() => {
    "bulan": bulan,
    "tahun": tahun,
    "total": total?.toJson(),
    "detail":
        detail == null
            ? []
            : List<dynamic>.from(detail!.map((x) => x.toJson())),
  };
}

// --- Model untuk Object 'total' (BARU) ---
class TotalTabungan {
  final num? totalBulanIni; // Gunakan num? untuk fleksibilitas int/double
  final num? totalBulanIniSd;

  TotalTabungan({
    this.totalBulanIni = 0, // Default 0
    this.totalBulanIniSd = 0, // Default 0
  });

  factory TotalTabungan.fromJson(Map<String, dynamic> json) => TotalTabungan(
    totalBulanIni: (json["total_bulan_ini"] as num?) ?? 0,
    totalBulanIniSd: (json["total_bulan_ini_sd"] as num?) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "total_bulan_ini": totalBulanIni,
    "total_bulan_ini_sd": totalBulanIniSd,
  };
}

// --- Model untuk item dalam list 'detail' (BARU) ---
class DetailTabunganItem {
  final String? jenisTabungan; // String?
  final num? nilaiBulanIni; // num?
  final num? nilaiBulanIniSd; // num?

  DetailTabunganItem({
    this.jenisTabungan = '', // Default string kosong
    this.nilaiBulanIni = 0,
    this.nilaiBulanIniSd = 0,
  });

  factory DetailTabunganItem.fromJson(Map<String, dynamic> json) =>
      DetailTabunganItem(
        jenisTabungan: (json["jenis_tabungan"] as String?) ?? '',
        nilaiBulanIni: (json["nilai_bulan_ini"] as num?) ?? 0,
        nilaiBulanIniSd: (json["nilai_bulan_ini_sd"] as num?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "jenis_tabungan": jenisTabungan,
    "nilai_bulan_ini": nilaiBulanIni,
    "nilai_bulan_ini_sd": nilaiBulanIniSd,
  };
}

// Hapus class Data yang lama jika tidak terpakai lagi
// Hapus fungsi formatRupiah dari model, lakukan formatting di UI
