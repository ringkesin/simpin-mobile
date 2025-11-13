import 'package:flutter/material.dart';

class Product {
  final String name;
  final int price;
  final int discountPercent;
  const Product({required this.name, required this.price, this.discountPercent = 0});
}

// Helper untuk format rupiah sederhana: 6000 -> Rp6.000
String formatRp(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  int count = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    buffer.write(s[i]);
    count++;
    if (count == 3 && i != 0) {
      buffer.write('.');
      count = 0;
    }
  }
  final formatted = buffer.toString().split('').reversed.join();
  return 'Rp$formatted';
}

int originalPrice(int price, int discountPercent) {
  if (discountPercent <= 0) return price;
  return (price / (1 - discountPercent / 100)).round();
}