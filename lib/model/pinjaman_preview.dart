import 'dart:convert';
import 'package:kkba_mobile/model/pinjaman_list.dart'; // Menggunakan kembali model yang ada

// Helper functions untuk parsing aman, bisa di-import dari model Anda atau didefinisikan di sini
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
  if (value is double) return value.toInt();
  return null;
}

// 1. Model Wrapper untuk keseluruhan respons API
class PinjamanPreviewResponse {
  final bool success;
  final PinjamanPreviewDetail data;
  final String message;

  PinjamanPreviewResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory PinjamanPreviewResponse.fromJson(Map<String, dynamic> json) =>
      PinjamanPreviewResponse(
        success: json["success"],
        data: PinjamanPreviewDetail.fromJson(json["data"]),
        message: json["message"],
      );
}

// 2. Model utama yang berisi semua detail data pinjaman untuk preview
class PinjamanPreviewDetail {
  final int tPinjamanId;
  final int pAnggotaId;
  final int pJenisPinjamanId;
  final String? nomorPinjaman;
  final int tenor;
  final double? biayaAdmin;
  final double? raJumlahPinjaman;
  final double? riJumlahPinjaman;
  final String? jaminan;
  final String? jaminanKeterangan;
  final double? jaminanPerkiraanNilai;
  final String? noRekening;
  final String? bank;
  final String? tglPencairan;
  final String? tglPelunasan;
  final String? docSlipGaji;
  final int pStatusPengajuanId;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? margin;
  final List<String> pinjamanKeperluanNama;
  final double? estimasiCicilanBulanan;
  final MasterJenisPinjamanSimpleModel masterJenisPinjaman;
  final MasterStatusPengajuanSimpleModel masterStatusPengajuan;
  final MasterAnggotaPreviewModel
  masterAnggota; // Menggunakan model anggota yang lebih detail

  PinjamanPreviewDetail({
    required this.tPinjamanId,
    required this.pAnggotaId,
    required this.pJenisPinjamanId,
    this.nomorPinjaman,
    required this.tenor,
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
    this.margin,
    required this.pinjamanKeperluanNama,
    this.estimasiCicilanBulanan,
    required this.masterJenisPinjaman,
    required this.masterStatusPengajuan,
    required this.masterAnggota,
  });

  factory PinjamanPreviewDetail.fromJson(Map<String, dynamic> json) =>
      PinjamanPreviewDetail(
        tPinjamanId: json["t_pinjaman_id"],
        pAnggotaId: json["p_anggota_id"],
        pJenisPinjamanId: json["p_jenis_pinjaman_id"],
        nomorPinjaman: json["nomor_pinjaman"],
        tenor: _parseInt(json["tenor"]) ?? 0,
        biayaAdmin: _parseDouble(json["biaya_admin"]),
        raJumlahPinjaman: _parseDouble(json["ra_jumlah_pinjaman"]),
        riJumlahPinjaman: _parseDouble(json["ri_jumlah_pinjaman"]),
        jaminan: json["jaminan"],
        jaminanKeterangan: json["jaminan_keterangan"],
        jaminanPerkiraanNilai: _parseDouble(json["jaminan_perkiraan_nilai"]),
        noRekening: json["no_rekening"],
        bank: json["bank"],
        tglPencairan: json["tgl_pencairan"],
        tglPelunasan: json["tgl_pelunasan"],
        docSlipGaji: json["doc_slip_gaji"],
        pStatusPengajuanId: json["p_status_pengajuan_id"],
        remarks: json["remarks"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        margin: json["margin"]?.toString(),
        pinjamanKeperluanNama: List<String>.from(
          json["pinjaman_keperluan_nama"].map((x) => x),
        ),
        estimasiCicilanBulanan: _parseDouble(json["estimasi_cicilan_bulanan"]),
        masterJenisPinjaman: MasterJenisPinjamanSimpleModel.fromJson(
          json["master_jenis_pinjaman"],
        ),
        masterStatusPengajuan: MasterStatusPengajuanSimpleModel.fromJson(
          json["master_status_pengajuan"],
        ),
        masterAnggota: MasterAnggotaPreviewModel.fromJson(
          json["master_anggota"],
        ),
      );
}

// 3. Model untuk master_anggota yang lebih detail sesuai JSON preview
class MasterAnggotaPreviewModel {
  final int pAnggotaId;
  final String? nomorAnggota;
  final DateTime? validFrom;
  final String? tanggalMasuk;
  final String? nama;
  final String? nik;
  final String? alamat;
  final String? ktp;
  final String? tempatLahir;
  final String? tglLahir;
  final String? email;
  final String? mobile;
  final bool isRegistered;

  MasterAnggotaPreviewModel({
    required this.pAnggotaId,
    this.nomorAnggota,
    this.validFrom,
    this.tanggalMasuk,
    this.nama,
    this.nik,
    this.alamat,
    this.ktp,
    this.tempatLahir,
    this.tglLahir,
    this.email,
    this.mobile,
    required this.isRegistered,
  });

  factory MasterAnggotaPreviewModel.fromJson(Map<String, dynamic> json) =>
      MasterAnggotaPreviewModel(
        pAnggotaId: json["p_anggota_id"],
        nomorAnggota: json["nomor_anggota"],
        validFrom:
            json["valid_from"] == null
                ? null
                : DateTime.parse(json["valid_from"]),
        tanggalMasuk: json["tanggal_masuk"],
        nama: json["nama"],
        nik: json["nik"],
        alamat: json["alamat"],
        ktp: json["ktp"],
        tempatLahir: json["tempat_lahir"],
        tglLahir: json["tgl_lahir"],
        email: json["email"],
        mobile: json["mobile"],
        isRegistered: json["is_registered"] ?? false,
      );
}
