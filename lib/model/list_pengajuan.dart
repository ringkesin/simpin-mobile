import 'package:meta/meta.dart'; // Untuk anotasi required (opsional tapi bagus)
import 'dart:convert'; // Untuk jsonDecode jika diperlukan

//-------------------------------------
// Root Response Model
//-------------------------------------
class ListPengajuanResponse {
  final bool success;
  final PaginationData? data; // Bisa null jika success = false
  final String? message;

  ListPengajuanResponse({required this.success, this.data, this.message});

  factory ListPengajuanResponse.fromJson(Map<String, dynamic> json) =>
      ListPengajuanResponse(
        success: json["success"] ?? false, // Default ke false jika null
        // Parse 'data' hanya jika success=true dan data tidak null
        data:
            json["success"] == true && json["data"] != null
                ? PaginationData.fromJson(json["data"])
                : null,
        message: json["message"],
      );

  // Opsional: toJson jika perlu mengirim balik
  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data?.toJson(),
    "message": message,
  };
}

//-------------------------------------
// Pagination Data Model
//-------------------------------------
class PaginationData {
  final int currentPage;
  final List<PengajuanItem> data; // List item pengajuan
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
  final int total;

  PaginationData({
    required this.currentPage,
    required this.data,
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
    required this.total,
  });

  factory PaginationData.fromJson(Map<String, dynamic> json) => PaginationData(
    currentPage: json["current_page"] ?? 1,
    // Parse list 'data' di dalam pagination data
    data:
        json["data"] == null
            ? []
            : List<PengajuanItem>.from(
              json["data"].map((x) => PengajuanItem.fromJson(x)),
            ),
    firstPageUrl: json["first_page_url"],
    from: json["from"],
    lastPage: json["last_page"] ?? 1,
    lastPageUrl: json["last_page_url"],
    // Parse list 'links'
    links:
        json["links"] == null
            ? []
            : List<LinkItem>.from(
              json["links"].map((x) => LinkItem.fromJson(x)),
            ),
    nextPageUrl: json["next_page_url"],
    path: json["path"] ?? '',
    perPage: json["per_page"] ?? 10,
    prevPageUrl: json["prev_page_url"],
    to: json["to"],
    total: json["total"] ?? 0,
  );

  // Opsional: toJson
  Map<String, dynamic> toJson() => {
    "current_page": currentPage,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
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
    "total": total,
  };
}

//-------------------------------------
// Pengajuan Item Model (Satu item dalam list 'data')
//-------------------------------------
class PengajuanItem {
  final String tTabunganPengambilanId;
  final DateTime? tglPengajuan; // Parse ke DateTime?
  final num jumlahDiambil;
  final num? jumlahDisetujui; // Nullable
  final String rekeningNo;
  final String rekeningBank;
  final String statusPengambilan;
  final DateTime? tglPencairan; // Nullable, Parse ke DateTime?
  final String? catatanUser; // Nullable
  final String? catatanApprover; // Nullable
  final DateTime? createdAt; // Parse ke DateTime?
  final DateTime? updatedAt; // Parse ke DateTime?
  final JenisTabunganInfo? jenisTabungan; // Bisa null jika data tidak konsisten
  final MasterAnggotaInfo? masterAnggota; // Bisa null jika data tidak konsisten

  PengajuanItem({
    required this.tTabunganPengambilanId,
    this.tglPengajuan,
    required this.jumlahDiambil,
    this.jumlahDisetujui,
    required this.rekeningNo,
    required this.rekeningBank,
    required this.statusPengambilan,
    this.tglPencairan,
    this.catatanUser,
    this.catatanApprover,
    this.createdAt,
    this.updatedAt,
    this.jenisTabungan,
    this.masterAnggota,
  });

