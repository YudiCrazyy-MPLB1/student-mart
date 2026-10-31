import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../product_model.dart';
import 'api_client.dart';

/// Endpoint manajemen produk, pesanan, dan dashboard untuk role Manager.
class ManagerApi {
  // ============================================================
  // MANAGER DASHBOARD
  // ============================================================

  static Future<Map<String, dynamic>> getManagerDashboard() async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/manager/dashboard',
      requireAuth: true,
      notLoggedInMessage: 'Kamu belum login sebagai manager.',
      fallback: 'Gagal mengambil dashboard manager.',
      timeoutMessage: 'Mengambil dashboard terlalu lama.',
      statusMessages: {403: 'Akses ditolak. Akun ini bukan manager.'},
    );

    return ApiClient.dataMap(json);
  }

  // ============================================================
  // MANAGER PRODUCT
  // ============================================================

  static Future<List<Product>> getManagerProducts() async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/manager/products',
      fallback: 'Gagal mengambil produk manager.',
    );

    return ApiClient.productList(
      ApiClient.dataList(json, invalidMessage: 'Data produk manager tidak valid.'),
    );
  }

  static Future<Product> createManagerProduct({
    required int categoryId,
    required String name,
    String? description,
    required int price,
    required int stock,
    XFile? imageFile,
    bool isActive = true,
  }) async {
    final files = <http.MultipartFile>[];

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: imageFile.name),
      );
    }

    final json = await ApiClient.multipartRequest(
      '/manager/products',
      requireAuth: true,
      notLoggedInMessage: 'Kamu belum login sebagai manager.',
      fallback: 'Gagal menambahkan produk.',
      fields: {
        'category_id': categoryId.toString(),
        'name': name,
        'description': description ?? '',
        'price': price.toString(),
        'stock': stock.toString(),
        'is_active': isActive ? '1' : '0',
      },
      files: files,
    );

    return Product.fromJson(
      ApiClient.requireDataMap(json, 'Response tidak berisi data produk.'),
    );
  }

  static Future<Product> updateManagerProduct({
    required int productId,
    int? categoryId,
    String? name,
    String? description,
    int? price,
    int? stock,
    XFile? imageFile,
    bool? isActive,
  }) async {
    final fields = <String, String>{
      // Laravel method spoofing.
      '_method': 'PUT',
      'category_id': ?categoryId?.toString(),
      'name': ?name,
      'description': ?description,
      'price': ?price?.toString(),
      'stock': ?stock?.toString(),
      if (isActive != null) 'is_active': isActive ? '1' : '0',
    };

    final files = <http.MultipartFile>[];

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: imageFile.name),
      );
    }

    final json = await ApiClient.multipartRequest(
      '/manager/products/$productId',
      requireAuth: true,
      notLoggedInMessage: 'Kamu belum login sebagai manager.',
      fallback: 'Gagal memperbarui produk.',
      fields: fields,
      files: files,
    );

    return Product.fromJson(
      ApiClient.requireDataMap(json, 'Response tidak berisi data produk.'),
    );
  }

  static Future<Product> deactivateManagerProduct(int productId) async {
    final json = await ApiClient.jsonRequest(
      'DELETE',
      '/manager/products/$productId',
      fallback: 'Gagal menonaktifkan produk.',
    );

    return Product.fromJson(
      ApiClient.requireDataMap(json, 'Response tidak berisi data produk.'),
    );
  }

  static Future<Product> activateManagerProduct(int productId) async {
    final json = await ApiClient.jsonRequest(
      'PATCH',
      '/manager/products/$productId/activate',
      fallback: 'Gagal mengaktifkan produk.',
    );

    return Product.fromJson(
      ApiClient.requireDataMap(json, 'Response tidak berisi data produk.'),
    );
  }

  // ============================================================
  // MANAGER ORDERS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getManagerOrders() async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/manager/orders',
      fallback: 'Gagal mengambil pesanan.',
    );

    return ApiClient.mapList(
      ApiClient.dataList(json, invalidMessage: 'Data pesanan manager tidak valid.'),
    );
  }

  static Future<Map<String, dynamic>> updateManagerOrderStatus({
    required int orderId,
    required String status,
  }) async {
    return ApiClient.jsonRequest(
      'PATCH',
      '/manager/orders/$orderId/status',
      body: {'status': status},
      fallback: 'Gagal mengubah status pesanan.',
    );
  }
}

