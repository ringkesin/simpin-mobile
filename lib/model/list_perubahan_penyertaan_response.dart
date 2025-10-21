import 'package:kkba_mobile/model/jenis_tabungan.dart';
import 'package:kkba_mobile/model/list_penyertaan_response.dart'; // Menggunakan kembali model MasterAnggotaPenyertaan

class ListPerubahanPenyertaanResponse {
  final bool success;
  final PerubahanPenyertaanData data;
  final String message;

  ListPerubahanPenyertaanResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory ListPerubahanPenyertaanResponse.fromJson(Map<String, dynamic> json) =>
      ListPerubahanPenyertaanResponse(
        success: json["success"],
        data: PerubahanPenyertaanData.fromJson(json["data"]),
        message: json["message"],
      );
}

class PerubahanPenyertaanData {
  final int currentPage;
  final List<PerubahanPenyertaan> data;
  final int lastPage;
  final int total;

  PerubahanPenyertaanData({
    required this.currentPage,
    required this.data,
    required this.lastPage,
    required this.total,
  });

  factory PerubahanPenyertaanData.fromJson(Map<String, dynamic> json) =>
      PerubahanPenyertaanData(
        currentPage: json["current_page"],
        data: List<PerubahanPenyertaan>.from(
          json["data"].map((x) => PerubahanPenyertaan.fromJson(x)),
        ),
        lastPage: json["last_page"],
        total: json["total"],
      );
}

class PerubahanPenyertaan {
  final String id;
  final int? nilaiSebelum;
  final int nilaiBaru;
  final DateTime validFrom;
  final String statusPerubahan;
  final String? catatanUser;
  final String? catatanApprover;
  final JenisTabunganItem jenisTabungan;
  final MasterAnggotaPenyertaan masterAnggota;

  PerubahanPenyertaan({
    required this.id,
    this.nilaiSebelum,
    required this.nilaiBaru,
    required this.validFrom,
    required this.statusPerubahan,
    this.catatanUser,
    this.catatanApprover,
    required this.jenisTabungan,
    required this.masterAnggota,
  });

  factory PerubahanPenyertaan.fromJson(Map<String, dynamic> json) =>
      PerubahanPenyertaan(
        id: json["t_tabungan_perubahan_penyertaan_id"],
        nilaiSebelum: json["nilai_sebelum"],
        nilaiBaru: json["nilai_baru"],
        validFrom: DateTime.parse(json["valid_from"]),
        statusPerubahan: json["status_perubahan_penyertaan"],
        catatanUser: json["catatan_user"],
        catatanApprover: json["catatan_approver"],
        jenisTabungan: JenisTabunganItem.fromJson(json["jenis_tabungan"]),
        masterAnggota: MasterAnggotaPenyertaan.fromJson(json["master_anggota"]),
      );
}
