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
      requireAuth: true,
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
      requireAuth: true,
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
      requireAuth: true,
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
      requireAuth: true,
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
      requireAuth: true,
      body: {'status': status},
      fallback: 'Gagal mengubah status pesanan.',
    );
  }

  // ============================================================
  // EXPORT & TEMPLATE (EXCEL)
  // ============================================================

  static Future<DownloadedFile> exportOrders({
    String? startDate,
    String? endDate,
    String? status,
    String? paymentMethod,
    String? pickupMethod,
  }) async {
    final query = <String, String>{
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      if (status != null && status.isNotEmpty) 'status': status,
      if (paymentMethod != null && paymentMethod.isNotEmpty)
        'payment_method': paymentMethod,
      if (pickupMethod != null && pickupMethod.isNotEmpty)
        'pickup_method': pickupMethod,
    };

    return ApiClient.downloadFile(
      '/manager/orders/export',
      query: query.isEmpty ? null : query,
      defaultFileName: 'laporan-pesanan.xlsx',
      fallback: 'Gagal mengekspor laporan pesanan.',
    );
  }

  static Future<DownloadedFile> exportProducts({
    int? categoryId,
    String? status,
    String? stockFilter,
    bool? isActive,
  }) async {
    final query = <String, String>{
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (stockFilter != null && stockFilter.isNotEmpty)
        'stock_filter': stockFilter,
      if (isActive != null) 'is_active': isActive ? '1' : '0',
    };

    return ApiClient.downloadFile(
      '/manager/products/export',
      query: query.isEmpty ? null : query,
      defaultFileName: 'laporan-produk.xlsx',
      fallback: 'Gagal mengekspor data produk.',
    );
  }

  static Future<DownloadedFile> exportInventoryMovements({
    String? startDate,
    String? endDate,
    int? productId,
    String? type,
  }) async {
    final query = <String, String>{
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      if (productId != null) 'product_id': productId.toString(),
      if (type != null && type.isNotEmpty) 'type': type,
    };

    return ApiClient.downloadFile(
      '/manager/inventory-movements/export',
      query: query.isEmpty ? null : query,
      defaultFileName: 'laporan-mutasi-inventaris.xlsx',
      fallback: 'Gagal mengekspor mutasi inventaris.',
    );
  }

  static Future<DownloadedFile> downloadProductImportTemplate() async {
    return ApiClient.downloadFile(
      '/manager/products/import/template',
      defaultFileName: 'template-import-produk.xlsx',
      fallback: 'Gagal mengunduh template import produk.',
    );
  }
}

