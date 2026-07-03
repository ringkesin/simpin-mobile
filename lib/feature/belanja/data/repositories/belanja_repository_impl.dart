import '../../domain/entities/tracking_cart.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/repositories/belanja_repository.dart';
import '../datasources/belanja_remote_datasource.dart';
import '../models/tracking_cart_mapper.dart';

/// Implementasi BelanjaRepository
/// Mengimplementasikan kontrak dari domain layer
class BelanjaRepositoryImpl implements BelanjaRepository {
  final BelanjaRemoteDataSource _remoteDataSource;

  BelanjaRepositoryImpl({BelanjaRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? BelanjaRemoteDataSource();

  @override
  Future<BelanjaResult<CartEntity>> getCart() async {
    try {
      final cartModel = await _remoteDataSource.getCart();
      if (cartModel != null) {
        final cartEntity = CartMapper.fromModel(cartModel);
        return BelanjaResult.success(cartEntity);
      }
      // Return empty cart instead of failure
      final emptyCart = CartEntity(
        items: [],
        summary: const CartSummaryEntity(subtotal: 0, discount: 0, total: 0),
        lokasiDeliveryNama: null,
        deliveryPicName: null,
        deliveryPicPhone: null,
        deliveryRemarks: null,
        estimatedDeliveryAt: null,
      );
      return BelanjaResult.success(emptyCart);
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<bool>> addToCart({
    required String productId,
    required int quantity,
    String remarks = '',
  }) async {
    try {
      final success = await _remoteDataSource.addToCart(
        productId: productId,
        quantity: quantity,
        remarks: remarks,
      );
      if (success) {
        return BelanjaResult.success(true);
      }
      return BelanjaResult.failure(
        _remoteDataSource.lastError ?? 'Gagal menambah item',
      );
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<bool>> updateQuantity({
    required String productId,
    required int quantity,
  }) async {
    try {
      final success = await _remoteDataSource.updateQuantity(
        productId: productId,
        quantity: quantity,
      );
      if (success) {
        return BelanjaResult.success(true);
      }
      return BelanjaResult.failure(
        _remoteDataSource.lastError ?? 'Gagal mengupdate quantity',
      );
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<bool>> removeItem({required String productId}) async {
    try {
      final success = await _remoteDataSource.removeItem(productId: productId);
      if (success) {
        return BelanjaResult.success(true);
      }
      return BelanjaResult.failure(
        _remoteDataSource.lastError ?? 'Gagal menghapus item',
      );
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<List<TrackingCartEntity>>> getWaitingCarts({
    required int page,
    required int perPage,
  }) async {
    try {
      final data = await _remoteDataSource.getWaitingCarts(
        page: page,
        perPage: perPage,
      );
      final carts = data.map((e) => TrackingCartMapper.fromJson(e)).toList();
      return BelanjaResult.success(carts);
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<List<TrackingCartEntity>>> getConfirmedCarts({
    required int page,
    required int perPage,
  }) async {
    try {
      final data = await _remoteDataSource.getConfirmedCarts(
        page: page,
        perPage: perPage,
      );
      final carts = data.map((e) => TrackingCartMapper.fromJson(e)).toList();
      return BelanjaResult.success(carts);
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<List<TrackingCartEntity>>> getCancelledCarts({
    required int page,
    required int perPage,
  }) async {
    try {
      final data = await _remoteDataSource.getCancelledCarts(
        page: page,
        perPage: perPage,
      );
      final carts = data.map((e) => TrackingCartMapper.fromJson(e)).toList();
      return BelanjaResult.success(carts);
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<List<TrackingCartEntity>>> getDeliveryCarts({
    required int page,
    required int perPage,
  }) async {
    try {
      final data = await _remoteDataSource.getDeliveryCarts(
        page: page,
        perPage: perPage,
      );
      final carts = data.map((e) => TrackingCartMapper.fromJson(e)).toList();
      return BelanjaResult.success(carts);
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<List<TrackingCartEntity>>> getHistoryCarts({
    required int page,
    required int perPage,
  }) async {
    try {
      final data = await _remoteDataSource.getHistoryCarts(
        page: page,
        perPage: perPage,
      );
      final carts = data.map((e) => TrackingCartMapper.fromJson(e)).toList();
      return BelanjaResult.success(carts);
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<PayData>> payCart({
    required String cartMobileId,
    required int metodePembayaranId,
  }) async {
    try {
      final data = await _remoteDataSource.payCart(
        cartMobileId: cartMobileId,
        metodePembayaranId: metodePembayaranId,
      );
      if (data != null) {
        return BelanjaResult.success(
          PayData(
            redirectUrl: data['redirect_url']?.toString(),
            snapToken: data['snap_token']?.toString(),
            orderId: data['order_id']?.toString(),
          ),
        );
      }
      return BelanjaResult.failure(
        _remoteDataSource.lastError ?? 'Pembayaran gagal',
      );
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<bool>> cancelCart({
    required String cartMobileId,
    required String alasan,
  }) async {
    try {
      final success = await _remoteDataSource.cancelCart(
        cartMobileId: cartMobileId,
        cancelNote: alasan,
      );
      if (success) {
        return BelanjaResult.success(true);
      }
      return BelanjaResult.failure(
        _remoteDataSource.lastError ?? 'Gagal membatalkan',
      );
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<bool>> markDelivered({
    required String cartMobileId,
  }) async {
    try {
      final success = await _remoteDataSource.markDelivered(
        cartId: cartMobileId,
      );
      if (success) {
        return BelanjaResult.success(true);
      }
      return BelanjaResult.failure(
        _remoteDataSource.lastError ?? 'Gagal menandai diterima',
      );
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<int>> getTongjiBalance() async {
    try {
      final balance = await _remoteDataSource.getTongjiBalance();
      return BelanjaResult.success(balance);
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }

  @override
  Future<BelanjaResult<bool>> resetPayment({
    required String cartMobileId,
  }) async {
    try {
      final success = await _remoteDataSource.resetPayment(
        cartMobileId: cartMobileId,
      );
      if (success) {
        return BelanjaResult.success(true);
      }
      return BelanjaResult.failure(
        _remoteDataSource.lastError ?? 'Gagal reset pembayaran',
      );
    } catch (e) {
      return BelanjaResult.failure(_remoteDataSource.lastError ?? e.toString());
    }
  }
}
