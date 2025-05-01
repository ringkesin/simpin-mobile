// Model untuk satu item jenis tabungan
class JenisTabunganItem {
  final int id;
  final String nama;
  // Menggunakan boolean lebih idiomatik di Dart untuk flag seperti ini
  final bool isWithdrawable;

  JenisTabunganItem({
    required this.id,
    required this.nama,
    required this.isWithdrawable,
  });

  factory JenisTabunganItem.fromJson(Map<String, dynamic> json) {
    return JenisTabunganItem(
      id: json['p_jenis_tabungan_id'] as int? ?? 0, // Default 0 jika null
      nama: json['nama'] as String? ?? 'Tanpa Nama', // Default jika null
      // Konversi nilai integer (1/0) ke boolean
      isWithdrawable: (json['withdrawal'] == 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'p_jenis_tabungan_id': id,
      'nama': nama,
      'withdrawal':
          isWithdrawable ? 1 : 0, // Konversi boolean ke integer saat toJson
    };
  }
}

// Model untuk object 'data' dalam response
class JenisTabunganData {
  final List<JenisTabunganItem> jenisTabungan;

  JenisTabunganData({required this.jenisTabungan});

  factory JenisTabunganData.fromJson(Map<String, dynamic> json) {
    var list = json['jenis_tabungan'] as List?;
    List<JenisTabunganItem> items = [];
    if (list != null) {
      items =
          list.map((itemJson) {
            if (itemJson is Map<String, dynamic>) {
              return JenisTabunganItem.fromJson(itemJson);
            } else {
              print(
                "Error: Item in jenis_tabungan list is not a Map: $itemJson",
              );
              // Fallback atau throw error
              return JenisTabunganItem(
                id: -1,
                nama: 'Invalid Item',
                isWithdrawable: false,
              );
            }
          }).toList();
    }
    return JenisTabunganData(jenisTabungan: items);
  }
}

// Model untuk response API level teratas
class JenisTabunganResponse {
  final bool success;
  final JenisTabunganData? data; // Nullable jika bisa tidak ada
  final String message;

  JenisTabunganResponse({
    required this.success,
    this.data,
    required this.message,
  });

  factory JenisTabunganResponse.fromJson(Map<String, dynamic> json) {
    return JenisTabunganResponse(
      success: json['success'] as bool? ?? false,
      data:
          json['data'] != null && json['data'] is Map<String, dynamic>
              ? JenisTabunganData.fromJson(json['data'] as Map<String, dynamic>)
              : null,
      message: json['message'] as String? ?? '',
    );
  }
}
