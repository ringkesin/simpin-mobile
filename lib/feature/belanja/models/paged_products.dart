import 'product.dart';

class PagedProducts {
  final List<Product> items;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  PagedProducts({required this.items, required this.currentPage, required this.perPage, required this.total, required this.lastPage});

  factory PagedProducts.fromResponse(Map<String, dynamic> json) {
    final List<dynamic> list = (json['data'] as List?) ?? [];
    final Map<String, dynamic> meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? {};
    return PagedProducts(
      items: list.map((e) => Product.fromApiJson((e as Map).cast<String, dynamic>())).toList(),
      currentPage: meta['current_page'] ?? 1,
      perPage: meta['per_page'] ?? list.length,
      total: meta['total'] ?? list.length,
      lastPage: meta['last_page'] ?? 1,
    );
  }
}

