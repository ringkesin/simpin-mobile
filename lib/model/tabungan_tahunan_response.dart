// models/tabungan_tahunan_response.dart

import 'dart:convert';

// Fungsi helper (opsional)
TabunganTahunanResponse tabunganTahunanResponseFromJson(String str) =>
    TabunganTahunanResponse.fromJson(json.decode(str));
String tabunganTahunanResponseToJson(TabunganTahunanResponse data) =>
    json.encode(data.toJson());

// --- Model Utama ---
class TabunganTahunanResponse {
  final bool success;
  final TabunganTahunanData? data;
  final String? message;

  TabunganTahunanResponse({required this.success, this.data, this.message});

  factory TabunganTahunanResponse.fromJson(Map<String, dynamic> json) =>
      TabunganTahunanResponse(
        success: json["success"] ?? false,
        data:
            json["data"] == null || !(json["data"] is Map<String, dynamic>)
                ? null
                : TabunganTahunanData.fromJson(json["data"]),
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data?.toJson(),
    "message": message,
  };
}

// --- Model untuk Object 'data' ---
class TabunganTahunanData {
  final int? tahun;
  final num? totalSaldoSd; // Saldo s/d akhir tahun
  final DetailSaldoTahunan? detail; // Objek detail saldo

  TabunganTahunanData({this.tahun, this.totalSaldoSd, this.detail});

  factory TabunganTahunanData.fromJson(Map<String, dynamic> json) =>
      TabunganTahunanData(
        tahun: (json["tahun"] as int?) ?? 0,
        totalSaldoSd: (json["total_saldo_sd"] as num?) ?? 0,
        detail:
            json["detail"] == null || !(json["detail"] is Map<String, dynamic>)
                ? null // Atau DetailSaldoTahunan() jika ingin default kosong
                : DetailSaldoTahunan.fromJson(json["detail"]),
      );

  Map<String, dynamic> toJson() => {
    "tahun": tahun,
    "total_saldo_sd": totalSaldoSd,
    "detail": detail?.toJson(),
  };
}

// --- Model untuk Object 'detail' (Saldo s/d Akhir Tahun per Jenis) ---
class DetailSaldoTahunan {
  final num? saldoSdSimpananPokok;
  final num? saldoSdSimpananWajib;
  final num? saldoSdTabunganSukarela;
  final num? saldoSdTabunganIndir;
  final num? saldoSdKompensasiMasaKerja;

  DetailSaldoTahunan({
    this.saldoSdSimpananPokok = 0,
    this.saldoSdSimpananWajib = 0,
    this.saldoSdTabunganSukarela = 0,
    this.saldoSdTabunganIndir = 0,
    this.saldoSdKompensasiMasaKerja = 0,
  });

  factory DetailSaldoTahunan.fromJson(Map<String, dynamic> json) =>
      DetailSaldoTahunan(
        saldoSdSimpananPokok: (json["saldo_sd_simpanan_pokok"] as num?) ?? 0,
        saldoSdSimpananWajib: (json["saldo_sd_simpanan_wajib"] as num?) ?? 0,
        saldoSdTabunganSukarela:
            (json["saldo_sd_tabungan_sukarela"] as num?) ?? 0,
        saldoSdTabunganIndir: (json["saldo_sd_tabungan_indir"] as num?) ?? 0,
        saldoSdKompensasiMasaKerja:
            (json["saldo_sd_kompensasi_masa_kerja"] as num?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "saldo_sd_simpanan_pokok": saldoSdSimpananPokok,
    "saldo_sd_simpanan_wajib": saldoSdSimpananWajib,
    "saldo_sd_tabungan_sukarela": saldoSdTabunganSukarela,
    "saldo_sd_tabungan_indir": saldoSdTabunganIndir,
    "saldo_sd_kompensasi_masa_kerja": saldoSdKompensasiMasaKerja,
  };
}
