class PengajuanPencairanDetail {
  final int pAnggotaId;
  final int pJenisTabunganId;
  final String
  tglPengajuan; // Simpan sebagai String, parse ke DateTime jika perlu di UI
  final num jumlahDiambil; // Bisa int atau double, gunakan num
  final String rekeningNo;
  final String rekeningBank;
  final String statusPengambilan;
  final String? catatanUser; // Nullable sesuai response
  final dynamic createdBy; // Bisa int/String?
  final dynamic updatedBy; // Bisa int/String?
  final String id; // t_tabungan_pengambilan_id
  final String updatedAt; // Simpan sebagai String
  final String createdAt; // Simpan sebagai String

  PengajuanPencairanDetail({
    required this.pAnggotaId,
    required this.pJenisTabunganId,
    required this.tglPengajuan,
    required this.jumlahDiambil,
    required this.rekeningNo,
    required this.rekeningBank,
    required this.statusPengambilan,
    this.catatanUser,
    this.createdBy,
    this.updatedBy,
    required this.id,
    required this.updatedAt,
    required this.createdAt,
  });

  factory PengajuanPencairanDetail.fromJson(Map<String, dynamic> json) {
    return PengajuanPencairanDetail(
      pAnggotaId: json['p_anggota_id'] as int? ?? 0,
      pJenisTabunganId: json['p_jenis_tabungan_id'] as int? ?? 0,
      tglPengajuan: json['tgl_pengajuan'] as String? ?? '',
      jumlahDiambil: json['jumlah_diambil'] as num? ?? 0,
      rekeningNo: json['rekening_no'] as String? ?? '',
      rekeningBank: json['rekening_bank'] as String? ?? '',
      statusPengambilan: json['status_pengambilan'] as String? ?? 'UNKNOWN',
      catatanUser: json['catatan_user'] as String?, // Bisa null
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      id: json['t_tabungan_pengambilan_id'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'p_anggota_id': pAnggotaId,
      'p_jenis_tabungan_id': pJenisTabunganId,
      'tgl_pengajuan': tglPengajuan,
      'jumlah_diambil': jumlahDiambil,
      'rekening_no': rekeningNo,
      'rekening_bank': rekeningBank,
      'status_pengambilan': statusPengambilan,
      'catatan_user': catatanUser,
      'created_by': createdBy,
      'updated_by': updatedBy,
      't_tabungan_pengambilan_id': id,
      'updated_at': updatedAt,
      'created_at': createdAt,
    };
  }
}

// Model untuk response API level teratas
class PengajuanPencairanResponse {
  final bool success;
  // 'data' berisi object 'pengajuan_pencairan', yang diwakili oleh PengajuanPencairanDetail
  final PengajuanPencairanDetail? data; // Nullable jika bisa tidak ada
  final String message;

  PengajuanPencairanResponse({
    required this.success,
    this.data,
    required this.message,
  });

  factory PengajuanPencairanResponse.fromJson(Map<String, dynamic> json) {
    PengajuanPencairanDetail? detailData;
    // Cek apakah 'data' ada dan berisi 'pengajuan_pencairan'
    if (json['data'] != null &&
        json['data'] is Map<String, dynamic> &&
        json['data']['pengajuan_pencairan'] != null &&
        json['data']['pengajuan_pencairan'] is Map<String, dynamic>) {
      detailData = PengajuanPencairanDetail.fromJson(
        json['data']['pengajuan_pencairan'] as Map<String, dynamic>,
      );
    }

    return PengajuanPencairanResponse(
      success: json['success'] as bool? ?? false,
      data: detailData,
      message: json['message'] as String? ?? '',
    );
  }
}
