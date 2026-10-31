import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Endpoint manajemen stok, inventaris, dan import Excel.
class InventoryApi {
  // ============================================================
  // ACCOUNTING / INVENTORY
  // ============================================================

  static Future<Map<String, dynamic>> getInventorySummary() async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/manager/inventory/summary',
      fallback: 'Gagal mengambil ringkasan inventaris.',
    );

    return ApiClient.dataMap(json);
  }

  static Future<Map<String, dynamic>> previewProductExcel(
    Uint8List bytes,
    String fileName,
  ) async {
    final json = await ApiClient.multipartRequest(
      '/manager/products/import/preview',
      fallback: 'Gagal membaca file Excel.',
      files: [http.MultipartFile.fromBytes('file', bytes, filename: fileName)],
    );

    return ApiClient.dataMap(json);
  }

  static Future<Map<String, dynamic>> confirmProductExcel(
    List<dynamic> rows,
  ) async {
    final json = await ApiClient.jsonRequest(
      'POST',
      '/manager/products/import/confirm',
      body: {'rows': rows},
      fallback: 'Gagal melakukan import Excel.',
      timeout: ApiClient.uploadTimeout, // import banyak baris bisa lama
    );

    return ApiClient.dataMap(json);
  }

  static Future<List<dynamic>> getInventoryProducts({
    String search = '',
  }) async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/manager/inventory/products',
      query: search.trim().isEmpty ? null : {'search': search.trim()},
      fallback: 'Gagal mengambil daftar inventaris.',
    );

    return ApiClient.dataList(json);
  }

  static Future<List<dynamic>> getLowStockProducts() async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/manager/inventory/low-stock',
      fallback: 'Gagal mengambil stok menipis.',
    );

    return ApiClient.dataList(json);
  }

  static Future<List<dynamic>> getInventoryMovements({
    int? productId,
    String? type,
  }) async {
    final query = <String, String>{
      'product_id': ?productId?.toString(),
      if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
    };

    final json = await ApiClient.jsonRequest(
      'GET',
      '/manager/inventory-movements',
      query: query,
      fallback: 'Gagal mengambil riwayat inventaris.',
    );

    return ApiClient.dataList(json);
  }

  static Future<Map<String, dynamic>> inventoryStockIn({
    required int productId,
    required int quantity,
    String? note,
  }) async {
    final json = await ApiClient.jsonRequest(
      'POST',
      '/manager/inventory/products/$productId/stock-in',
      body: {
        'quantity': quantity,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      fallback: 'Gagal menambahkan stok.',
    );

    return ApiClient.dataMap(json);
  }

  static Future<Map<String, dynamic>> inventoryStockOut({
    required int productId,
    required int quantity,
    String type = 'out',
    String? note,
  }) async {
    final json = await ApiClient.jsonRequest(
      'POST',
      '/manager/inventory/products/$productId/stock-out',
      body: {
        'quantity': quantity,
        'type': type,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      fallback: 'Gagal mengurangi stok.',
    );

    return ApiClient.dataMap(json);
  }

  static Future<Map<String, dynamic>> inventoryAdjustment({
    required int productId,
    required int stock,
    String? note,
  }) async {
    final json = await ApiClient.jsonRequest(
      'POST',
      '/manager/inventory/products/$productId/adjust-stock',
      body: {
        'stock': stock,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      fallback: 'Gagal menyesuaikan stok.',
    );

    return ApiClient.dataMap(json);
  }
}

