import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Endpoint sistem konsinyasi (supplier/consignor & verifikasi manager).
class ConsignmentApi {
  // ============================================================
  // CONSIGNMENT (KONSINYASI)
  // ============================================================

  static Future<Map<String, dynamic>> agreeTos() {
    return ApiClient.jsonRequest(
      'POST',
      '/consignment/tos',
      fallback: 'Gagal menyetujui TOS.',
    );
  }

  static Future<Map<String, dynamic>> submitConsignmentProduct({
    required String name,
    required String description,
    required String price,
    required String stock,
    required List<int> imageBytes,
    required String imageName,
  }) {
    return ApiClient.multipartRequest(
      '/consignment/products',
      fallback: 'Gagal mengunggah produk.',
      fields: {
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
      },
      files: [
        http.MultipartFile.fromBytes('image', imageBytes, filename: imageName),
      ],
    );
  }

  static Future<List<dynamic>> getPendingProducts() async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/manager/consignment/products/pending',
      fallback: 'Gagal memuat produk pending.',
    );

    return ApiClient.dataList(json);
  }

  static Future<Map<String, dynamic>> verifyProduct({
    required int productId,
    required String status,
  }) {
    return ApiClient.jsonRequest(
      'PUT',
      '/manager/consignment/products/$productId/verify',
      body: {'status': status},
      fallback: 'Gagal memverifikasi produk.',
    );
  }

  static Future<List<dynamic>> getMyConsignmentProducts() async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/consignment/my-products',
      fallback: 'Gagal memuat produk saya.',
    );

    return ApiClient.dataList(json);
  }
}

