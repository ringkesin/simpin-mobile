// models/simulasi_pinjaman_response.dart

import 'dart:convert';

// Fungsi helper (dikembalikan seperti semula)
SimulasiPinjamanResponse simulasiPinjamanResponseFromJson(String str) =>
    SimulasiPinjamanResponse.fromJson(json.decode(str));

String simulasiPinjamanResponseToJson(SimulasiPinjamanResponse data) =>
    json.encode(data.toJson());

// Class SimulasiPinjamanResponse (dikembalikan seperti semula)
class SimulasiPinjamanResponse {
  final bool success;
  final SimulasiResult? data;
  final String? message;

  SimulasiPinjamanResponse({required this.success, this.data, this.message});

  factory SimulasiPinjamanResponse.fromJson(Map<String, dynamic> json) =>
      SimulasiPinjamanResponse(
        success: json["success"] ?? false,
        data:
            json["data"] == null || json["data"] is! Map<String, dynamic>
                ? null
                : SimulasiResult.fromJson(json["data"]),
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data?.toJson(),
    "message": message,
  };
}

// Class SimulasiResult (dimodifikasi dengan benar)
class SimulasiResult {
  final int? tahun;
  final int? tenor;
  final double? margin;
  final double? angsuran;
  final double? biayaAdmin;
  final int? biayaAdminRp;
  // Variabel baru dengan nama yang benar (tidak diubah)
  final double? total_pengembalian;

  SimulasiResult({
    this.tahun = 0,
    this.tenor = 0,
    this.margin = 0.0,
    this.angsuran = 0.0,
    this.biayaAdmin,
    this.biayaAdminRp,
    this.total_pengembalian, // Menggunakan nama variabel yang benar
  });

  factory SimulasiResult.fromJson(Map<String, dynamic> json) => SimulasiResult(
    tahun: (json["tahun"] as int?) ?? 0,
    tenor: (json["tenor"] as int?) ?? 0,
    margin: (json["margin"] as num?)?.toDouble() ?? 0.0,
    angsuran: (json["angsuran"] as num?)?.toDouble() ?? 0.0,
    biayaAdmin: (json["biaya_admin"] as num?)?.toDouble(),
    biayaAdminRp: json["biaya_admin_rp"] as int?,
    total_pengembalian: (json["total_pengembalian"] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "tahun": tahun,
    "tenor": tenor,
    "margin": margin,
    "angsuran": angsuran,
    "biaya_admin": biayaAdmin,
    "biaya_admin_rp": biayaAdminRp,
    "total_pengembalian": total_pengembalian,
  };
}
