class CategoryModel {
  final int id;
  final String kategori;
  final String? remarks;
  final String? gambarKategori;
  final String gambarKategoriUrl;
  final bool hasChild;

  CategoryModel({
    required this.id,
    required this.kategori,
    this.remarks,
    this.gambarKategori,
    required this.gambarKategoriUrl,
    required this.hasChild,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      kategori: json['kategori'] ?? '',
      remarks: json['remarks'],
      gambarKategori: json['gambar_kategori'],
      gambarKategoriUrl:
          (json['gambar_kategori_url'] ?? '')
              .toString()
              .replaceAll('`', '')
              .trim(),
      hasChild: json['has_child'] ?? false,
    );
  }
}
