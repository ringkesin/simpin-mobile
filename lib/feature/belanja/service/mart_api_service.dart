import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';

import '../models/section_model.dart';
import '../models/product.dart';
import '../models/paged_products.dart';

class MartApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['martBaseUrl'] ?? 'https://kkba-mart.laravel.cloud',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<BannerModel>> getBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final options =
          token != null
              ? Options(headers: {'Authorization': 'Bearer $token'})
              : null;

      final response = await _dio.get('/api/home/banners', options: options);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> bannerList = data['data'];
          return bannerList.map((e) => BannerModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching banners: $e');
      return [];
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final options =
          token != null
              ? Options(headers: {'Authorization': 'Bearer $token'})
              : null;

      final response = await _dio.get(
        '/api/home/kategori/parents',
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // The user didn't specify the wrapper structure, but usually it's similar.
        // Based on banner response: data['status'] == true && data['data'] != null
        // However, the user provided JSON example is a list of objects directly?
        // "responsenya akan berbentuk seperti dibawah ini ... [{}, {}]"
        // But usually APIs have a wrapper. Let's assume standard wrapper for now, or check if it's a direct list.
        // If the user says "responsenya akan berbentuk seperti dibawah ini", and lists objects, it might be a direct list or inside 'data'.
        // Given the previous endpoint structure, it's likely inside 'data' or similar.
        // Let's assume it follows the same pattern as banners: { status: true, message: ..., data: [...] }
        // If not, I'll have to debug. But for safety, I'll check if data is list or map.

        if (data is Map && data['data'] is List) {
          final List<dynamic> categoryList = data['data'];
          return categoryList.map((e) => CategoryModel.fromJson(e)).toList();
        } else if (data is List) {
          return data.map((e) => CategoryModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<SectionModel>> getSections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final options =
          token != null
              ? Options(headers: {'Authorization': 'Bearer $token'})
              : null;

      final response = await _dio.get('/api/home/sections', options: options);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> sectionList = data['data'];
          return sectionList.map((e) => SectionModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching sections: $e');
      return [];
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'}, validateStatus: (s) => true)
          : Options(validateStatus: (s) => true);

      final response = await _dio.get('/api/product/$id', options: options);

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true && data['data'] is Map) {
          return Product.fromApiJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PagedProducts> getProductsByCategory(String kategoriId, {int page = 1, int perPage = 20}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'}, validateStatus: (s) => true)
          : Options(validateStatus: (s) => true);

      final response = await _dio.post(
        '/api/product/kategori/$kategoriId',
        data: {'page': page, 'per_page': perPage},
        options: options,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return PagedProducts.fromResponse(data);
        }
      }
      return PagedProducts(items: const [], currentPage: page, perPage: perPage, total: 0, lastPage: 0);
    } catch (_) {
      return PagedProducts(items: const [], currentPage: page, perPage: perPage, total: 0, lastPage: 0);
    }
  }

  Future<PagedProducts> searchProducts({
    required String keywords,
    int? brandId,
    int? kategoriId,
    int page = 1,
    int perPage = 50,
    String sortField = 'harga_setelah_diskon_mobile',
    String sortDirection = 'asc',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'}, validateStatus: (s) => true)
          : Options(validateStatus: (s) => true);

      final response = await _dio.post(
        '/api/product/search',
        data: {
          'keywords': keywords,
          'brand_id': brandId,
          'kategori_id': kategoriId,
          'page': page,
          'per_page': perPage,
          'sort_field': sortField,
          'sort_direction': sortDirection,
        },
        options: options,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return PagedProducts.fromResponse(data);
        }
      }
      return PagedProducts(items: const [], currentPage: page, perPage: perPage, total: 0, lastPage: 0);
    } catch (_) {
      return PagedProducts(items: const [], currentPage: page, perPage: perPage, total: 0, lastPage: 0);
    }
  }
}
