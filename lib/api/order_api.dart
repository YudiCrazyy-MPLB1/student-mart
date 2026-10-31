import 'api_client.dart';

/// Endpoint pesanan siswa.
class OrderApi {
  // ============================================================
  // ORDERS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/orders',
      requireAuth: true,
      fallback: 'Gagal mengambil riwayat pesanan.',
      timeoutMessage: 'Mengambil pesanan terlalu lama.',
    );

    return ApiClient.mapList(ApiClient.dataList(json));
  }

  static Future<Map<String, dynamic>> createOrder({
    required String pickupMethod,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final json = await ApiClient.jsonRequest(
      'POST',
      '/orders',
      requireAuth: true,
      body: {
        'pickup_method': pickupMethod,
        'payment_method': paymentMethod,
        'items': items,
      },
      fallback: 'Gagal membuat pesanan.',
      timeoutMessage: 'Pembuatan pesanan terlalu lama.',
    );

    return ApiClient.dataMap(json);
  }
}

