import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../api_exception.dart';
import 'api_client.dart';

/// Endpoint iklan / advertisement (submit, verifikasi manager, listing aktif).
class AdvertisementApi {
  // ============================================================
  // ADVERTISEMENTS
  // ============================================================

  static Future<void> submitAdvertisement({
    required String title,
    required String targetUrl,
    required String packageType,
    required String paymentMethod,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    await ApiClient.multipartRequest(
      '/advertisements/submit',
      fallback: 'Gagal mengajukan iklan.',
      fields: {
        'title': title,
        'target_url': targetUrl,
        'package_type': packageType,
        'payment_method': paymentMethod,
      },
      files: [
        http.MultipartFile.fromBytes('image', imageBytes, filename: imageName),
      ],
    );
  }

  /// Daftar iklan yang menunggu verifikasi.
  static Future<List<dynamic>> getPendingAds() async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/manager/advertisements/pending',
      fallback: 'Gagal memuat antrean iklan.',
    );

    return ApiClient.dataList(json);
  }

  /// [action]: 'approve' atau 'reject'.
  static Future<Map<String, dynamic>> verifyAd({
    required int adId,
    required String action,
  }) {
    return ApiClient.jsonRequest(
      'PUT',
      '/manager/advertisements/$adId/verify',
      body: {'action': action},
      fallback: 'Gagal memverifikasi iklan.',
    );
  }

  /// Route publik. Kalau gagal dikembalikan list kosong supaya tampilan
  /// Home tidak rusak hanya karena iklan tidak termuat.
  static Future<List<dynamic>> getActiveAds() async {
    try {
      final json = await ApiClient.jsonRequest(
        'GET',
        '/advertisements',
        isPublic: true,
        fallback: 'Gagal memuat iklan.',
      );

      return ApiClient.dataList(json);
    } on ApiException {
      return <dynamic>[];
    }
  }
}

