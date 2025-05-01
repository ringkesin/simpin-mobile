// Lokasi file: lib/model/tabungan_tahunan.dart (atau sesuaikan path Anda)

import 'package:flutter/foundation.dart'; // for listEquals

class TabunganTahunanResponse {
  final bool success;
  final String? message;
  final TabunganTahunanData? data;

  TabunganTahunanResponse({required this.success, this.message, this.data});

  factory TabunganTahunanResponse.fromJson(Map<String, dynamic> json) {
    return TabunganTahunanResponse(
      success: json['success'] ?? false,
      message: json['message'] as String?,
      // Lakukan pengecekan tipe sebelum parsing data
      data:
          json['data'] != null && json['data'] is Map<String, dynamic>
              ? TabunganTahunanData.fromJson(json['data'])
              : null,
    );
  }

  // Optional: For debugging or comparing objects
  @override
  String toString() {
    return 'TabunganTahunanResponse(success: $success, message: $message, data: $data)';
  }
}

class TabunganTahunanData {
  final int tahun;
  final num totalSaldoSd; // Tambahkan field ini sesuai JSON
  final List<SaldoItemTahunan> detail; // Nama field sesuai JSON key 'detail'

  TabunganTahunanData({
    required this.tahun,
    required this.totalSaldoSd,
    required this.detail,
  });

  factory TabunganTahunanData.fromJson(Map<String, dynamic> json) {
    // Parsing list 'detail' dari JSON
    var detailListFromJson = json['detail'] as List?;
    List<SaldoItemTahunan> detailList =
        detailListFromJson
            ?.map(
              (item) => SaldoItemTahunan.fromJson(item as Map<String, dynamic>),
            )
            .toList() ??
        []; // Default list kosong jika null

    return TabunganTahunanData(
      tahun:
          json['tahun'] as int? ??
          DateTime.now().year, // Default ke tahun ini jika null
      totalSaldoSd: json['total_saldo_sd'] as num? ?? 0, // Ambil total saldo
      detail: detailList, // Gunakan list yang sudah diparsing
    );
  }

  // Optional: For debugging or comparing objects
  @override
  String toString() {
    return 'TabunganTahunanData(tahun: $tahun, totalSaldoSd: $totalSaldoSd, detail: $detail)';
  }

  // Optional: Override equality operator if needed for state management comparisons
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TabunganTahunanData &&
        other.tahun == tahun &&
        other.totalSaldoSd == totalSaldoSd &&
        listEquals(other.detail, detail); // Use listEquals for comparing lists
  }

  @override
  int get hashCode => tahun.hashCode ^ totalSaldoSd.hashCode ^ detail.hashCode;
}

class SaldoItemTahunan {
  final int pJenisTabunganId;
  final String namaJenisTabungan; // Gunakan nama deskriptif untuk field Dart
  final num saldoAkhir; // Gunakan nama konsisten dengan logika sebelumnya

  SaldoItemTahunan({
    required this.pJenisTabunganId,
    required this.namaJenisTabungan,
    required this.saldoAkhir,
  });

  factory SaldoItemTahunan.fromJson(Map<String, dynamic> json) {
    return SaldoItemTahunan(
      // Mapping dari key JSON ke field Dart
      pJenisTabunganId:
          json['p_jenis_tabungan_id'] as int? ?? 0, // Ambil dari JSON
      namaJenisTabungan:
          json['jenis_tabungan'] as String? ??
          'Tidak Diketahui', // Ambil dari JSON
      saldoAkhir: json['saldo_sd_bulan_ini'] as num? ?? 0, // Ambil dari JSON
    );
  }

  // Optional: For debugging or comparing objects
  @override
  String toString() {
    return 'SaldoItemTahunan(pJenisTabunganId: $pJenisTabunganId, namaJenisTabungan: $namaJenisTabungan, saldoAkhir: $saldoAkhir)';
  }

  // Optional: Override equality operator if needed
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SaldoItemTahunan &&
        other.pJenisTabunganId == pJenisTabunganId &&
        other.namaJenisTabungan == namaJenisTabungan &&
        other.saldoAkhir == saldoAkhir;
  }

  @override
  int get hashCode =>
      pJenisTabunganId.hashCode ^
      namaJenisTabungan.hashCode ^
      saldoAkhir.hashCode;
}
