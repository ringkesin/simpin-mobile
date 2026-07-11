import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracking_cart_mapper.dart';
import '../../service/cart_api_service.dart';
import '../../models/cart_model.dart';

/// Data source untuk API calls belanja
/// Bertanggung jawab untuk HTTP requests ke backend
class BelanjaRemoteDataSource {
  final Dio _dio;
  final CartApiService _cartApiService;

  BelanjaRemoteDataSource({Dio? dio, CartApiService? cartApiService})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl:
                  dotenv.env['martBaseUrl'] ??
                  'https://kkba-mart.laravel.cloud',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          ),
      _cartApiService = cartApiService ?? CartApiService();

  String? _lastError;

  String? get lastError => _lastError;

  Future<Options?> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print(
      '--- GET HEADERS --- Token: ${token != null ? 'available' : 'NOT AVAILABLE'}',
    );
    return token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
  }

  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    try {
      if (data is Map<String, dynamic>) {
        if (data['message'] is String) return data['message'] as String;
        if (data['error'] is String) return data['error'] as String;
      }
    } catch (_) {}
    return null;
  }

  /// Get current cart
  Future<CartModel?> getCart() async {
    return await _cartApiService.getCart();
  }

  /// Add item to cart
  Future<bool> addToCart({
    required String productId,
    required int quantity,
    String remarks = '',
  }) async {
    final ok = await _cartApiService.addToCart(
      productId,
      quantity,
      remarks: remarks,
    );
    if (!ok) {
      _lastError = _cartApiService.lastErrorMessage;
    }
    return ok;
  }

  /// Update item quantity
  Future<bool> updateQuantity({
    required String productId,
    required int quantity,
  }) async {
    final ok = await _cartApiService.updateQuantity(productId, quantity);
    if (!ok) {
      _lastError = _cartApiService.lastErrorMessage;
    }
    return ok;
  }

  /// Remove item from cart
  Future<bool> removeItem({required String productId}) async {
    final ok = await _cartApiService.removeItem(productId);
    if (!ok) {
      _lastError = _cartApiService.lastErrorMessage;
    }
    return ok;
  }

  /// Get carts by status
  Future<List<Map<String, dynamic>>> _getCartsByStatus(
    String endpoint, {
    required int page,
    required int perPage,
  }) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        endpoint,
        data: {'page': page, 'per_page': perPage},
        options: options?.copyWith(validateStatus: (status) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true && data['data'] is List) {
          return (data['data'] as List).cast<Map<String, dynamic>>();
        }
        _lastError = _extractMessage(data);
      }
      return [];
    } on DioException catch (e) {
      _lastError = _extractMessage(e.response?.data) ?? e.message;
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWaitingCarts({
    required int page,
    required int perPage,
  }) {
    return _getCartsByStatus(
      '/api/cart/waiting-admin',
      page: page,
      perPage: perPage,
    );
  }

  Future<List<Map<String, dynamic>>> getConfirmedCarts({
    required int page,
    required int perPage,
  }) {
    return _getCartsByStatus(
      '/api/cart/confirmed',
      page: page,
      perPage: perPage,
    );
  }

  Future<List<Map<String, dynamic>>> getCancelledCarts({
    required int page,
    required int perPage,
  }) {
    return _getCartsByStatus(
      '/api/cart/canceled',
      page: page,
      perPage: perPage,
    );
  }

  Future<List<Map<String, dynamic>>> getDeliveryCarts({
    required int page,
    required int perPage,
  }) {
    return _getCartsByStatus(
      '/api/cart/delivery',
      page: page,
      perPage: perPage,
    );
  }

  Future<List<Map<String, dynamic>>> getHistoryCarts({
    required int page,
    required int perPage,
  }) {
    return _getCartsByStatus('/api/cart/history', page: page, perPage: perPage);
  }

  /// Pay cart
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
        options: options?.copyWith(validateStatus: (status) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final body = response.data as Map<String, dynamic>;
        if (body['status'] == true) {
          return body['data'] as Map<String, dynamic>?;
        }
        _lastError = _extractMessage(body) ?? 'Pembayaran gagal';
        return null;
      }
      _lastError = 'Pembayaran gagal (${response.statusCode})';
      return null;
    } on DioException catch (e) {
      _lastError = _extractMessage(e.response?.data) ?? e.message;
      return null;
    }
  }

  /// Cancel cart
  Future<bool> cancelCart({
    required String cartMobileId,
    required String cancelNote,
  }) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/cancel-submitted',
        data: {'cart_mobile_id': cartMobileId, 'cancel_note': cancelNote},
        options: options?.copyWith(validateStatus: (status) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final body = response.data as Map<String, dynamic>;
        if (body['status'] == true) return true;
        _lastError = _extractMessage(body) ?? 'Gagal membatalkan cart';
        return false;
      }
      _lastError = 'Gagal membatalkan cart (${response.statusCode})';
      return false;
    } on DioException catch (e) {
      _lastError = _extractMessage(e.response?.data) ?? e.message;
      return false;
    }
  }

  /// Reset payment
  Future<bool> resetPayment({required String cartMobileId}) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/reset-payment',
        data: {'cart_mobile_id': cartMobileId},
        options: options?.copyWith(validateStatus: (status) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final body = response.data as Map<String, dynamic>;
        if (body['status'] == true) return true;
        _lastError = _extractMessage(body) ?? 'Gagal reset pembayaran';
        return false;
      }
      _lastError = 'Gagal reset pembayaran (${response.statusCode})';
      return false;
    } on DioException catch (e) {
      _lastError = _extractMessage(e.response?.data) ?? e.message;
      return false;
    }
  }

  /// Mark delivered
  Future<bool> markDelivered({required String cartId}) async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/delivery/mark-delivered',
        data: {'cart_id': cartId},
        options: options?.copyWith(validateStatus: (status) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final body = response.data as Map<String, dynamic>;
        if (body['status'] == true) return true;
        _lastError = _extractMessage(body) ?? 'Gagal menandai diterima';
        return false;
      }
      return false;
    } on DioException catch (e) {
      _lastError = _extractMessage(e.response?.data) ?? e.message;
      return false;
    }
  }

  /// Get Tongji balance
  Future<int> getTongjiBalance() async {
    try {
      final options = await _getHeaders();
      final response = await _dio.get(
        '/api/tongji/balance',
        options: options?.copyWith(validateStatus: (status) => true),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final body = response.data as Map<String, dynamic>;
        final data = (body['data'] as Map?)?.cast<String, dynamic>();
        if (data != null) {
          final rawValue =
              data['remaining_amount'] ?? data['limit_amount'] ?? data['limit'];
          return int.tryParse(rawValue?.toString() ?? '') ?? 0;
        }
      }
      return 0;
    } on DioException catch (e) {
      _lastError = _extractMessage(e.response?.data) ?? e.message;
      return 0;
    }
  }
}
