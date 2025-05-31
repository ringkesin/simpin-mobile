// model/pinjaman_list_models.dart

// Helper functions (bisa tetap di sini atau dipindahkan ke file utils jika lebih suka)
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  // Hati-hati jika mengonversi double ke int, akan memotong desimal
  if (value is double) return value.toInt();
  return null;
}

// --- Model untuk Master Data Sederhana ---
class MasterAnggotaSimpleModel {
  final int pAnggotaId;
  final String? nomorAnggota;
  final String? nama;
  final String? nik;
  // Tambahkan field lain jika diperlukan

  MasterAnggotaSimpleModel({
    required this.pAnggotaId,
    this.nomorAnggota,
    this.nama,
    this.nik,
  });

  factory MasterAnggotaSimpleModel.fromJson(Map<String, dynamic> json) {
    return MasterAnggotaSimpleModel(
      pAnggotaId: json['p_anggota_id'] as int,
      nomorAnggota: json['nomor_anggota'] as String?,
      nama: json['nama'] as String?,
      nik: json['nik'] as String?,
    );
  }
}

class MasterJenisPinjamanSimpleModel {
  final int pJenisPinjamanId;
  final String? nama;
  final String? kodeJenisPinjaman;

  MasterJenisPinjamanSimpleModel({
    required this.pJenisPinjamanId,
    this.nama,
    this.kodeJenisPinjaman,
  });

  factory MasterJenisPinjamanSimpleModel.fromJson(Map<String, dynamic> json) {
    return MasterJenisPinjamanSimpleModel(
      pJenisPinjamanId: json['p_jenis_pinjaman_id'] as int,
      nama: json['nama'] as String?,
      kodeJenisPinjaman: json['kode_jenis_pinjaman'] as String?,
    );
  }
}

class MasterStatusPengajuanSimpleModel {
  // Model ini sudah ada dan akan digunakan
  final int pStatusPengajuanId;
  final String? nama;

  MasterStatusPengajuanSimpleModel({
    required this.pStatusPengajuanId,
    this.nama,
  });

  factory MasterStatusPengajuanSimpleModel.fromJson(Map<String, dynamic> json) {
    // Memastikan parsing ID yang lebih aman jika API mungkin mengirim tipe berbeda untuk ID
    final idValue = json['p_status_pengajuan_id'] ?? json['id'];
    return MasterStatusPengajuanSimpleModel(
      pStatusPengajuanId:
          _parseInt(idValue) ?? 0, // Default ke 0 jika parsing gagal
      nama: json['nama'] as String?,
    );
  }
}

// --- Model untuk Detail Setiap Item Pinjaman ---
class PinjamanDetailModel {
  final int tPinjamanId;
  final int pAnggotaId;
  final int pJenisPinjamanId;
  final String? nomorPinjaman;
  final List<int> pPinjamanKeperluanIds;
  final String? jenisBarang;
  final String? merkType;
  final int? tenor;
  final double? biayaAdmin;
  final double? raJumlahPinjaman;
  final double? riJumlahPinjaman;
  final String? jaminan;
  final String? jaminanKeterangan;
  final double? jaminanPerkiraanNilai;
  final String? noRekening;
  final String? bank;
  final DateTime? tglPencairan;
  final DateTime? tglPelunasan;
  final String? docSlipGaji;
  final int pStatusPengajuanId;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int? createdBy;
  final int? updatedBy;
  final int? deletedBy;
  final double? margin;
  final List<String> pinjamanKeperluanNama;
  final double? estimasiCicilanBulanan;
  final MasterJenisPinjamanSimpleModel masterJenisPinjaman;
  final MasterStatusPengajuanSimpleModel masterStatusPengajuan;
  final MasterAnggotaSimpleModel masterAnggota;

  PinjamanDetailModel({
    required this.tPinjamanId,
    required this.pAnggotaId,
    required this.pJenisPinjamanId,
    this.nomorPinjaman,
    required this.pPinjamanKeperluanIds,
    this.jenisBarang,
    this.merkType,
    this.tenor,
    this.biayaAdmin,
    this.raJumlahPinjaman,
    this.riJumlahPinjaman,
    this.jaminan,
    this.jaminanKeterangan,
    this.jaminanPerkiraanNilai,
    this.noRekening,
    this.bank,
    this.tglPencairan,
    this.tglPelunasan,
    this.docSlipGaji,
    required this.pStatusPengajuanId,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.margin,
    required this.pinjamanKeperluanNama,
    this.estimasiCicilanBulanan,
    required this.masterJenisPinjaman,
    required this.masterStatusPengajuan,
    required this.masterAnggota,
  });

