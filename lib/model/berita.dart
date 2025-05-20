// Model untuk satu item berita/konten
class BeritaItem {
  final String? id;
  final int contentTypeId;
  final String? thumbnailPath; // Bisa null jika API memungkinkan
  final String title;
  final String text; // Ini berisi HTML
  final String validFrom; // Simpan sebagai String, parsing di UI jika perlu
  final String? validTo; // Bisa null
  final dynamic createdBy; // Tipe bisa int/String, gunakan dynamic atau int?
  final dynamic updatedBy;
  // Tambahkan field lain jika diperlukan (deleted_at, deleted_by, dll)

  BeritaItem({
    required this.id,
    required this.contentTypeId,
    this.thumbnailPath,
    required this.title,
    required this.text,
    required this.validFrom,
    this.validTo,
    this.createdBy,
    this.updatedBy,
  });

  factory BeritaItem.fromJson(Map<String, dynamic> json) {
    return BeritaItem(
      id: json['t_content_id'] as String?, // Default 0 jika null
      contentTypeId: json['p_content_type_id'] as int? ?? 0,
      thumbnailPath: json['thumbnail_path'] as String?,
      title:
          json['content_title'] as String? ??
          'Tanpa Judul', // Default jika null
      text: json['content_text'] as String? ?? '', // Default string kosong
      validFrom: json['valid_from'] as String? ?? '',
      validTo: json['valid_to'] as String?,
      createdBy: json['created_by'], // Biarkan dynamic atau cast ke int?
      updatedBy: json['updated_by'], // Biarkan dynamic atau cast ke int?
    );
  }

  // Opsional: toJson jika perlu mengirim data kembali
  Map<String, dynamic> toJson() {
    return {
      't_content_id': id,
      'p_content_type_id': contentTypeId,
      'thumbnail_path': thumbnailPath,
      'content_title': title,
      'content_text': text,
      'valid_from': validFrom,
      'valid_to': validTo,
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }
}

// Model untuk object 'data' dalam response list
class BeritaData {
  final List<BeritaItem> content;

  BeritaData({required this.content});

  factory BeritaData.fromJson(Map<String, dynamic> json) {
    var contentList = json['content'] as List?; // Ambil list, bisa null
    List<BeritaItem> items = [];
    if (contentList != null) {
      items =
          contentList.map((itemJson) {
            // Pastikan itemJson adalah Map<String, dynamic>
            if (itemJson is Map<String, dynamic>) {
              return BeritaItem.fromJson(itemJson);
            } else {
              // Handle kasus jika item bukan map (meskipun seharusnya tidak terjadi)
              // Anda bisa throw error atau return item default/null
              print("Error: Item in content list is not a Map: $itemJson");
              // Contoh fallback: return BeritaItem default atau lewati item ini
              return BeritaItem(
                id: '',
                contentTypeId: -1,
                title: 'Invalid Item',
                text: '',
                validFrom: '',
              ); // Atau cara lain
            }
          }).toList();
    }
    return BeritaData(content: items);
  }
}

// Model untuk response API list berita (/api/konten)
class BeritaResponse {
  final bool success;
  final BeritaData?
  data; // Buat nullable jika data bisa tidak ada saat success=false
  final String message;

  BeritaResponse({required this.success, this.data, required this.message});

  factory BeritaResponse.fromJson(Map<String, dynamic> json) {
    return BeritaResponse(
      success: json['success'] as bool? ?? false,
      // Parse 'data' hanya jika ada dan bukan null
      data:
          json['data'] != null && json['data'] is Map<String, dynamic>
              ? BeritaData.fromJson(json['data'] as Map<String, dynamic>)
              : null,
      message: json['message'] as String? ?? '',
    );
  }
}

// Model untuk response API detail berita (/api/konten/{id})
// Asumsi struktur data mirip, tapi 'data' berisi satu BeritaItem
class SingleBeritaResponse {
  final bool success;
  final BeritaItem? data; // Langsung ke BeritaItem, nullable
  final String message;

  SingleBeritaResponse({
    required this.success,
    this.data,
    required this.message,
  });

  factory SingleBeritaResponse.fromJson(Map<String, dynamic> json) {
    return SingleBeritaResponse(
      success: json['success'] as bool? ?? false,
      // Parse 'data' menjadi BeritaItem jika ada dan bukan null
      data:
          json['data'] != null && json['data'] is Map<String, dynamic>
              ? BeritaItem.fromJson(json['data'] as Map<String, dynamic>)
              : null,
      message: json['message'] as String? ?? '',
    );
  }
}
