// models/mutasi_tabungan_response.dart
import 'dart:convert';

// Helper Functions (opsional, bisa ditaruh di file terpisah jika sering dipakai)
MutasiTabunganResponse mutasiTabunganResponseFromJson(String str) =>
    MutasiTabunganResponse.fromJson(json.decode(str));

String mutasiTabunganResponseToJson(MutasiTabunganResponse data) =>
    json.encode(data.toJson());

// --- Root Response Object ---
class MutasiTabunganResponse {
  final bool success;
  final MutasiPaginationData?
  data; // Outer 'data' object which is for pagination
  final String? message;

  MutasiTabunganResponse({required this.success, this.data, this.message});

  factory MutasiTabunganResponse.fromJson(Map<String, dynamic> json) =>
      MutasiTabunganResponse(
        success: json["success"] ?? false,
        data:
            json["data"] == null || json["data"] is! Map<String, dynamic>
                ? null
                : MutasiPaginationData.fromJson(
                  json["data"] as Map<String, dynamic>,
                ),
        message: json["message"] as String?,
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data?.toJson(),
    "message": message,
  };
}

// --- Pagination Data Object (the outer 'data' object in JSON) ---
class MutasiPaginationData {
  final int currentPage;
  final List<MutasiTabunganItem>
  items; // Renamed from 'data' to 'items' for clarity
  final String? firstPageUrl;
  final int? from;
  final int lastPage;
  final String? lastPageUrl;
  final List<LinkItem> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;
  final int totalItems; // Renamed from 'total'

  MutasiPaginationData({
    required this.currentPage,
    required this.items,
    this.firstPageUrl,
    this.from,
    required this.lastPage,
    this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.totalItems,
  });

  factory MutasiPaginationData.fromJson(Map<String, dynamic> json) =>
      MutasiPaginationData(
        currentPage: json["current_page"] as int? ?? 1,
        items:
            json["data"] == null || json["data"] is! List
                ? []
                : List<MutasiTabunganItem>.from(
                  (json["data"] as List).map(
                    (x) =>
                        MutasiTabunganItem.fromJson(x as Map<String, dynamic>),
                  ),
                ),
        firstPageUrl: json["first_page_url"] as String?,
        from: json["from"] as int?,
        lastPage: json["last_page"] as int? ?? 1,
        lastPageUrl: json["last_page_url"] as String?,
        links:
            json["links"] == null || json["links"] is! List
                ? []
                : List<LinkItem>.from(
                  (json["links"] as List).map(
                    (x) => LinkItem.fromJson(x as Map<String, dynamic>),
                  ),
                ),
        nextPageUrl: json["next_page_url"] as String?,
        path: json["path"] as String? ?? '',
        perPage: json["per_page"] as int? ?? 0,
        prevPageUrl: json["prev_page_url"] as String?,
        to: json["to"] as int?,
        totalItems: json["total"] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "current_page": currentPage,
    "data": List<dynamic>.from(items.map((x) => x.toJson())),
    "first_page_url": firstPageUrl,
    "from": from,
    "last_page": lastPage,
    "last_page_url": lastPageUrl,
    "links": List<dynamic>.from(links.map((x) => x.toJson())),
    "next_page_url": nextPageUrl,
    "path": path,
    "per_page": perPage,
    "prev_page_url": prevPageUrl,
    "to": to,
    "total": totalItems,
  };
}

// --- Individual Mutation Item (item in the inner 'data' array) ---
class MutasiTabunganItem {
  final String tTabunganJurnalId;
  final DateTime? tglTransaksi; // Parsed to DateTime
  final num nilai;
  final num nilaiSd;
  final String? catatan;
  final DateTime? createdAt; // Parsed to DateTime
  final JenisTabunganMutasiInfo jenisTabungan;
  final MasterAnggotaMutasiInfo masterAnggota;

  MutasiTabunganItem({
    required this.tTabunganJurnalId,
    this.tglTransaksi,
    required this.nilai,
    required this.nilaiSd,
    this.catatan,
    this.createdAt,
    required this.jenisTabungan,
    required this.masterAnggota,
  });

  factory MutasiTabunganItem.fromJson(Map<String, dynamic> json) =>
      MutasiTabunganItem(
        tTabunganJurnalId: json["t_tabungan_jurnal_id"] as String? ?? '',
        tglTransaksi:
            json["tgl_transaksi"] == null
                ? null
                : DateTime.tryParse(json["tgl_transaksi"] as String),
        nilai: (json["nilai"] as num?) ?? 0,
        nilaiSd: (json["nilai_sd"] as num?) ?? 0,
        catatan: json["catatan"] as String?,
        createdAt:
            json["created_at"] == null
                ? null
                : DateTime.tryParse(json["created_at"] as String),
        jenisTabungan: JenisTabunganMutasiInfo.fromJson(
          json["jenis_tabungan"] as Map<String, dynamic>? ?? {},
        ),
        masterAnggota: MasterAnggotaMutasiInfo.fromJson(
          json["master_anggota"] as Map<String, dynamic>? ?? {},
        ),
      );

  Map<String, dynamic> toJson() => {
    "t_tabungan_jurnal_id": tTabunganJurnalId,
    "tgl_transaksi": tglTransaksi?.toIso8601String(),
    "nilai": nilai,
    "nilai_sd": nilaiSd,
    "catatan": catatan,
    "created_at": createdAt?.toIso8601String(),
    "jenis_tabungan": jenisTabungan.toJson(),
    "master_anggota": masterAnggota.toJson(),
  };
}

// --- Nested Object for 'jenis_tabungan' ---
class JenisTabunganMutasiInfo {
  final int pJenisTabunganId;
  final String nama;

  JenisTabunganMutasiInfo({required this.pJenisTabunganId, required this.nama});

  factory JenisTabunganMutasiInfo.fromJson(Map<String, dynamic> json) =>
      JenisTabunganMutasiInfo(
        pJenisTabunganId: json["p_jenis_tabungan_id"] as int? ?? 0,
        nama: json["nama"] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    "p_jenis_tabungan_id": pJenisTabunganId,
    "nama": nama,
  };
}

// --- Nested Object for 'master_anggota' ---
class MasterAnggotaMutasiInfo {
  final int pAnggotaId;
  final String nomorAnggota;
  final String nama;
  final String nik;

  MasterAnggotaMutasiInfo({
    required this.pAnggotaId,
    required this.nomorAnggota,
    required this.nama,
    required this.nik,
  });

  factory MasterAnggotaMutasiInfo.fromJson(Map<String, dynamic> json) =>
      MasterAnggotaMutasiInfo(
        pAnggotaId: json["p_anggota_id"] as int? ?? 0,
        nomorAnggota: json["nomor_anggota"] as String? ?? '',
        nama: json["nama"] as String? ?? '',
        nik: json["nik"] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    "p_anggota_id": pAnggotaId,
    "nomor_anggota": nomorAnggota,
    "nama": nama,
    "nik": nik,
  };
}

// --- Item for 'links' array in pagination ---
class LinkItem {
  final String? url;
  final String label;
  final bool active;

  LinkItem({this.url, required this.label, required this.active});

  factory LinkItem.fromJson(Map<String, dynamic> json) => LinkItem(
    url: json["url"] as String?,
    label: json["label"] as String? ?? '',
    active: json["active"] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    "url": url,
    "label": label,
    "active": active,
  };
}
