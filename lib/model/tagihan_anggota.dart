// model/tagihan_anggota_response.dart

class TagihanAnggotaResponse {
  final bool success;
  final TagihanData?
  data; // Tetap nullable jika 'data' bisa tidak ada sama sekali
  final String message;

  TagihanAnggotaResponse({
    required this.success,
    this.data,
    required this.message,
  });

  factory TagihanAnggotaResponse.fromJson(Map<String, dynamic> json) {
    return TagihanAnggotaResponse(
      success: json['success'] as bool? ?? false,
      data:
          json['data'] != null
              ? TagihanData.fromJson(json['data'] as Map<String, dynamic>)
              : null,
      message: json['message'] as String? ?? "",
    );
  }
}

class TagihanData {
  final num totalTagihan;
  final List<TagihanItem> tagihan;

  TagihanData({required this.totalTagihan, required this.tagihan});

  factory TagihanData.fromJson(Map<String, dynamic> json) {
    List<TagihanItem> itemsList = [];
    if (json['tagihan'] != null && json['tagihan'] is List) {
      itemsList =
          (json['tagihan'] as List)
              .map((i) => TagihanItem.fromJson(i as Map<String, dynamic>))
              .toList();
    }

    return TagihanData(
      totalTagihan: json['total_tagihan'] as num? ?? 0,
      tagihan: itemsList,
    );
  }
}

class TagihanItem {
  final String tTagihanId;
  final int pAnggotaId;
  final int tPinjamanId;
  final String uraian;
  final num jumlahTagihan;
  final String remarks;
  final int bulan;
  final int tahun;
  final String tglJatuhTempo;
  final int pStatusPembayaranId;
  final String paidAt;
  final num jumlahPembayaran;
  final int pMetodePembayaranId;
  final PinjamanAnggota? pinjamanAnggota; // Tetap nullable
  final StatusPembayaran? statusPembayaran; // Tetap nullable
  final MetodePembayaran? metodePembayaran; // Tetap nullable

  TagihanItem({
    required this.tTagihanId,
    required this.pAnggotaId,
    required this.tPinjamanId,
    required this.uraian,
    required this.jumlahTagihan,
    required this.remarks,
    required this.bulan,
    required this.tahun,
    required this.tglJatuhTempo,
    required this.pStatusPembayaranId,
    required this.paidAt,
    required this.jumlahPembayaran,
    required this.pMetodePembayaranId,
    this.pinjamanAnggota,
    this.statusPembayaran,
    this.metodePembayaran,
  });

