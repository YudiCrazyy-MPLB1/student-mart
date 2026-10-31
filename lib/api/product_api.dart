import '../product_model.dart';
import 'api_client.dart';

/// Endpoint produk siswa & kategori umum.
class ProductApi {
  // ============================================================
  // PRODUCTS
  // ============================================================

  static Future<List<Product>> getProducts() async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/products',
      fallback: 'Gagal mengambil produk.',
      timeoutMessage: 'Mengambil produk terlalu lama.',
    );

    return ApiClient.productList(ApiClient.dataList(json));
  }

  static Future<Product> getProduct(int id) async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/products/$id',
      fallback: 'Gagal mengambil detail produk.',
      timeoutMessage: 'Mengambil detail produk terlalu lama.',
    );

    return Product.fromJson(
      ApiClient.requireDataMap(json, 'Data detail produk tidak valid.'),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/categories',
      fallback: 'Gagal mengambil kategori.',
      timeoutMessage: 'Mengambil kategori terlalu lama.',
    );

    return ApiClient.mapList(ApiClient.dataList(json));
  }
}

