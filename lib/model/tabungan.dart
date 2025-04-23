import 'package:intl/intl.dart';

class TabunganData {
  bool success;
  Data data;
  String message;

  TabunganData({
    required this.success,
    required this.data,
    required this.message,
  });

  factory TabunganData.fromJson(Map<String, dynamic> json) {
    return TabunganData(
      success: json['success'],
      data: Data.fromJson(json['data']),
      message: json['message'],
    );
  }
}

class Data {
  int pAnggotaId;
  String bulan;
  String tahun;
  num totalTabungan;
  num simpananPokok;
  num simpananWajib;
  num tabunganSukarela;
  num tabunganIndir;
  num kompensasiMasaKerja;

  Data({
    required this.pAnggotaId,
    required this.bulan,
    required this.tahun,
    required this.totalTabungan,
    required this.simpananPokok,
    required this.simpananWajib,
    required this.tabunganSukarela,
    required this.tabunganIndir,
    required this.kompensasiMasaKerja,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      // Asumsikan p_anggota_id dan field nominal memang angka (num/int)
      pAnggotaId: (json['p_anggota_id'] as int?) ?? 0,
      // Konversi bulan dan tahun ke String menggunakan .toString() atau interpolasi
      bulan: (json['bulan'] as dynamic)?.toString() ?? '', // <-- Perbaikan
      tahun: (json['tahun'] as dynamic)?.toString() ?? '', // <-- Perbaikan
      // Untuk field num, pastikan di-cast ke num dan beri default jika perlu
      totalTabungan: (json['total_tabungan'] as num?) ?? 0,
      simpananPokok: (json['simpanan_pokok'] as num?) ?? 0,
      simpananWajib: (json['simpanan_wajib'] as num?) ?? 0,
      tabunganSukarela: (json['tabungan_sukarela'] as num?) ?? 0,
      tabunganIndir: (json['tabungan_indir'] as num?) ?? 0,
      kompensasiMasaKerja: (json['kompensasi_masa_kerja'] as num?) ?? 0,
    );
  }

  // Fungsi untuk memformat angka ke mata uang Rupiah.
  String formatRupiah() {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(totalTabungan);
  }
}