  // Helper untuk parsing tanggal yang aman
  static DateTime? _parseDateTime(String? dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print("Error parsing date: $dateString -> $e");
      return null; // Kembalikan null jika parsing gagal
    }
  }

  factory PengajuanItem.fromJson(Map<String, dynamic> json) => PengajuanItem(
    tTabunganPengambilanId: json["t_tabungan_pengambilan_id"] ?? '',
    tglPengajuan: _parseDateTime(json["tgl_pengajuan"]),
    jumlahDiambil: json["jumlah_diambil"] ?? 0,
    jumlahDisetujui: json["jumlah_disetujui"], // Tetap num?
    rekeningNo: json["rekening_no"] ?? '',
    rekeningBank: json["rekening_bank"] ?? '',
    statusPengambilan: json["status_pengambilan"] ?? 'UNKNOWN',
    tglPencairan: _parseDateTime(json["tgl_pencairan"]),
    catatanUser: json["catatan_user"],
    catatanApprover: json["catatan_approver"],
    createdAt: _parseDateTime(json["created_at"]),
    updatedAt: _parseDateTime(json["updated_at"]),
    // Parse nested objects dengan aman
    jenisTabungan:
        json["jenis_tabungan"] == null
            ? null
            : JenisTabunganInfo.fromJson(json["jenis_tabungan"]),
    masterAnggota:
        json["master_anggota"] == null
            ? null
            : MasterAnggotaInfo.fromJson(json["master_anggota"]),
  );

  // Opsional: toJson
  Map<String, dynamic> toJson() => {
    "t_tabungan_pengambilan_id": tTabunganPengambilanId,
    "tgl_pengajuan": tglPengajuan?.toIso8601String(),
    "jumlah_diambil": jumlahDiambil,
    "jumlah_disetujui": jumlahDisetujui,
    "rekening_no": rekeningNo,
    "rekening_bank": rekeningBank,
    "status_pengambilan": statusPengambilan,
    "tgl_pencairan": tglPencairan?.toIso8601String(),
    "catatan_user": catatanUser,
    "catatan_approver": catatanApprover,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "jenis_tabungan": jenisTabungan?.toJson(),
    "master_anggota": masterAnggota?.toJson(),
  };
}

//-------------------------------------
// Nested Jenis Tabungan Model
//-------------------------------------
class JenisTabunganInfo {
  final int pJenisTabunganId;
  final String nama;

  JenisTabunganInfo({required this.pJenisTabunganId, required this.nama});

  factory JenisTabunganInfo.fromJson(Map<String, dynamic> json) =>
      JenisTabunganInfo(
        pJenisTabunganId: json["p_jenis_tabungan_id"] ?? 0,
        nama: json["nama"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "p_jenis_tabungan_id": pJenisTabunganId,
    "nama": nama,
  };
}

//-------------------------------------
// Nested Master Anggota Model
//-------------------------------------
class MasterAnggotaInfo {
  final int pAnggotaId;
  final String nomorAnggota;
  final String nama;
  final String nik;

  MasterAnggotaInfo({
    required this.pAnggotaId,
    required this.nomorAnggota,
    required this.nama,
    required this.nik,
  });

  factory MasterAnggotaInfo.fromJson(Map<String, dynamic> json) =>
      MasterAnggotaInfo(
        pAnggotaId: json["p_anggota_id"] ?? 0,
        nomorAnggota: json["nomor_anggota"] ?? '',
        nama: json["nama"] ?? '',
        nik: json["nik"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "p_anggota_id": pAnggotaId,
    "nomor_anggota": nomorAnggota,
    "nama": nama,
    "nik": nik,
  };
}

//-------------------------------------
// Link Item Model (untuk pagination links)
//-------------------------------------
class LinkItem {
  final String? url; // Nullable
  final String label;
  final bool active;

  LinkItem({this.url, required this.label, required this.active});

  factory LinkItem.fromJson(Map<String, dynamic> json) => LinkItem(
    url: json["url"],
    label: json["label"] ?? '',
    active: json["active"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "url": url,
    "label": label,
    "active": active,
  };
}
