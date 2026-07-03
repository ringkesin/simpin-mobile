import 'cart_item.dart';

/// Status cart yang mungkin
enum CartStatus {
  waitingAdmin('waiting_admin'),
  confirmed('confirmed'),
  cancelled('cancelled'),
  onDelivery('on_delivery'),
  completed('completed');

  final String value;
  const CartStatus(this.value);

  static CartStatus fromString(String value) {
    return CartStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CartStatus.waitingAdmin,
    );
  }

  /// Label yang好看 untuk ditampilkan ke user
  String get label {
    switch (this) {
      case CartStatus.waitingAdmin:
        return 'Menunggu Konfirmasi';
      case CartStatus.confirmed:
        return 'Dikonfirmasi';
      case CartStatus.cancelled:
        return 'Dibatalkan';
      case CartStatus.onDelivery:
        return 'Sedang Dikirim';
      case CartStatus.completed:
        return 'Selesai';
    }
  }
}

/// Entity untuk Tracking Cart (domain layer)
/// Represents the domain model for a shopping cart tracking
class TrackingCartEntity {
  final String id;
  final int anggotaId;
  final CartStatus status;
  final int subtotal;
  final int subtotalAfterVoucher;
  final String lokasiDeliveryNama;
  final String? deliveryRemarks;
  final String? remarks;
  final String? confirmedAt;
  final String? expiredAt;
  final String createdAt;
  final String? estimatedDeliveryAt;
  final List<CartItem> items;

  const TrackingCartEntity({
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

  /// Helper untuk cek apakah cart bisa dibatalkan
  bool get canCancel =>
      status == CartStatus.waitingAdmin || status == CartStatus.confirmed;

  /// Helper untuk cek apakah cart bisa dibayar
  bool get canPay => status == CartStatus.confirmed;

  /// Helper untuk cek apakah sudah selesai
  bool get isCompleted =>
      status == CartStatus.completed || status == CartStatus.cancelled;

  /// Total item count
  int get totalItems => items.fold(0, (sum, item) => sum + item.qty);
}
