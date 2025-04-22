import 'package:intl/intl.dart';

class InfoSHU {
  bool success;
  ShuData data;
  String message;

  InfoSHU({required this.success, required this.data, required this.message});

  factory InfoSHU.fromJson(Map<String, dynamic> json) {
    return InfoSHU(
      success: json['success'],
      data: ShuData.fromJson(json['data']),
      message: json['message'],
    );
  }
}

class ShuData {
  int pAnggotaId;
  String tahun;
  num shuDiterima;
  num shuDibagi;
  num shuDitabung;
  num shuTahunLalu;

  ShuData({
    required this.pAnggotaId,
    required this.tahun,
    required this.shuDiterima,
    required this.shuDibagi,
    required this.shuDitabung,
    required this.shuTahunLalu,
  });

  factory ShuData.fromJson(Map<String, dynamic> json) {
    return ShuData(
      pAnggotaId: json['p_anggota_id'],
      tahun: json['tahun'],
      shuDiterima: json['shu_diterima'],
      shuDibagi: json['shu_dibagi'],
      shuDitabung: json['shu_ditabung'],
      shuTahunLalu: json['shu_tahun_lalu'],
    );
  }

  // Fungsi untuk memformat angka ke mata uang Rupiah.
  String formatRupiah(num value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }
}
