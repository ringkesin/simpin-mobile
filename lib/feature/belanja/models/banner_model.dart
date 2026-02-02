class BannerModel {
  final String id;
  final String title;
  final String image;
  final String? remarks;
  final BannerBrand? brand;

  BannerModel({
    required this.id,
    required this.title,
    required this.image,
    this.remarks,
    this.brand,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      remarks: json['remarks'],
      brand: json['brand'] != null ? BannerBrand.fromJson(json['brand']) : null,
    );
  }
}

class BannerBrand {
  final int id;
  final String brand;

  BannerBrand({
    required this.id,
    required this.brand,
  });

  factory BannerBrand.fromJson(Map<String, dynamic> json) {
    return BannerBrand(
      id: json['id'],
      brand: json['brand'],
    );
  }
}
