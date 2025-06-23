// lib/model/berita.dart

import 'dart:convert';

// Model Universal untuk satu item berita
// Nama field disesuaikan dengan model yang Anda berikan (title, text)
class BeritaItem {
  final String? id;
  final int contentTypeId;
  final String? thumbnailPath;
  final String title;
  final String text; // Ini adalah field untuk 'content_text' dari API
  final String validFrom;
  final String? validTo;

  BeritaItem({
    required this.id,
    required this.contentTypeId,
    this.thumbnailPath,
    required this.title,
    required this.text,
    required this.validFrom,
    this.validTo,
  });

  factory BeritaItem.fromJson(Map<String, dynamic> json) {
    return BeritaItem(
      id: json['t_content_id'] as String?,
      contentTypeId: json['p_content_type_id'] as int? ?? 0,
      thumbnailPath: json['thumbnail_path'] as String?,
      title: json['content_title'] as String? ?? 'Tanpa Judul',
      text: json['content_text'] as String? ?? '',
      validFrom: json['valid_from'] as String? ?? '',
      validTo: json['valid_to'] as String?,
    );
  }
}

// Model untuk response API list berita (/api/konten)
class BeritaResponse {
  final bool success;
  final BeritaListData? data;
  final String message;

  BeritaResponse({required this.success, this.data, required this.message});

  factory BeritaResponse.fromJson(Map<String, dynamic> json) {
    return BeritaResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? BeritaListData.fromJson(json['data']) : null,
      message: json['message'] as String? ?? '',
    );
  }
}

class BeritaListData {
  final List<BeritaItem> content;

  BeritaListData({required this.content});

  factory BeritaListData.fromJson(Map<String, dynamic> json) {
    var contentList = json['content'] as List? ?? [];
    List<BeritaItem> items =
        contentList.map((item) => BeritaItem.fromJson(item)).toList();
    return BeritaListData(content: items);
  }
}

// DIUBAH: Model untuk response detail berita agar cocok dengan struktur JSON
class SingleBeritaResponse {
  final bool success;
  final SingleBeritaData? data;
  final String message;

  SingleBeritaResponse({
    required this.success,
    this.data,
    required this.message,
  });

  factory SingleBeritaResponse.fromJson(Map<String, dynamic> json) {
    return SingleBeritaResponse(
      success: json['success'] as bool? ?? false,
      data:
          json['data'] != null ? SingleBeritaData.fromJson(json['data']) : null,
      message: json['message'] as String? ?? '',
    );
  }
}

// BARU: Class perantara untuk menangani {"data": {"content": ...}}
class SingleBeritaData {
  final BeritaItem content;

  SingleBeritaData({required this.content});

  factory SingleBeritaData.fromJson(Map<String, dynamic> json) {
    return SingleBeritaData(content: BeritaItem.fromJson(json['content']));
  }
}
