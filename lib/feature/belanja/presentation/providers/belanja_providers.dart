import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/belanja_repository_impl.dart';
import '../../domain/entities/tracking_cart.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/repositories/belanja_repository.dart';
import '../../domain/usecases/cancel_cart.dart';
import '../../domain/usecases/get_confirmed_carts.dart';
import '../../domain/usecases/get_delivery_carts.dart';
import '../../domain/usecases/get_history_carts.dart';
import '../../domain/usecases/get_tongji_balance.dart';
import '../../domain/usecases/get_waiting_carts.dart';
import '../../domain/usecases/get_cancelled_carts.dart';
import '../../domain/usecases/mark_delivered.dart';
import '../../domain/usecases/pay_cart.dart';
import '../../domain/usecases/reset_payment.dart';
import '../../domain/usecases/get_cart.dart';
import '../../domain/usecases/add_to_cart.dart';
import '../../domain/usecases/update_cart_quantity.dart';
import '../../domain/usecases/remove_cart_item.dart';

// ============== Repository Provider ==============

/// Provider untuk repository
/// Menggunakan ref.watch agar bisa auto-rebuild saat dependency berubah
final belanjaRepositoryProvider = Provider<BelanjaRepository>((ref) {
  return BelanjaRepositoryImpl();
});

// ============== Use Case Providers ==============

final getWaitingCartsUseCaseProvider = Provider<GetWaitingCarts>((ref) {
  return GetWaitingCarts(ref.watch(belanjaRepositoryProvider));
});

final getConfirmedCartsUseCaseProvider = Provider<GetConfirmedCarts>((ref) {
  return GetConfirmedCarts(ref.watch(belanjaRepositoryProvider));
});

final getCancelledCartsUseCaseProvider = Provider<GetCancelledCarts>((ref) {
  return GetCancelledCarts(ref.watch(belanjaRepositoryProvider));
});

final getDeliveryCartsUseCaseProvider = Provider<GetDeliveryCarts>((ref) {
  return GetDeliveryCarts(ref.watch(belanjaRepositoryProvider));
});

final getHistoryCartsUseCaseProvider = Provider<GetHistoryCarts>((ref) {
  return GetHistoryCarts(ref.watch(belanjaRepositoryProvider));
});

final payCartUseCaseProvider = Provider<PayCart>((ref) {
  return PayCart(ref.watch(belanjaRepositoryProvider));
});

final cancelCartUseCaseProvider = Provider<CancelCart>((ref) {
  return CancelCart(ref.watch(belanjaRepositoryProvider));
});

final markDeliveredUseCaseProvider = Provider<MarkDelivered>((ref) {
  return MarkDelivered(ref.watch(belanjaRepositoryProvider));
});

final getTongjiBalanceUseCaseProvider = Provider<GetTongjiBalance>((ref) {
  return GetTongjiBalance(ref.watch(belanjaRepositoryProvider));
});

final resetPaymentUseCaseProvider = Provider<ResetPayment>((ref) {
  return ResetPayment(ref.watch(belanjaRepositoryProvider));
});

final getCartUseCaseProvider = Provider<GetCart>((ref) {
  return GetCart(ref.watch(belanjaRepositoryProvider));
});

final addToCartUseCaseProvider = Provider<AddToCart>((ref) {
  return AddToCart(ref.watch(belanjaRepositoryProvider));
});

final updateCartQuantityUseCaseProvider = Provider<UpdateCartQuantity>((ref) {
  return UpdateCartQuantity(ref.watch(belanjaRepositoryProvider));
});

final removeCartItemUseCaseProvider = Provider<RemoveCartItem>((ref) {
  return RemoveCartItem(ref.watch(belanjaRepositoryProvider));
});

// ============== State Classes ==============

/// State untuk tracking carts per tab
class TrackingCartsState {
  final List<TrackingCartEntity> carts;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int lastPage;

