import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../api_exception.dart';
import '../config.dart';
import '../product_model.dart';

/// Client HTTP dasar yang menangani koneksi, autentikasi, token,
/// timeout, dan parsing respon Laravel.
class ApiClient {
  static const flutterSecureStorage = FlutterSecureStorage();
  static final String baseUrl = Config.baseUrl;

  static const Duration requestTimeout = Duration(seconds: 15);

  /// Upload gambar / import Excel butuh waktu lebih lama di jaringan lambat.
  static const Duration uploadTimeout = Duration(seconds: 60);

  static String? authToken;
  static String? userRole;

  /// Dipanggil SEKALI saat sesi berakhir (server membalas 401 untuk request
  /// yang membawa token).
  static void Function()? onUnauthorized;
  static bool sessionExpiryHandled = false;

  static const String tokenKey = 'student_mart_auth_token';
  static const String roleKey = 'student_mart_user_role';

  // ============================================================
  // TOKEN & ROLE
  // ============================================================

  static Future<void> loadToken() async {
    authToken = await flutterSecureStorage.read(key: tokenKey);
    userRole = await flutterSecureStorage.read(key: roleKey);

    if (authToken == null || authToken!.isEmpty) {
      userRole = null;
    }
  }

  static Future<void> saveToken(String token, String? role) async {
    authToken = token;
    sessionExpiryHandled = false;

    if (role != null && role.isNotEmpty) {
      userRole = role.toLowerCase();
    }

    await flutterSecureStorage.write(key: tokenKey, value: token);

    if (userRole != null && userRole!.isNotEmpty) {
      await flutterSecureStorage.write(key: roleKey, value: userRole!);
    }
  }

  static Future<void> clearToken() async {
    authToken = null;
    userRole = null;

    await flutterSecureStorage.delete(key: tokenKey);
    await flutterSecureStorage.delete(key: roleKey);
  }

  // ============================================================
  // IMAGE URL
  // ============================================================

  static String getImageUrl(String? image) {
    if (image == null || image.trim().isEmpty) {
      return '';
    }

    final value = image.trim();

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final cleanPath = value.startsWith('/') ? value.substring(1) : value;
    final serverUrl = baseUrl.replaceFirst(RegExp(r'/api(/v1)?$'), '');
    final uri = Uri.parse('$serverUrl/$cleanPath');
    return uri.toString();
  }

  // ============================================================
  // CORE: REQUEST PIPELINE
  // ============================================================

  static Uri uri(String path, [Map<String, String>? query]) {
    final u = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return u;
    return u.replace(queryParameters: query);
  }

  static Map<String, String> headers({String? token, bool json = true}) {
    final h = <String, String>{'Accept': 'application/json'};

    if (json) h['Content-Type'] = 'application/json';

    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }

    return h;
  }

  static String? resolveToken({
    required bool isPublic,
    required bool requireAuth,
    String? notLoggedInMessage,
  }) {
    if (isPublic) return null;

    final token = authToken;
    final hasToken = token != null && token.isNotEmpty;

    if (!hasToken && requireAuth) {
      throw ApiException(
        401,
        notLoggedInMessage ?? 'Kamu belum login. Silakan login terlebih dahulu.',
      );
    }

    return hasToken ? token : null;
  }

  static Future<Map<String, dynamic>> jsonRequest(
    String method,
    String path, {
    required String fallback,
    Map<String, String>? query,
    Object? body,
    bool requireAuth = false,
    bool isPublic = false,
    String? notLoggedInMessage,
    Duration? timeout,
    String? timeoutMessage,
    Map<int, String>? statusMessages,
  }) async {
    final token = resolveToken(
      isPublic: isPublic,
      requireAuth: requireAuth,
      notLoggedInMessage: notLoggedInMessage,
    );

    final request = http.Request(method, uri(path, query))
      ..headers.addAll(headers(token: token, json: body != null));

    if (body != null) request.body = jsonEncode(body);

    return send(
      request,
      usedToken: token,
      isPublic: isPublic,
      fallback: fallback,
      timeout: timeout ?? requestTimeout,
      timeoutMessage: timeoutMessage,
      statusMessages: statusMessages,
    );
  }

  static Future<Map<String, dynamic>> multipartRequest(
    String path, {
    required String fallback,
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
    bool requireAuth = false,
    String? notLoggedInMessage,
    String? timeoutMessage,
  }) async {
    final token = resolveToken(
      isPublic: false,
      requireAuth: requireAuth,
      notLoggedInMessage: notLoggedInMessage,
    );

    final request = http.MultipartRequest('POST', uri(path))
      ..headers.addAll(headers(token: token, json: false))
      ..fields.addAll(fields)
      ..files.addAll(files);

    return send(
      request,
      usedToken: token,
      isPublic: false,
      fallback: fallback,
      timeout: uploadTimeout,
      timeoutMessage: timeoutMessage ?? 'Upload terlalu lama. Coba lagi.',
    );
  }

  static Future<Map<String, dynamic>> send(
    http.BaseRequest request, {
    required String? usedToken,
    required bool isPublic,
    required String fallback,
    required Duration timeout,
    String? timeoutMessage,
    Map<int, String>? statusMessages,
  }) async {
    try {
      final response = await request
          .send()
          .then(http.Response.fromStream)
          .timeout(timeout);

      return await parseResponse(
        response,
        usedToken: usedToken,
        isPublic: isPublic,
        fallback: fallback,
        statusMessages: statusMessages,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        408,
        timeoutMessage ?? 'Server terlalu lama merespons. Coba lagi.',
      );
    } on http.ClientException {
      throw ApiException(503, 'Tidak dapat terhubung ke server.');
    } on FormatException {
      throw ApiException(502, 'Server mengirim response yang tidak valid.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw ApiException(503, 'Tidak dapat terhubung ke server.');
      }
      throw ApiException(500, fallback);
    }
  }

  static Future<Map<String, dynamic>> parseResponse(
    http.Response response, {
    required String? usedToken,
    required bool isPublic,
    required String fallback,
    Map<int, String>? statusMessages,
  }) async {
    final status = response.statusCode;
    final isOk = status >= 200 && status < 300;
    final json = tryDecode(response.body);

    var isSessionExpiry = false;
    if (status == 401 && !isPublic && usedToken != null) {
      isSessionExpiry = true;
      await expireSession(usedToken);
    }

    if (!isOk || (json != null && json['success'] == false)) {
      throw ApiException(
        status,
        errorMessage(
          status,
          json,
          fallback,
          statusMessages: statusMessages,
          sessionExpiry: isSessionExpiry,
        ),
      );
    }

    if (json == null) {
      if (response.body.trim().isEmpty) return <String, dynamic>{};
      throw ApiException(502, 'Server mengirim response yang tidak valid.');
    }

    return json;
  }

  static Map<String, dynamic>? tryDecode(String body) {
    if (body.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String errorMessage(
    int status,
    Map<String, dynamic>? json,
    String fallback, {
    Map<int, String>? statusMessages,
    required bool sessionExpiry,
  }) {
    final override = statusMessages?[status];
    if (override != null) return override;

    if (sessionExpiry) {
      return 'Sesi login sudah berakhir. Silakan login kembali.';
    }

    if (status >= 500) {
      return 'Server sedang bermasalah. Coba lagi nanti.';
    }

    final message = json?['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final errors = json?['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first is String && first.isNotEmpty) return first;
    }

    if (status == 429) return 'Terlalu banyak percobaan. Coba lagi nanti.';

    return fallback;
  }

  static Future<void> expireSession(String usedToken) async {
    if (authToken != usedToken) return;

    await clearToken();

    if (!sessionExpiryHandled) {
      sessionExpiryHandled = true;
      onUnauthorized?.call();
    }
  }

  // ---------- helper membaca field "data" ----------

  static Map<String, dynamic> dataMap(Map<String, dynamic> json) {
    final data = json['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  static Map<String, dynamic> requireDataMap(
    Map<String, dynamic> json,
    String invalidMessage,
  ) {
    final data = json['data'];
    if (data is! Map) throw ApiException(502, invalidMessage);
    return Map<String, dynamic>.from(data);
  }

  static List<dynamic> dataList(
    Map<String, dynamic> json, {
    String? invalidMessage,
  }) {
    final data = json['data'];

    if (data is List) return List<dynamic>.from(data);

    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data'] as List);
    }

    if (invalidMessage != null) throw ApiException(502, invalidMessage);

    return <dynamic>[];
  }

  static List<Map<String, dynamic>> mapList(List<dynamic> list) {
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static List<Product> productList(List<dynamic> list) {
    return list
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}