  factory PinjamanDetailModel.fromJson(Map<String, dynamic> json) {
    return PinjamanDetailModel(
      tPinjamanId: json['t_pinjaman_id'] as int,
      pAnggotaId: json['p_anggota_id'] as int,
      pJenisPinjamanId: json['p_jenis_pinjaman_id'] as int,
      nomorPinjaman: json['nomor_pinjaman'] as String?,
      pPinjamanKeperluanIds:
          (json['p_pinjaman_keperluan_ids'] as List<dynamic>?)
              ?.map((e) => _parseInt(e) ?? 0)
              .where((id) => id != 0)
              .toList() ??
          [],
      jenisBarang: json['jenis_barang'] as String?,
      merkType: json['merk_type'] as String?,
      tenor: _parseInt(json['tenor']),
      biayaAdmin: _parseDouble(json['biaya_admin']),
      raJumlahPinjaman: _parseDouble(json['ra_jumlah_pinjaman']),
      riJumlahPinjaman: _parseDouble(json['ri_jumlah_pinjaman']),
      jaminan: json['jaminan'] as String?,
      jaminanKeterangan: json['jaminan_keterangan'] as String?,
      jaminanPerkiraanNilai: _parseDouble(json['jaminan_perkiraan_nilai']),
      noRekening: json['no_rekening'] as String?,
      bank: json['bank'] as String?,
      tglPencairan:
          json['tgl_pencairan'] == null
              ? null
              : DateTime.tryParse(json['tgl_pencairan'] as String),
      tglPelunasan:
          json['tgl_pelunasan'] == null
              ? null
              : DateTime.tryParse(json['tgl_pelunasan'] as String),
      docSlipGaji: json['doc_slip_gaji'] as String?,
      pStatusPengajuanId: json['p_status_pengajuan_id'] as int,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt:
          json['deleted_at'] == null
              ? null
              : DateTime.tryParse(json['deleted_at'] as String),
      createdBy: _parseInt(json['created_by']),
      updatedBy: _parseInt(json['updated_by']),
      deletedBy: _parseInt(json['deleted_by']),
      margin: _parseDouble(json['margin']),
      pinjamanKeperluanNama:
          (json['pinjaman_keperluan_nama'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      estimasiCicilanBulanan: _parseDouble(json['estimasi_cicilan_bulanan']),
      masterJenisPinjaman: MasterJenisPinjamanSimpleModel.fromJson(
        json['master_jenis_pinjaman'] as Map<String, dynamic>,
      ),
      masterStatusPengajuan: MasterStatusPengajuanSimpleModel.fromJson(
        json['master_status_pengajuan'] as Map<String, dynamic>,
      ),
      masterAnggota: MasterAnggotaSimpleModel.fromJson(
        json['master_anggota'] as Map<String, dynamic>,
      ),
    );
  }
}

// --- Model untuk Data Paginasi ---
class PaginationDataPinjaman {
  final int currentPage;
  final List<PinjamanDetailModel> data;
  final String? firstPageUrl;
  final int? from;
  final int? lastPage;
  final String? lastPageUrl;
  // Jika Anda ingin memodelkan 'links' secara detail, buat LinkModel terpisah
  // final List<LinkModel> links;
  final String? nextPageUrl;
  final String? path;
  final int? perPage;
  final String? prevPageUrl;
  final int? to;
  final int? total;

  PaginationDataPinjaman({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    this.from,
    this.lastPage,
    this.lastPageUrl,
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
    this.total,
  });

  factory PaginationDataPinjaman.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List?;
    List<PinjamanDetailModel> pinjamanList =
        list != null
            ? list
                .map(
                  (i) =>
                      PinjamanDetailModel.fromJson(i as Map<String, dynamic>),
                )
                .toList()
            : [];

    return PaginationDataPinjaman(
      currentPage: json['current_page'] as int,
      data: pinjamanList,
      firstPageUrl: json['first_page_url'] as String?,
      from: _parseInt(json['from']),
      lastPage: json['last_page'] as int?,
      lastPageUrl: json['last_page_url'] as String?,
      nextPageUrl: json['next_page_url'] as String?,
      path: json['path'] as String?,
      perPage: _parseInt(json['per_page']),
      prevPageUrl: json['prev_page_url'] as String?,
      to: _parseInt(json['to']),
      total: _parseInt(json['total']),
    );
  }
}

// --- Model untuk Respons API Utama ---
class PinjamanListResponse {
  final bool success;
  final PaginationDataPinjaman data;
  final String message;

  PinjamanListResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory PinjamanListResponse.fromJson(Map<String, dynamic> json) {
    return PinjamanListResponse(
      success: json['success'] as bool,
      data: PaginationDataPinjaman.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
      message: json['message'] as String,
    );
  }
}

class StatusPengajuanMasterListResponse {
  final bool success;
  final List<MasterStatusPengajuanSimpleModel> statusPengajuan;
  final String? message;

  StatusPengajuanMasterListResponse({
    required this.success,
    required this.statusPengajuan,
    this.message,
  });

  factory StatusPengajuanMasterListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    var dataField = json['data'] as Map<String, dynamic>?;
    var list = dataField?['status_pengajuan'] as List?;

    List<MasterStatusPengajuanSimpleModel> statusList =
        list != null
            ? list
                .map(
                  (i) => MasterStatusPengajuanSimpleModel.fromJson(
                    i as Map<String, dynamic>,
                  ),
                )
                .toList()
            : [];

    return StatusPengajuanMasterListResponse(
      success: json['success'] as bool? ?? false,
      statusPengajuan: statusList,
      message: json['message'] as String?,
    );
  }
}
