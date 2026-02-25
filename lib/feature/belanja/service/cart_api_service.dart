import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_model.dart';
import '../models/tracking_cart_model.dart';
import '../models/voucher_model.dart';
import '../models/delivery_location_model.dart';

class CartApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['martBaseUrl'] ?? 'https://kkba-mart.laravel.cloud',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  String? lastErrorMessage;

  Future<Options?> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
  }

  // Get Available Vouchers
  Future<List<VoucherModel>> getVouchers() async {
    try {
      final options = await _getHeaders();
      final response = await _dio.get(
        '/api/vouchers',
        options: options?.copyWith(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((e) => VoucherModel.fromJson(e))
              .toList();
        }
        lastErrorMessage = _extractMessage(data);
      }
      return [];
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      print('Error fetching vouchers: ${lastErrorMessage ?? e}');
      return [];
    }
  }

  // Get Delivery Locations
  Future<List<DeliveryLocationModel>> getDeliveryLocations() async {
    try {
      final options = await _getHeaders();
      final response = await _dio.get(
        '/api/delivery/locations',
        options: options?.copyWith(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((e) => DeliveryLocationModel.fromJson(e))
              .toList();
        }
        lastErrorMessage = _extractMessage(data);
      }
      return [];
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      print('Error fetching delivery locations: ${lastErrorMessage ?? e}');
      return [];
    }
  }

  // Get Cart Data
  Future<CartModel?> getCart() async {
    try {
      final options = await _getHeaders();
      final response = await _dio.get(
        '/api/cart',
        options: options?.copyWith(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          return CartModel.fromJson(data['data']);
        }
        lastErrorMessage = _extractMessage(data);
      }
      return null;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      print('Error fetching cart: ${lastErrorMessage ?? e}');
      return null;
    }
  }

  // Add Item to Cart
  Future<bool> addToCart(
    String productId,
    int quantity, {
    String remarks = '',
  }) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/items',
        data: {
          'produk_item_id': productId,
          'qty': quantity,
          'remarks': remarks,
        },
        options: options?.copyWith(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return true;
      }
      lastErrorMessage = _extractMessage(response.data);
      return false;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      print('Error adding to cart: ${lastErrorMessage ?? e}');
      return false;
    }
  }

  // Update Item Quantity
  Future<bool> updateQuantity(String productId, int quantity) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/items/update',
        data: {'produk_item_id': productId, 'qty': quantity},
        options: options?.copyWith(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return true;
      }
      lastErrorMessage = _extractMessage(response.data);
      return false;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      print('Error updating cart: ${lastErrorMessage ?? e}');
      return false;
    }
  }

  // Remove Item
  Future<bool> removeItem(String productId) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/items/remove',
        data: {'produk_item_id': productId},
        options: options?.copyWith(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return true;
      }
      lastErrorMessage = _extractMessage(response.data);
      return false;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      print('Error removing item: ${lastErrorMessage ?? e}');
      return false;
    }
  }

  // Apply Voucher
  Future<bool> applyVoucher(String code) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/voucher/apply',
        data: {'kode_voucher': code},
        options: options?.copyWith(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return true;
      }
      lastErrorMessage = _extractMessage(response.data);
      return false;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      print('Error applying voucher: ${lastErrorMessage ?? e}');
      return false;
    }
  }

  // Remove Voucher
  Future<bool> removeVoucher() async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/voucher/remove',
        options: options?.copyWith(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return true;
      }
      lastErrorMessage = _extractMessage(response.data);
      return false;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      print('Error removing voucher: ${lastErrorMessage ?? e}');
      return false;
    }
  }

  // Submit/Checkout
  Future<bool> checkout() async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/checkout',
        options: options?.copyWith(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return true;
      }
      lastErrorMessage = _extractMessage(response.data);
      return false;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      print('Error checking out: ${lastErrorMessage ?? e}');
      return false;
    }
  }

  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    try {
      if (data is Map<String, dynamic>) {
        if (data['message'] is String) return data['message'] as String;
        if (data['error'] is String) return data['error'] as String;
        if (data['errors'] is Map) {
          final errs = data['errors'] as Map;
          if (errs.isNotEmpty) {
            final firstKey = errs.keys.first;
            final val = errs[firstKey];
            if (val is List && val.isNotEmpty) return val.first.toString();
            return val.toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> submitCart({
    required int lokasiDeliveryId,
    required String deliveryRemarks,
  }) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/submit',
        data: {
          'lokasi_delivery_id': lokasiDeliveryId,
          'delivery_remarks': deliveryRemarks,
        },
        options: options?.copyWith(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return true;
      }
      lastErrorMessage = _extractMessage(response.data);
      return false;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return false;
    }
  }

  Future<PagedTrackingCarts> getWaitingAdminCarts({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/waiting-admin',
        data: {'page': page, 'per_page': perPage},
        options: options?.copyWith(validateStatus: (s) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return PagedTrackingCarts.fromResponse(
          response.data as Map<String, dynamic>,
        );
      }
      return PagedTrackingCarts(
        items: const [],
        currentPage: page,
        perPage: perPage,
        total: 0,
        lastPage: 0,
      );
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return PagedTrackingCarts(
        items: const [],
        currentPage: page,
        perPage: perPage,
        total: 0,
        lastPage: 0,
      );
    }
  }

  Future<PagedTrackingCarts> getConfirmedCarts({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/confirmed',
        data: {'page': page, 'per_page': perPage},
        options: options?.copyWith(validateStatus: (s) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return PagedTrackingCarts.fromResponse(
          response.data as Map<String, dynamic>,
        );
      }
      return PagedTrackingCarts(
        items: const [],
        currentPage: page,
        perPage: perPage,
        total: 0,
        lastPage: 0,
      );
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return PagedTrackingCarts(
        items: const [],
        currentPage: page,
        perPage: perPage,
        total: 0,
        lastPage: 0,
      );
    }
  }

  Future<PagedTrackingCarts> getCancelledCarts({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/canceled',
        data: {'page': page, 'per_page': perPage},
        options: options?.copyWith(validateStatus: (s) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return PagedTrackingCarts.fromResponse(
          response.data as Map<String, dynamic>,
        );
      }
      return PagedTrackingCarts(
        items: const [],
        currentPage: page,
        perPage: perPage,
        total: 0,
        lastPage: 0,
      );
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return PagedTrackingCarts(
        items: const [],
        currentPage: page,
        perPage: perPage,
        total: 0,
        lastPage: 0,
      );
    }
  }

  Future<PagedTrackingCarts> getDeliveryStatusCarts({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/delivery',
        data: {'page': page, 'per_page': perPage},
        options: options?.copyWith(validateStatus: (s) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return PagedTrackingCarts.fromResponse(
          response.data as Map<String, dynamic>,
        );
      }
      return PagedTrackingCarts(
        items: const [],
        currentPage: page,
        perPage: perPage,
        total: 0,
        lastPage: 0,
      );
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return PagedTrackingCarts(
        items: const [],
        currentPage: page,
        perPage: perPage,
        total: 0,
        lastPage: 0,
      );
    }
  }

  Future<PagedTrackingCarts> getHistoryCarts({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/history',
        data: {'page': page, 'per_page': perPage},
        options: options?.copyWith(validateStatus: (s) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return PagedTrackingCarts.fromResponse(
          response.data as Map<String, dynamic>,
        );
      }
      return PagedTrackingCarts(
        items: const [],
        currentPage: page,
        perPage: perPage,
        total: 0,
        lastPage: 0,
      );
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return PagedTrackingCarts(
        items: const [],
        currentPage: page,
        perPage: perPage,
        total: 0,
        lastPage: 0,
      );
    }
  }

  Future<Map<String, dynamic>?> payCart({
    required String cartMobileId,
    required int metodePembayaranId,
    String notePembayaran = '',
  }) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/pay',
        data: {
          'cart_mobile_id': cartMobileId,
          'metode_pembayaran_id': metodePembayaranId,
          'note_pembayaran': notePembayaran,
        },
        options: options?.copyWith(validateStatus: (s) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final Map<String, dynamic> body =
            (response.data as Map<String, dynamic>);
        if (body['status'] == true) {
          return body['data'] as Map<String, dynamic>?;
        }
        lastErrorMessage = _extractMessage(body) ?? 'Pembayaran gagal';
        return null;
      }
      lastErrorMessage = 'Pembayaran gagal (${response.statusCode})';
      return null;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return null;
    }
  }

  Future<bool> cancelSubmitted({
    required String cartMobileId,
    required String cancelNote,
  }) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/cancel-submitted',
        data: {'cart_mobile_id': cartMobileId, 'cancel_note': cancelNote},
        options: options?.copyWith(validateStatus: (s) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final Map<String, dynamic> body =
            (response.data as Map<String, dynamic>);
        if (body['status'] == true) return true;
        lastErrorMessage = _extractMessage(body) ?? 'Gagal membatalkan cart';
        return false;
      }
      lastErrorMessage = 'Gagal membatalkan cart (${response.statusCode})';
      return false;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return false;
    }
  }

  Future<bool> resetPayment({required String cartMobileId}) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/reset-payment',
        data: {'cart_mobile_id': cartMobileId},
        options: options?.copyWith(validateStatus: (s) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final Map<String, dynamic> body =
            (response.data as Map<String, dynamic>);
        if (body['status'] == true) return true;
        lastErrorMessage = _extractMessage(body) ?? 'Gagal reset pembayaran';
        return false;
      }
      lastErrorMessage = 'Gagal reset pembayaran (${response.statusCode})';
      return false;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return false;
    }
  }

  Future<CartModel?> getCartDetail(String cartId) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.get(
        '/api/cart/$cartId',
        options: options?.copyWith(validateStatus: (s) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final Map<String, dynamic> body = response.data as Map<String, dynamic>;
        final Map<String, dynamic> data =
            (body['data'] as Map?)?.cast<String, dynamic>() ?? body;
        return CartModel.fromJson(data);
      }
      lastErrorMessage = 'Gagal mengambil detail cart (${response.statusCode})';
      return null;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTongjiBalance() async {
    try {
      final options = await _getHeaders();
      final response = await _dio.get(
        '/api/tongji/balance',
        options: options?.copyWith(validateStatus: (s) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final Map<String, dynamic> body = response.data as Map<String, dynamic>;
        final Map<String, dynamic>? data =
            (body['data'] as Map?)?.cast<String, dynamic>();
        return data;
      }
      lastErrorMessage =
          'Gagal mengambil saldo Tongji (${response.statusCode})';
      return null;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return null;
    }
  }

  Future<bool> markDelivered({required String cartId}) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/delivery/mark-delivered',
        data: {'cart_id': cartId},
        options: options?.copyWith(validateStatus: (s) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final Map<String, dynamic> body = response.data as Map<String, dynamic>;
        if (body['status'] == true) return true;
        lastErrorMessage =
            _extractMessage(body) ?? 'Gagal menandai pesanan diterima';
        return false;
      }
      lastErrorMessage =
          'Gagal menandai pesanan diterima (${response.statusCode})';
      return false;
    } on DioException catch (e) {
      lastErrorMessage = _extractMessage(e.response?.data) ?? e.message;
      return false;
    }
  }
}
