class PengajuanPenyertaanResponse {
  final bool success;
  final PengajuanData data;
  final String message;

  PengajuanPenyertaanResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory PengajuanPenyertaanResponse.fromJson(Map<String, dynamic> json) =>
      PengajuanPenyertaanResponse(
        success: json["success"],
        data: PengajuanData.fromJson(json["data"]),
        message: json["message"],
      );
}

class PengajuanData {
  final PengajuanPenyertaanDetail pengajuanPenyertaan;

  PengajuanData({required this.pengajuanPenyertaan});

  factory PengajuanData.fromJson(Map<String, dynamic> json) => PengajuanData(
    pengajuanPenyertaan: PengajuanPenyertaanDetail.fromJson(
      json["pengajuan_penyertaan"],
    ),
  );
}

class PengajuanPenyertaanDetail {
  final int pAnggotaId;
  final int pJenisTabunganId;
  final DateTime penyertaanDate;
  final int jumlah;
  final String statusPenyertaan;
  final String? catatanUser;
  final String tTabunganPenyertaanId;

  PengajuanPenyertaanDetail({
    required this.pAnggotaId,
    required this.pJenisTabunganId,
    required this.penyertaanDate,
    required this.jumlah,
    required this.statusPenyertaan,
    this.catatanUser,
    required this.tTabunganPenyertaanId,
  });

  factory PengajuanPenyertaanDetail.fromJson(Map<String, dynamic> json) =>
      PengajuanPenyertaanDetail(
        pAnggotaId: json["p_anggota_id"],
        pJenisTabunganId: json["p_jenis_tabungan_id"],
        penyertaanDate: DateTime.parse(json["penyertaan_date"]),
        jumlah: json["jumlah"],
        statusPenyertaan: json["status_penyertaan"],
        catatanUser: json["catatan_user"],
        tTabunganPenyertaanId: json["t_tabungan_penyertaan_id"],
      );
}
