/// Entity untuk Cart Item (domain layer)
class CartItemEntity {
  final String id;
  final String productId;
  final String productName;
  final String? productImageUrl;
  final int quantity;
  final int price;
  final int totalPrice;
  final String? remarks;

  const CartItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    this.remarks,
  });
}

/// Entity untuk Cart Summary (domain layer)
class CartSummaryEntity {
  final int subtotal;
  final int discount;
  final int total;
  final String? voucherCode;

  const CartSummaryEntity({
    required this.subtotal,
    required this.discount,
    required this.total,
    this.voucherCode,
  });
}

/// Entity untuk Cart (domain layer)
class CartEntity {
  final List<CartItemEntity> items;
  final CartSummaryEntity summary;
  final String? lokasiDeliveryNama;
  final String? deliveryPicName;
  final String? deliveryPicPhone;
  final String? deliveryRemarks;
  final String? estimatedDeliveryAt;

  const CartEntity({
    required this.items,
    required this.summary,
    this.lokasiDeliveryNama,
    this.deliveryPicName,
    this.deliveryPicPhone,
    this.deliveryRemarks,
    this.estimatedDeliveryAt,
  });

  /// Helper untuk mendapatkan total quantity items
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}
