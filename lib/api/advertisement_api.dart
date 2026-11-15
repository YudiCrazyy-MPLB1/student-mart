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
      requireAuth: true,
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
      requireAuth: true,
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
      requireAuth: true,
      body: {'action': action},
      fallback: 'Gagal memverifikasi iklan.',
    );
  }

  static Future<({List<dynamic> ads, Map<String, dynamic> counts})>
      getManagedAds({
    required String view,
    String? query,
    int? endingWithin,
    String? packageType,
    String? sort,
  }) async {
    final q = <String, String>{'view': view};
    if (query != null && query.trim().isNotEmpty) q['q'] = query.trim();
    if (endingWithin != null) q['ending_within'] = '$endingWithin';
    if (packageType != null) q['package_type'] = packageType;
    if (sort != null) q['sort'] = sort;

    final json = await ApiClient.jsonRequest(
      'GET',
      '/manager/advertisements',
      requireAuth: true,
      query: q,
      fallback: 'Gagal memuat daftar iklan.',
    );

    final counts = json['counts'];
    return (
      ads: ApiClient.dataList(json),
      counts: counts is Map ? Map<String, dynamic>.from(counts) : <String, dynamic>{},
    );
  }

  static Future<void> takeDownAd({required int adId, required String reason}) {
    return ApiClient.jsonRequest(
      'PATCH',
      '/manager/advertisements/$adId/take-down',
      requireAuth: true,
      body: {'reason': reason},
      fallback: 'Gagal menurunkan iklan.',
    );
  }

  static Future<void> extendAd({required int adId, required int days}) {
    return ApiClient.jsonRequest(
      'PATCH',
      '/manager/advertisements/$adId/extend',
      requireAuth: true,
      body: {'days': days},
      fallback: 'Gagal memperpanjang iklan.',
    );
  }

  static Future<void> deleteAd(int adId) {
    return ApiClient.jsonRequest(
      'DELETE',
      '/manager/advertisements/$adId',
      requireAuth: true,
      fallback: 'Gagal menghapus iklan.',
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

