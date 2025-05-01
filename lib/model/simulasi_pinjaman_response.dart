// models/simulasi_pinjaman_response.dart

import 'dart:convert';

SimulasiPinjamanResponse simulasiPinjamanResponseFromJson(String str) =>
    SimulasiPinjamanResponse.fromJson(json.decode(str));

String simulasiPinjamanResponseToJson(SimulasiPinjamanResponse data) =>
    json.encode(data.toJson());

class SimulasiPinjamanResponse {
  final bool success;
  final SimulasiResult? data; // Jadikan nullable
  final String? message;

  SimulasiPinjamanResponse({required this.success, this.data, this.message});

  factory SimulasiPinjamanResponse.fromJson(Map<String, dynamic> json) =>
      SimulasiPinjamanResponse(
        success: json["success"] ?? false,
        // Handle jika data null atau bukan map
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

class SimulasiResult {
  final int? tahun;
  final int? tenor;
  final double? margin; // Gunakan double untuk desimal
  final double? angsuran; // Gunakan double untuk desimal

  SimulasiResult({
    this.tahun = 0,
    this.tenor = 0,
    this.margin = 0.0,
    this.angsuran = 0.0,
  });

  factory SimulasiResult.fromJson(Map<String, dynamic> json) => SimulasiResult(
    tahun: (json["tahun"] as int?) ?? 0,
    tenor: (json["tenor"] as int?) ?? 0,
    // Gunakan num?.toDouble() untuk handle int atau double dari JSON
    margin: (json["margin"] as num?)?.toDouble() ?? 0.0,
    angsuran: (json["angsuran"] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "tahun": tahun,
    "tenor": tenor,
    "margin": margin,
    "angsuran": angsuran,
  };
}
