class TrackingItem {
  final String id;
  final String produkItemId;
  final int uomId;
  final int hargaJual;
  final int qty;
  final int subtotal;
  final String? remarks;

  TrackingItem({
    required this.id,
    required this.produkItemId,
    required this.uomId,
    required this.hargaJual,
    required this.qty,
    required this.subtotal,
    this.remarks,
  });

  factory TrackingItem.fromJson(Map<String, dynamic> json) {
    return TrackingItem(
      id: (json['id'] ?? '').toString(),
      produkItemId: (json['produk_item_id'] ?? '').toString(),
      uomId: (json['uom_id'] ?? 0) as int,
      hargaJual: (json['harga_jual'] ?? 0) is num ? (json['harga_jual'] as num).round() : int.tryParse('${json['harga_jual'] ?? 0}') ?? 0,
      qty: (json['qty'] ?? 0) is num ? (json['qty'] as num).round() : int.tryParse('${json['qty'] ?? 0}') ?? 0,
      subtotal: (json['subtotal'] ?? 0) is num ? (json['subtotal'] as num).round() : int.tryParse('${json['subtotal'] ?? 0}') ?? 0,
      remarks: json['remarks']?.toString(),
    );
  }
}

class TrackingCart {
  final String id;
  final int anggotaId;
  final String status;
  final int subtotal;
  final int subtotalAfterVoucher;
  final String lokasiDeliveryNama;
  final String? deliveryRemarks;
  final String? remarks;
  final String? confirmedAt;
  final String? expiredAt;
  final String createdAt;
  final String? estimatedDeliveryAt;
  final List<TrackingItem> items;

  TrackingCart({
    required this.id,
    required this.anggotaId,
    required this.status,
    required this.subtotal,
    required this.subtotalAfterVoucher,
    required this.lokasiDeliveryNama,
    this.deliveryRemarks,
    this.remarks,
    this.confirmedAt,
    this.expiredAt,
    required this.createdAt,
    this.estimatedDeliveryAt,
    required this.items,
  });

  factory TrackingCart.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = (json['items'] as List?) ?? [];
    return TrackingCart(
      id: (json['id'] ?? '').toString(),
      anggotaId: (json['p_anggota_id'] ?? 0) as int,
      status: (json['status'] ?? '').toString(),
      subtotal: (json['subtotal'] ?? 0) is num ? (json['subtotal'] as num).round() : int.tryParse('${json['subtotal'] ?? 0}') ?? 0,
      subtotalAfterVoucher: (json['subtotal_after_voucher'] ?? 0) is num ? (json['subtotal_after_voucher'] as num).round() : int.tryParse('${json['subtotal_after_voucher'] ?? 0}') ?? 0,
      lokasiDeliveryNama: (json['lokasi_delivery_nama'] ?? '').toString(),
      deliveryRemarks: json['delivery_remarks']?.toString(),
      remarks: json['remarks']?.toString(),
      confirmedAt: json['confirmed_at']?.toString(),
      expiredAt: json['expired_at']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      estimatedDeliveryAt: json['estimated_delivery_at']?.toString(),
      items: itemsJson.map((e) => TrackingItem.fromJson((e as Map).cast<String, dynamic>())).toList(),
    );
  }
}

class PagedTrackingCarts {
  final List<TrackingCart> items;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  PagedTrackingCarts({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory PagedTrackingCarts.fromResponse(Map<String, dynamic> json) {
    final List<dynamic> list = (json['data'] as List?) ?? [];
    final Map<String, dynamic> meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? {};
    return PagedTrackingCarts(
      items: list.map((e) => TrackingCart.fromJson((e as Map).cast<String, dynamic>())).toList(),
      currentPage: meta['current_page'] ?? 1,
      perPage: meta['per_page'] ?? list.length,
      total: meta['total'] ?? list.length,
      lastPage: meta['last_page'] ?? 1,
    );
  }
}