  const TrackingCartsState({
    this.carts = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  TrackingCartsState copyWith({
    List<TrackingCartEntity>? carts,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? lastPage,
  }) {
    return TrackingCartsState(
      carts: carts ?? this.carts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
    );
  }

  bool get hasMore => currentPage < lastPage;
}

// ============== Tab Index Provider ==============

/// Current tab index
final belanjaTabIndexProvider = StateProvider<int>((ref) => 0);

// ============== Cart State and Notifier ==============

/// State untuk cart
class CartState {
  final CartEntity? cart;
  final bool isLoading;
  final String? error;

  const CartState({this.cart, this.isLoading = false, this.error});

  CartState copyWith({CartEntity? cart, bool? isLoading, String? error}) {
    return CartState(
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Helper untuk optimistic update: menambah quantity pada produk tertentu
  CartState copyWithOptimisticAdd({
    required String productId,
    required int quantity,
  }) {
    if (cart == null) return this;

    final updatedItems =
        cart!.items.map((item) {
          if (item.productId == productId) {
            return CartItemEntity(
              id: item.id,
              productId: item.productId,
              productName: item.productName,
              productImageUrl: item.productImageUrl,
              quantity: item.quantity + quantity,
              price: item.price,
              totalPrice: item.totalPrice + (item.price * quantity),
              remarks: item.remarks,
            );
          }
          return item;
        }).toList();

    // Jika item belum ada di cart, kita tidak bisa optimistic update fullnya (karena belum punya semua data),
    // jadi kita tetap load ulang cart setelah API berhasil
    // Tapi untuk sekarang, kita return cart yang sama

    return CartState(
      cart: CartEntity(
        items: updatedItems,
        summary: cart!.summary,
        lokasiDeliveryNama: cart!.lokasiDeliveryNama,
        deliveryPicName: cart!.deliveryPicName,
        deliveryPicPhone: cart!.deliveryPicPhone,
        deliveryRemarks: cart!.deliveryRemarks,
        estimatedDeliveryAt: cart!.estimatedDeliveryAt,
      ),
      isLoading: isLoading,
      error: error,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final GetCart _getCart;
  final AddToCart _addToCart;
  final UpdateCartQuantity _updateQuantity;
  final RemoveCartItem _removeItem;

  CartNotifier(
    this._getCart,
    this._addToCart,
    this._updateQuantity,
    this._removeItem,
  ) : super(const CartState());

  Future<void> fetchCart() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCart();

    if (result.isSuccess) {
      state = state.copyWith(cart: result.data, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<void> addItem({
    required String productId,
    required int quantity,
    String remarks = '',
  }) async {
    // Optimistic update
    if (state.cart != null) {
      state = state.copyWithOptimisticAdd(
        productId: productId,
        quantity: quantity,
      );
    }

    final result = await _addToCart(
      productId: productId,
      quantity: quantity,
      remarks: remarks,
    );

    if (result.isSuccess) {
      // Refresh cart untuk mendapatkan data terbaru
      await fetchCart();
    } else {
      // Jika gagal, refresh cart untuk mengembalikan state yang benar
      await fetchCart();
    }
  }

  Future<void> updateQuantity({
    required String productId,
    required int quantity,
  }) async {
    final oldCart = state.cart;

    // Optimistic update
    if (oldCart != null) {
      final updatedItems =
          oldCart.items.map((item) {
            if (item.productId == productId) {
              return CartItemEntity(
                id: item.id,
                productId: item.productId,
                productName: item.productName,
                productImageUrl: item.productImageUrl,
                quantity: quantity,
                price: item.price,
                totalPrice: item.price * quantity,
                remarks: item.remarks,
              );
            }
            return item;
          }).toList();

      state = state.copyWith(
        cart: CartEntity(
          items: updatedItems,
          summary: oldCart.summary,
          lokasiDeliveryNama: oldCart.lokasiDeliveryNama,
          deliveryPicName: oldCart.deliveryPicName,
          deliveryPicPhone: oldCart.deliveryPicPhone,
          deliveryRemarks: oldCart.deliveryRemarks,
          estimatedDeliveryAt: oldCart.estimatedDeliveryAt,
        ),
      );
    }

    final result = await _updateQuantity(
      productId: productId,
      quantity: quantity,
    );

    if (!result.isSuccess) {
      // Jika gagal, refresh cart
      await fetchCart();
    }
  }

  Future<void> removeItem({required String productId}) async {
    final oldCart = state.cart;

    // Optimistic update
    if (oldCart != null) {
      final updatedItems =
          oldCart.items.where((item) => item.productId != productId).toList();

      state = state.copyWith(
        cart: CartEntity(
          items: updatedItems,
          summary: oldCart.summary,
          lokasiDeliveryNama: oldCart.lokasiDeliveryNama,
          deliveryPicName: oldCart.deliveryPicName,
          deliveryPicPhone: oldCart.deliveryPicPhone,
          deliveryRemarks: oldCart.deliveryRemarks,
          estimatedDeliveryAt: oldCart.estimatedDeliveryAt,
        ),
      );
    }

    final result = await _removeItem(productId: productId);

    if (!result.isSuccess) {
      // Jika gagal, refresh cart
      await fetchCart();
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(
    ref.watch(getCartUseCaseProvider),
    ref.watch(addToCartUseCaseProvider),
    ref.watch(updateCartQuantityUseCaseProvider),
    ref.watch(removeCartItemUseCaseProvider),
  );
});

// ============== Cart State Notifiers ==============

/// StateNotifier untuk Waiting Carts
class WaitingCartsNotifier extends StateNotifier<TrackingCartsState> {
  final GetWaitingCarts _getWaitingCarts;

  WaitingCartsNotifier(this._getWaitingCarts)
    : super(const TrackingCartsState());

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getWaitingCarts(page: page, perPage: 10);

    if (result.isSuccess) {
      final carts = result.data ?? [];
      state = state.copyWith(
        carts: refresh ? carts : [...state.carts, ...carts],
        isLoading: false,
        currentPage: page + 1,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  void removeCart(String cartId) {
    state = state.copyWith(
      carts: state.carts.where((c) => c.id != cartId).toList(),
    );
  }

  Future<void> refresh() => fetch(refresh: true);
}

/// StateNotifier untuk Confirmed Carts
class ConfirmedCartsNotifier extends StateNotifier<TrackingCartsState> {
  final GetConfirmedCarts _getConfirmedCarts;

  ConfirmedCartsNotifier(this._getConfirmedCarts)
    : super(const TrackingCartsState());

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getConfirmedCarts(page: page, perPage: 10);

    if (result.isSuccess) {
      final carts = result.data ?? [];
      state = state.copyWith(
        carts: refresh ? carts : [...state.carts, ...carts],
        isLoading: false,
        currentPage: page + 1,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  void removeCart(String cartId) {
    state = state.copyWith(
      carts: state.carts.where((c) => c.id != cartId).toList(),
    );
  }

  Future<void> refresh() => fetch(refresh: true);
}

/// StateNotifier untuk Cancelled Carts
class CancelledCartsNotifier extends StateNotifier<TrackingCartsState> {
  final GetCancelledCarts _getCancelledCarts;

  CancelledCartsNotifier(this._getCancelledCarts)
    : super(const TrackingCartsState());

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCancelledCarts(page: page, perPage: 10);

    if (result.isSuccess) {
      final carts = result.data ?? [];
      state = state.copyWith(
        carts: refresh ? carts : [...state.carts, ...carts],
        isLoading: false,
        currentPage: page + 1,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<void> refresh() => fetch(refresh: true);
}

/// StateNotifier untuk Delivery Carts
class DeliveryCartsNotifier extends StateNotifier<TrackingCartsState> {
  final GetDeliveryCarts _getDeliveryCarts;

  DeliveryCartsNotifier(this._getDeliveryCarts)
    : super(const TrackingCartsState());

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getDeliveryCarts(page: page, perPage: 10);

    if (result.isSuccess) {
      final carts = result.data ?? [];
      state = state.copyWith(
        carts: refresh ? carts : [...state.carts, ...carts],
        isLoading: false,
        currentPage: page + 1,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  void removeCart(String cartId) {
    state = state.copyWith(
      carts: state.carts.where((c) => c.id != cartId).toList(),
    );
  }

  Future<void> refresh() => fetch(refresh: true);
}

/// StateNotifier untuk History Carts
class HistoryCartsNotifier extends StateNotifier<TrackingCartsState> {
  final GetHistoryCarts _getHistoryCarts;

  HistoryCartsNotifier(this._getHistoryCarts)
    : super(const TrackingCartsState());

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getHistoryCarts(page: page, perPage: 10);

    if (result.isSuccess) {
      final carts = result.data ?? [];
      state = state.copyWith(
        carts: refresh ? carts : [...state.carts, ...carts],
        isLoading: false,
        currentPage: page + 1,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<void> refresh() => fetch(refresh: true);
}

// ============== Cart State Notifier Providers ==============

final waitingCartsProvider =
    StateNotifierProvider<WaitingCartsNotifier, TrackingCartsState>((ref) {
      return WaitingCartsNotifier(ref.watch(getWaitingCartsUseCaseProvider));
    });

final confirmedCartsProvider =
    StateNotifierProvider<ConfirmedCartsNotifier, TrackingCartsState>((ref) {
      return ConfirmedCartsNotifier(
        ref.watch(getConfirmedCartsUseCaseProvider),
      );
    });

final cancelledCartsProvider =
    StateNotifierProvider<CancelledCartsNotifier, TrackingCartsState>((ref) {
      return CancelledCartsNotifier(
        ref.watch(getCancelledCartsUseCaseProvider),
      );
    });

final deliveryCartsProvider =
    StateNotifierProvider<DeliveryCartsNotifier, TrackingCartsState>((ref) {
      return DeliveryCartsNotifier(ref.watch(getDeliveryCartsUseCaseProvider));
    });

final historyCartsProvider =
    StateNotifierProvider<HistoryCartsNotifier, TrackingCartsState>((ref) {
      return HistoryCartsNotifier(ref.watch(getHistoryCartsUseCaseProvider));
    });

// ============== Tongji Balance Provider ==============

final tongjiBalanceProvider = FutureProvider<int>((ref) async {
  final result = await ref.watch(getTongjiBalanceUseCaseProvider).call();
  return result.data ?? 0;
});

// ============== Action Providers (Pay, Cancel, Mark Delivered) ==============

/// Provider untuk cached Snap URLs (untuk retry payment)
final snapRedirectCacheProvider = StateProvider<Map<String, String>>(
  (ref) => {},
);

/// Pay cart action
Future<PayData?> payCart({
  required WidgetRef ref,
  required String cartId,
  required int metodePembayaranId,
}) async {
  final payCartUseCase = ref.read(payCartUseCaseProvider);
  final resetPaymentUseCase = ref.read(resetPaymentUseCaseProvider);
  final snapCache = ref.read(snapRedirectCacheProvider);

  // Check if we have cached redirect URL
  if (metodePembayaranId == 6 && snapCache.containsKey(cartId)) {
    final cachedUrl = snapCache[cartId]!;
    return PayData(redirectUrl: cachedUrl);
  }

  final result = await payCartUseCase(
    cartMobileId: cartId,
    metodePembayaranId: metodePembayaranId,
  );

  if (result.isSuccess && result.data != null) {
    // Cache the redirect URL if available
    if (result.data!.hasRedirectUrl) {
      final newCache = Map<String, String>.from(snapCache);
      newCache[cartId] = result.data!.redirectUrl!;
      ref.read(snapRedirectCacheProvider.notifier).state = newCache;
    }
    return result.data;
  }

  // Retry logic if order_id already used
  if (metodePembayaranId == 6) {
    final errorMsg = (result.error ?? '').toLowerCase();
    if (errorMsg.contains('order_id') && errorMsg.contains('digunakan')) {
      final resetResult = await resetPaymentUseCase(cartMobileId: cartId);
      if (resetResult.isSuccess) {
        // Clear cache and retry
        final newCache = Map<String, String>.from(snapCache);
        newCache.remove(cartId);
        ref.read(snapRedirectCacheProvider.notifier).state = newCache;

        final retryResult = await payCartUseCase(
          cartMobileId: cartId,
          metodePembayaranId: metodePembayaranId,
        );
        if (retryResult.isSuccess && retryResult.data != null) {
          return retryResult.data;
        }
      }
    }
  }

  return null;
}

/// Cancel cart action
Future<bool> cancelCart({
  required WidgetRef ref,
  required String cartId,
  required String alasan,
}) async {
  final cancelCartUseCase = ref.read(cancelCartUseCaseProvider);
  final result = await cancelCartUseCase(cartMobileId: cartId, alasan: alasan);
  return result.isSuccess;
}

/// Mark delivered action
Future<bool> markDelivered({
  required WidgetRef ref,
  required String cartId,
}) async {
  final markDeliveredUseCase = ref.read(markDeliveredUseCaseProvider);
  final result = await markDeliveredUseCase(cartMobileId: cartId);
  return result.isSuccess;
}
