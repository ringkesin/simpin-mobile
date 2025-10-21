import 'dart:convert';
// IMBAUAN: Pastikan path ke model jenis_tabungan.dart sudah benar
import 'jenis_tabungan.dart';

class ListPenyertaanResponse {
  final bool success;
  final PenyertaanData data;
  final String message;

  ListPenyertaanResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory ListPenyertaanResponse.fromJson(Map<String, dynamic> json) =>
      ListPenyertaanResponse(
        success: json["success"],
        data: PenyertaanData.fromJson(json["data"]),
        message: json["message"],
      );
}

class PenyertaanData {
  final int currentPage;
  final List<Penyertaan> data;
  final int lastPage;
  final int total;

  PenyertaanData({
    required this.currentPage,
    required this.data,
    required this.lastPage,
    required this.total,
  });

  factory PenyertaanData.fromJson(Map<String, dynamic> json) => PenyertaanData(
    currentPage: json["current_page"],
    data: List<Penyertaan>.from(
      json["data"].map((x) => Penyertaan.fromJson(x)),
    ),
    lastPage: json["last_page"],
    total: json["total"],
  );
}

class Penyertaan {
  final String tTabunganPenyertaanId;
  final int jumlah;
  final DateTime penyertaanDate;
  final String statusPenyertaan;
  final String? catatanUser;
  final String? catatanApprover;
  // --- PERUBAHAN DI SINI ---
  // Menggunakan model JenisTabunganItem dari file Anda
  final JenisTabunganItem jenisTabungan;
  final MasterAnggotaPenyertaan masterAnggota;

  Penyertaan({
    required this.tTabunganPenyertaanId,
    required this.jumlah,
    required this.penyertaanDate,
    required this.statusPenyertaan,
    this.catatanUser,
    this.catatanApprover,
    required this.jenisTabungan,
    required this.masterAnggota,
  });

  factory Penyertaan.fromJson(Map<String, dynamic> json) => Penyertaan(
    tTabunganPenyertaanId: json["t_tabungan_penyertaan_id"],
    jumlah: json["jumlah"],
    penyertaanDate: DateTime.parse(json["penyertaan_date"]),
    statusPenyertaan: json["status_penyertaan"],
    catatanUser: json["catatan_user"],
    catatanApprover: json["catatan_approver"],
    // --- PERUBAHAN DI SINI ---
    // Menggunakan factory fromJson dari JenisTabunganItem
    jenisTabungan: JenisTabunganItem.fromJson(json["jenis_tabungan"]),
    masterAnggota: MasterAnggotaPenyertaan.fromJson(json["master_anggota"]),
  );
}

// Model JenisTabunganPenyertaan dihapus dari file ini karena sudah ada di jenis_tabungan.dart

class MasterAnggotaPenyertaan {
  final int pAnggotaId;
  final String nomorAnggota;
  final String nama;
  final String nik;

  MasterAnggotaPenyertaan({
    required this.pAnggotaId,
    required this.nomorAnggota,
    required this.nama,
    required this.nik,
  });

  factory MasterAnggotaPenyertaan.fromJson(Map<String, dynamic> json) =>
      MasterAnggotaPenyertaan(
        pAnggotaId: json["p_anggota_id"],
        nomorAnggota: json["nomor_anggota"],
        nama: json["nama"],
        nik: json["nik"],
      );
}
