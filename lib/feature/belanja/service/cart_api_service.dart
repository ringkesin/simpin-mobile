import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_model.dart';
import '../models/voucher_model.dart';
import '../models/delivery_location_model.dart';

class CartApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://kkba-mart.laravel.cloud',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

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
      final response = await _dio.get('/api/vouchers', options: options);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((e) => VoucherModel.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching vouchers: $e');
      return [];
    }
  }

  // Get Delivery Locations
  Future<List<DeliveryLocationModel>> getDeliveryLocations() async {
    try {
      final options = await _getHeaders();
      final response = await _dio.get(
        '/api/delivery/locations',
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((e) => DeliveryLocationModel.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching delivery locations: $e');
      return [];
    }
  }

  // Get Cart Data
  Future<CartModel?> getCart() async {
    try {
      final options = await _getHeaders();
      final response = await _dio.get('/api/cart', options: options);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          return CartModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching cart: $e');
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
        options: options,
      );

      return response.statusCode == 200 && response.data['status'] == true;
    } catch (e) {
      print('Error adding to cart: $e');
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
        options: options,
      );

      return response.statusCode == 200 && response.data['status'] == true;
    } catch (e) {
      print('Error updating cart: $e');
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
        options: options,
      );

      return response.statusCode == 200 && response.data['status'] == true;
    } catch (e) {
      print('Error removing item: $e');
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
        options: options,
      );

      return response.statusCode == 200 && response.data['status'] == true;
    } catch (e) {
      print('Error applying voucher: $e');
      return false;
    }
  }

  // Remove Voucher
  Future<bool> removeVoucher() async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post(
        '/api/cart/voucher/remove',
        options: options,
      );

      return response.statusCode == 200 && response.data['status'] == true;
    } catch (e) {
      print('Error removing voucher: $e');
      return false;
    }
  }

  // Submit/Checkout
  Future<bool> checkout() async {
    try {
      final options = await _getHeaders();
      final response = await _dio.post('/api/cart/checkout', options: options);

      return response.statusCode == 200 && response.data['status'] == true;
    } catch (e) {
      print('Error checking out: $e');
      return false;
    }
  }
}
