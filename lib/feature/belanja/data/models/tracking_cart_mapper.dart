import '../../domain/entities/cart_item.dart';
import '../../domain/entities/tracking_cart.dart';
import '../../domain/entities/cart_entity.dart';
import '../../models/cart_model.dart';

/// Mapper untuk convert antara API model dan Domain entity
class TrackingCartMapper {
  /// Convert API model ke Domain entity
  static TrackingCartEntity fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = (json['items'] as List?) ?? [];

    return TrackingCartEntity(
      id: (json['id'] ?? '').toString(),
      anggotaId: (json['p_anggota_id'] ?? 0) as int,
      status: CartStatus.fromString((json['status'] ?? '').toString()),
      subtotal: _parseInt(json['subtotal']),
      subtotalAfterVoucher: _parseInt(json['subtotal_after_voucher']),
      lokasiDeliveryNama: (json['lokasi_delivery_nama'] ?? '').toString(),
      deliveryRemarks: json['delivery_remarks']?.toString(),
      remarks: json['remarks']?.toString(),
      confirmedAt: json['confirmed_at']?.toString(),
      expiredAt: json['expired_at']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      estimatedDeliveryAt: json['estimated_delivery_at']?.toString(),
      items:
          itemsJson
              .map((e) => CartItemMapper.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Mapper untuk CartItem
class CartItemMapper {
  static CartItem fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: (json['id'] ?? '').toString(),
      produkItemId: (json['produk_item_id'] ?? '').toString(),
      uomId: TrackingCartMapper._parseInt(json['uom_id']),
      hargaJual: TrackingCartMapper._parseInt(json['harga_jual']),
      qty: TrackingCartMapper._parseInt(json['qty']),
      subtotal: TrackingCartMapper._parseInt(json['subtotal']),
      remarks: json['remarks']?.toString(),
    );
  }
}

/// Mapper untuk Cart (cart_entity)
class CartMapper {
  /// Convert CartModel (dari service) ke CartEntity (domain)
  static CartEntity fromModel(CartModel model) {
    return CartEntity(
      items:
          model.items
              .map((item) => CartItemEntityMapper.fromModel(item))
              .toList(),
      summary: CartSummaryEntity(
        subtotal: model.summary.subtotal,
        discount: model.summary.discount,
        total: model.summary.total,
        voucherCode: model.summary.voucherCode,
      ),
      lokasiDeliveryNama: model.lokasiDeliveryNama,
      deliveryPicName: model.deliveryPicName,
      deliveryPicPhone: model.deliveryPicPhone,
      deliveryRemarks: model.deliveryRemarks,
      estimatedDeliveryAt: model.estimatedDeliveryAt,
    );
  }
}

/// Mapper untuk CartItem (cart_entity)
class CartItemEntityMapper {
  static CartItemEntity fromModel(CartItemModel model) {
    return CartItemEntity(
      id: model.id,
      productId: model.productId,
      productName: model.product.name,
      productImageUrl: model.product.imageUrl,
      quantity: model.quantity,
      price: model.price,
      totalPrice: model.totalPrice,
      remarks: model.remarks,
    );
  }
}
