import '../entities/tracking_cart.dart';
import '../entities/cart_entity.dart';

/// Repository interface untuk belanja
/// Kontrak yang harus dipenuhi oleh implementasi (data layer)
/// Ini adalah SOLID principle - Dependency Inversion
abstract class BelanjaRepository {
  /// Get current active cart
  Future<BelanjaResult<CartEntity>> getCart();

  /// Add item to cart
  Future<BelanjaResult<bool>> addToCart({
    required String productId,
    required int quantity,
    String remarks = '',
  });

  /// Update item quantity in cart
  Future<BelanjaResult<bool>> updateQuantity({
    required String productId,
    required int quantity,
  });

  /// Remove item from cart
  Future<BelanjaResult<bool>> removeItem({
    required String productId,
  });

  /// Get carts dengan status waiting_admin
  Future<BelanjaResult<List<TrackingCartEntity>>> getWaitingCarts({
    required int page,
    required int perPage,
  });

  /// Get carts dengan status confirmed
  Future<BelanjaResult<List<TrackingCartEntity>>> getConfirmedCarts({
    required int page,
    required int perPage,
  });

  /// Get carts dengan status cancelled
  Future<BelanjaResult<List<TrackingCartEntity>>> getCancelledCarts({
    required int page,
    required int perPage,
  });

  /// Get carts dengan status on_delivery
  Future<BelanjaResult<List<TrackingCartEntity>>> getDeliveryCarts({
    required int page,
    required int perPage,
  });

  /// Get semua carts (history)
  Future<BelanjaResult<List<TrackingCartEntity>>> getHistoryCarts({
    required int page,
    required int perPage,
  });

  /// Bayar cart
  Future<BelanjaResult<PayData>> payCart({
    required String cartMobileId,
    required int metodePembayaranId,
  });

  /// Cancel cart dengan alasan
  Future<BelanjaResult<bool>> cancelCart({
    required String cartMobileId,
    required String alasan,
  });

  /// Mark sebagai delivered
  Future<BelanjaResult<bool>> markDelivered({
    required String cartMobileId,
  });

  /// Get Tongji balance
  Future<BelanjaResult<int>> getTongjiBalance();

  /// Reset payment (jika order_id sudah dipakai)
  Future<BelanjaResult<bool>> resetPayment({
    required String cartMobileId,
  });
}

/// Result wrapper yang bisa Success atau Failure
/// Menggantikan exception-based error handling
class BelanjaResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const BelanjaResult._({this.data, this.error, required this.isSuccess});

  factory BelanjaResult.success(T data) =>
      BelanjaResult._(data: data, isSuccess: true);

  factory BelanjaResult.failure(String error) =>
      BelanjaResult._(error: error, isSuccess: false);
}

/// Data untuk payment
class PayData {
  final String? redirectUrl;
  final String? snapToken;
  final String? orderId;

  const PayData({this.redirectUrl, this.snapToken, this.orderId});

  bool get hasRedirectUrl => redirectUrl != null && redirectUrl!.isNotEmpty;
}