  factory TagihanItem.fromJson(Map<String, dynamic> json) {
    return TagihanItem(
      tTagihanId: json['t_tagihan_id'] as String? ?? "",
      pAnggotaId: json['p_anggota_id'] as int? ?? 0,
      tPinjamanId: json['t_pinjaman_id'] as int? ?? 0,
      uraian: json['uraian'] as String? ?? "",
      jumlahTagihan: json['jumlah_tagihan'] as num? ?? 0,
      remarks: json['remarks'] as String? ?? "",
      bulan: json['bulan'] as int? ?? 0,
      tahun: json['tahun'] as int? ?? 0,
      tglJatuhTempo: json['tgl_jatuh_tempo'] as String? ?? "",
      pStatusPembayaranId: json['p_status_pembayaran_id'] as int? ?? 0,
      paidAt: json['paid_at'] as String? ?? "",
      jumlahPembayaran: json['jumlah_pembayaran'] as num? ?? 0,
      pMetodePembayaranId: json['p_metode_pembayaran_id'] as int? ?? 0,
      pinjamanAnggota:
          json['pinjaman_anggota'] != null
              ? PinjamanAnggota.fromJson(
                json['pinjaman_anggota'] as Map<String, dynamic>,
              )
              : null,
      statusPembayaran:
          json['status_pembayaran'] != null
              ? StatusPembayaran.fromJson(
                json['status_pembayaran'] as Map<String, dynamic>,
              )
              : null,
      metodePembayaran:
          json['metode_pembayaran'] != null
              ? MetodePembayaran.fromJson(
                json['metode_pembayaran'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

class PinjamanAnggota {
  final int tPinjamanId;
  final int pAnggotaId;
  final int pJenisPinjamanId;
  final String nomorPinjaman;
  final List<String> pPinjamanKeperluanIds;
  final String jenisBarang;
  final String merkType;
  final int tenor;
  final num biayaAdmin;
  final num raJumlahPinjaman;
  final num riJumlahPinjaman;
  final String jaminan;
  final String jaminanKeterangan;
  final num jaminanPerkiraanNilai;
  final String noRekening;
  final String bank;
  final String tglPencairan;
  final String tglPelunasan;
  final String docSlipGaji;
  final int pStatusPengajuanId;
  final String remarks;
  final String createdAt;
  final String updatedAt;
  final String margin;

  PinjamanAnggota({
    required this.tPinjamanId,
    required this.pAnggotaId,
    required this.pJenisPinjamanId,
    required this.nomorPinjaman,
    required this.pPinjamanKeperluanIds,
    required this.jenisBarang,
    required this.merkType,
    required this.tenor,
    required this.biayaAdmin,
    required this.raJumlahPinjaman,
    required this.riJumlahPinjaman,
    required this.jaminan,
    required this.jaminanKeterangan,
    required this.jaminanPerkiraanNilai,
    required this.noRekening,
    required this.bank,
    required this.tglPencairan,
    required this.tglPelunasan,
    required this.docSlipGaji,
    required this.pStatusPengajuanId,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
    required this.margin,
  });

  factory PinjamanAnggota.fromJson(Map<String, dynamic> json) {
    List<String> keperluanIds = [];
    if (json['p_pinjaman_keperluan_ids'] != null &&
        json['p_pinjaman_keperluan_ids'] is List) {
      keperluanIds =
          (json['p_pinjaman_keperluan_ids'] as List)
              .map(
                (e) => e.toString(),
              ) // Memastikan setiap elemen adalah String
              .toList();
    }

    return PinjamanAnggota(
      tPinjamanId: json['t_pinjaman_id'] as int? ?? 0,
      pAnggotaId: json['p_anggota_id'] as int? ?? 0,
      pJenisPinjamanId: json['p_jenis_pinjaman_id'] as int? ?? 0,
      nomorPinjaman: json['nomor_pinjaman'] as String? ?? "",
      pPinjamanKeperluanIds: keperluanIds,
      jenisBarang: json['jenis_barang'] as String? ?? "",
      merkType: json['merk_type'] as String? ?? "",
      tenor: json['tenor'] as int? ?? 0,
      biayaAdmin:
          json['biaya_admin'] as num? ??
          0.0, // Default 0.0 jika num adalah double
      raJumlahPinjaman: json['ra_jumlah_pinjaman'] as num? ?? 0,
      riJumlahPinjaman: json['ri_jumlah_pinjaman'] as num? ?? 0,
      jaminan: json['jaminan'] as String? ?? "",
      jaminanKeterangan: json['jaminan_keterangan'] as String? ?? "",
      jaminanPerkiraanNilai: json['jaminan_perkiraan_nilai'] as num? ?? 0,
      noRekening: json['no_rekening'] as String? ?? "",
      bank: json['bank'] as String? ?? "",
      tglPencairan: json['tgl_pencairan'] as String? ?? "",
      tglPelunasan: json['tgl_pelunasan'] as String? ?? "",
      docSlipGaji: json['doc_slip_gaji'] as String? ?? "",
      pStatusPengajuanId: json['p_status_pengajuan_id'] as int? ?? 0,
      remarks: json['remarks'] as String? ?? "",
      createdAt: json['created_at'] as String? ?? "",
      updatedAt: json['updated_at'] as String? ?? "",
      margin: json['margin'] as String? ?? "0", // Atau "" jika lebih sesuai
    );
  }
}

class StatusPembayaran {
  final int pStatusPembayaranId;
  final String statusCode;
  final String statusName;

  StatusPembayaran({
    required this.pStatusPembayaranId,
    required this.statusCode,
    required this.statusName,
  });

  factory StatusPembayaran.fromJson(Map<String, dynamic> json) {
    return StatusPembayaran(
      pStatusPembayaranId: json['p_status_pembayaran_id'] as int? ?? 0,
      statusCode: json['status_code'] as String? ?? "",
      statusName: json['status_name'] as String? ?? "",
    );
  }
}

class MetodePembayaran {
  final int pMetodePembayaranId;
  final String metodeCode;
  final String metodeName;

  MetodePembayaran({
    required this.pMetodePembayaranId,
    required this.metodeCode,
    required this.metodeName,
  });

  factory MetodePembayaran.fromJson(Map<String, dynamic> json) {
    return MetodePembayaran(
      pMetodePembayaranId: json['p_metode_pembayaran_id'] as int? ?? 0,
      metodeCode: json['metode_code'] as String? ?? "",
      metodeName: json['metode_name'] as String? ?? "",
    );
  }
}
