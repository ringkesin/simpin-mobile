// lib/model/document_attribute.dart

// import 'dart:convert';

class DocumentAttributeResponse {
  final bool success;
  final DocumentAttributeData? data;
  final String message;

  DocumentAttributeResponse({
    required this.success,
    this.data,
    required this.message,
  });

  factory DocumentAttributeResponse.fromJson(Map<String, dynamic> json) =>
      DocumentAttributeResponse(
        success: json["success"],
        data:
            json["data"] == null
                ? null
                : DocumentAttributeData.fromJson(json["data"]),
        message: json["message"],
      );
}

class DocumentAttributeData {
  final String? attr_no_ktp;
  final String? attachment_ktp;
  final String? attr_no_kartu_pegawai;
  final String? attachment_kartu_pegawai;
  final String? attr_no_kartu_keluarga;
  final String? attachment_kartu_keluarga;
  final String? attr_npwp;
  final String? attachment_npwp;
  final String? attr_buku_nikah;
  final String? attachment_buku_nikah;

  DocumentAttributeData({
    this.attr_no_ktp,
    this.attachment_ktp,
    this.attr_no_kartu_pegawai,
    this.attachment_kartu_pegawai,
    this.attr_no_kartu_keluarga,
    this.attachment_kartu_keluarga,
    this.attr_npwp,
    this.attachment_npwp,
    this.attr_buku_nikah,
    this.attachment_buku_nikah,
  });

  factory DocumentAttributeData.fromJson(Map<String, dynamic> json) =>
      DocumentAttributeData(
        attr_no_ktp: json["attr_no_ktp"],
        attachment_ktp: json["attachment_ktp"],
        attr_no_kartu_pegawai: json["attr_no_kartu_pegawai"],
        attachment_kartu_pegawai: json["attachment_kartu_pegawai"],
        attr_no_kartu_keluarga: json["attr_no_kartu_keluarga"],
        attachment_kartu_keluarga: json["attachment_kartu_keluarga"],
        attr_npwp: json["attr_npwp"],
        attachment_npwp: json["attachment_npwp"],
        attr_buku_nikah: json["attr_buku_nikah"],
        attachment_buku_nikah: json["attachment_buku_nikah"],
      );
}
