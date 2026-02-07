import 'product.dart';

class CartModel {
  final List<CartItemModel> items;
  final CartSummaryModel summary;

  CartModel({required this.items, required this.summary});

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      items:
          (json['items'] as List?)
              ?.map((e) => CartItemModel.fromJson(e))
              .toList() ??
          [],
      summary: CartSummaryModel.fromJson(json),
    );
  }

  // Helper untuk mendapatkan total quantity items
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}

class CartItemModel {
  final String id; // ID item di keranjang
  final String productId;
  final Product product;
  final int quantity;
  final int price; // Harga per item saat masuk keranjang
  final int totalPrice; // quantity * price
  final String? remarks;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.product,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    this.remarks,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final int qty = json['quantity'] ?? json['qty'] ?? 0;
    final dynamic priceRaw = json['price'] ??
        json['harga'] ??
        json['harga_satuan'] ??
        json['harga_item'] ??
        json['harga_jual'] ??
        (json['product'] is Map ? (json['product']['harga_jual']) : null);
    final int price = priceRaw is num
        ? priceRaw.round()
        : int.tryParse('${priceRaw ?? ''}') ?? 0;

    final dynamic totalRaw = json['total_price'] ??
        json['total_harga'] ??
        json['subtotal'] ??
        (price > 0 && qty > 0 ? price * qty : null);
    final int totalPrice = totalRaw is num
        ? totalRaw.round()
        : int.tryParse('${totalRaw ?? ''}') ?? 0;

    return CartItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? json['produk_item_id']?.toString() ?? '',
      product: Product.fromApiJson(json['product'] ?? {}),
      quantity: qty,
      price: price,
      totalPrice: totalPrice,
      remarks: json['remarks'],
    );
  }
}

class CartSummaryModel {
  final int subtotal;
  final int discount;
  final int total;
  final String? voucherCode;

  CartSummaryModel({
    required this.subtotal,
    required this.discount,
    required this.total,
    this.voucherCode,
  });

  factory CartSummaryModel.fromJson(Map<String, dynamic> json) {
    return CartSummaryModel(
      subtotal: json['subtotal'] ?? 0,
      discount: json['voucher_diskon_value'] ?? 0,
      total: json['subtotal_after_voucher'] ?? 0,
      voucherCode: json['voucher_id']?.toString(),
    );
  }
}
