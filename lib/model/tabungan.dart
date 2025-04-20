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
      pAnggotaId: json['p_anggota_id'],
      bulan: json['bulan'],
      tahun: json['tahun'],
      totalTabungan: json['total_tabungan'],
      simpananPokok: json['simpanan_pokok'],
      simpananWajib: json['simpanan_wajib'],
      tabunganSukarela: json['tabungan_sukarela'],
      tabunganIndir: json['tabungan_indir'],
      kompensasiMasaKerja: json['kompensasi_masa_kerja'],
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
