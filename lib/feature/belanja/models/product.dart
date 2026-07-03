import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final int price;
  final int discountPercent;
  final String? imageUrl;
  final bool isStockAvailable;

  const Product({
    this.id = '',
    required this.name,
    required this.price,
    this.discountPercent = 0,
    this.imageUrl,
    this.isStockAvailable = true,
  });

  factory Product.fromApiJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['nama_produk'] ?? '',
      price: json['harga_jual'] ?? 0,
      discountPercent: json['diskon_persen'] ?? 0,
      imageUrl:
          (json['gambar_produk'] ?? '').toString().replaceAll('`', '').trim(),
      isStockAvailable: json['is_stock_available'] ?? true,
    );
  }
}

int originalPrice(int price, int discountPercent) {
  if (discountPercent <= 0) return price;
  return (price / (1 - discountPercent / 100)).round();
}
