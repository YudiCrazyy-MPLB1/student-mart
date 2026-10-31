import 'dart:async';
import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Endpoint autentikasi: login, register, logout, getMe, password reset.
class AuthApi {
  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final json = await ApiClient.jsonRequest(
      'POST',
      '/login',
      body: {'email': email.trim(), 'password': password},
      isPublic: true,
      fallback: 'Email atau password salah.',
      timeoutMessage: 'Server terlalu lama merespons. Coba lagi.',
    );

    final data = ApiClient.dataMap(json);

    final token = data['token'];
    final user = data['user'];
    String? role;

    if (user is Map) {
      role = user['role']?.toString();
    }

    if (token != null && token.toString().isNotEmpty) {
      await ApiClient.saveToken(token.toString(), role ?? 'student');
    }

    return data;
  }

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String kodeUndangan,
  }) async {
    final json = await ApiClient.jsonRequest(
      'POST',
      '/register',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
        'kode_undangan': kodeUndangan.trim(),
      },
      isPublic: true,
      fallback: 'Pendaftaran gagal.',
    );

    return ApiClient.dataMap(json);
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  /// Selalu menghapus token lokal dan TIDAK PERNAH melempar error.
  /// Pemanggilan ke server hanya best-effort: kalau server tidak terjangkau,
  /// user tetap harus bisa keluar.
  static Future<void> logout() async {
    final token = ApiClient.authToken;

    try {
      if (token != null && token.isNotEmpty) {
        await http
            .post(
              ApiClient.uri('/logout'),
              headers: ApiClient.headers(token: token, json: false),
            )
            .timeout(ApiClient.requestTimeout);
      }
    } catch (_) {
      // sengaja diabaikan
    } finally {
      await ApiClient.clearToken();
    }
  }

  // ============================================================
  // GET ME
  // ============================================================

  static Future<Map<String, dynamic>> getMe() async {
    final json = await ApiClient.jsonRequest(
      'GET',
      '/me',
      requireAuth: true,
      notLoggedInMessage: 'Tidak ada token login.',
      fallback: 'Gagal mengambil data pengguna.',
    );

    final data = ApiClient.dataMap(json);

    // Sinkronisasi role terbaru.
    final role = data['role']?.toString();

    if (role != null && role.isNotEmpty) {
      ApiClient.userRole = role.toLowerCase();
      await ApiClient.flutterSecureStorage.write(
        key: ApiClient.roleKey,
        value: ApiClient.userRole!,
      );
    }

    return data;
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  static Future<void> forgotPassword(String email) async {
    await ApiClient.jsonRequest(
      'POST',
      '/forgot-password',
      body: {'email': email.trim()},
      isPublic: true,
      fallback: 'Gagal mengirim link reset password.',
      timeoutMessage: 'Permintaan terlalu lama.',
    );
  }

  static Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await ApiClient.jsonRequest(
      'POST',
      '/reset-password',
      body: {
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      isPublic: true,
      fallback: 'Gagal mereset password.',
      timeoutMessage: 'Permintaan terlalu lama.',
    );
  }
}

