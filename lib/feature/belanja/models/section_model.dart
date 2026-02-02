import 'product.dart';
import 'category_model.dart';

class SectionModel {
  final String id;
  final String title;
  final String displayType;
  final String? remarks;
  final List<SectionItemModel> items;

  SectionModel({
    required this.id,
    required this.title,
    required this.displayType,
    this.remarks,
    required this.items,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'],
      title: json['title'] ?? '',
      displayType: json['display_type'] ?? 'produk',
      remarks: json['remarks'],
      items:
          (json['items'] as List?)
              ?.map((e) => SectionItemModel.fromJson(e, json['display_type']))
              .toList() ??
          [],
    );
  }
}

class SectionItemModel {
  final String id;
  final String? remarks;
  final Product? product;
  final CategoryModel? category;

  SectionItemModel({
    required this.id,
    this.remarks,
    this.product,
    this.category,
  });

  factory SectionItemModel.fromJson(
    Map<String, dynamic> json,
    String? displayType,
  ) {
    return SectionItemModel(
      id: json['id'],
      remarks: json['remarks'],
      product:
          json['product'] != null ? Product.fromApiJson(json['product']) : null,
      category:
          json['category'] != null
              ? CategoryModel.fromJson({
                'id': json['category']['id'],
                'kategori': json['category']['kategori'],
                'gambar_kategori_url': json['category']['gambar_kategori'],
                // Add defaults for missing fields
                'has_child': false,
              })
              : null,
    );
  }
}
