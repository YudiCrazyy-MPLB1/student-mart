import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_navigator.dart';
import 'cart_controller.dart';
import 'user_model.dart';

/// Satu-satunya sumber kebenaran status login untuk UI.
///
/// Semua halaman harus login/logout lewat provider ini (bukan langsung ke
/// ApiService), supaya state, token, keranjang, dan navigasi selalu sinkron.
///
/// Data pengguna aktif tersedia lewat [user] — tidak perlu hit `/me` dari
/// setiap halaman secara manual.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // Satu jalur untuk sesi berakhir: ApiService memanggil ini sekali
    // setiap kali server membalas 401 untuk request yang membawa token.
    ApiService.onUnauthorized = expireSession;
  }

  bool _isAuthenticated = false;
  bool _isChecking = true;
  String? _role;

  /// Profil pengguna yang sedang login. null sebelum login atau sesudah logout.
  UserProfile? _user;

  /// Mencegah reset + navigasi ke login berjalan dua kali untuk sesi yang
  /// sama (mis. callback ApiService DAN penanganan 401 di halaman).
  bool _leavingSession = false;

  /// true selama pemeriksaan sesi di startup (RoleCheckPage menampilkan splash).
  bool get isChecking => _isChecking;
  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;

  /// Profil pengguna aktif. Tersedia setelah login / startup berhasil.
  UserProfile? get user => _user;

  /// Samakan state provider dengan token/role yang ada di ApiService.
  ///
  /// [userData] opsional — jika diisi, profil langsung disimpan dari data
  /// respons login / /me tanpa perlu request tambahan.
  void syncFromApi({Map<String, dynamic>? userData}) {
    final token = ApiService.authToken;
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
      _role = ApiService.userRole;
      _leavingSession = false;

      // Simpan profil jika data user tersedia.
      if (userData != null && userData.isNotEmpty) {
        try {
          _user = UserProfile.fromJson(userData);
        } catch (_) {
          // Jika parse gagal, biarkan _user tetap nilai lama.
        }
      }
    } else {
      _isAuthenticated = false;
      _role = null;
      _user = null;
    }
    notifyListeners();
  }

  /// Dipanggil sekali saat app start: baca token lokal, lalu verifikasi ke
  /// server (/me). Hanya 401 yang berarti token salah (ditangani ApiService ->
  /// [expireSession]); timeout / jaringan / 5xx TIDAK membuang token yang
  /// mungkin masih valid.
  Future<void> checkLoginStatus() async {
    await ApiService.loadToken();

    final token = ApiService.authToken;
    Map<String, dynamic>? meData;
    if (token != null && token.isNotEmpty) {
      try {
        meData = await ApiService.getMe().timeout(const Duration(seconds: 5));
      } catch (_) {
        // 401: sudah ditangani ApiService. Lainnya: lanjut dengan token lokal.
      }
    }

    _isChecking = false;
    syncFromApi(userData: meData);
  }

  /// Login. Melempar [ApiException] kalau gagal. Mengembalikan data response
  /// (berisi `user`) supaya halaman login bisa menyapa dan memilih tujuan.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiService.login(email: email, password: password);

    // Ekstrak objek user dari respons login dan simpan ke profil.
    final dynamic rawUser = data['user'];
    final userData =
        rawUser is Map<String, dynamic> ? rawUser : null;
    syncFromApi(userData: userData);
    return data;
  }

  /// Logout oleh user: hapus token, kosongkan keranjang, kembali ke login.
  /// Tidak melempar error; navigasi memakai navigatorKey sehingga aman
  /// dipanggil dari halaman yang sudah tidak mounted.
  Future<void> logout() async {
    if (_leavingSession) return;
    _leavingSession = true;

    await ApiService.logout(); // best-effort, tidak pernah melempar error
    _resetStateAndGoToLogin();
  }

  /// Sesi berakhir (401). Aman dipanggil berkali-kali: hanya yang pertama
  /// yang diproses. Dipanggil otomatis oleh ApiService, dan boleh dipanggil
  /// manual oleh halaman yang menerima ApiException 401.
  Future<void> expireSession() async {
    if (_leavingSession) return;
    _leavingSession = true;

    await ApiService.clearToken();
    _resetStateAndGoToLogin(
      message: 'Sesi login berakhir. Silakan login kembali.',
    );
  }

  void _resetStateAndGoToLogin({String? message}) {
    _isAuthenticated = false;
    _role = null;
    _user = null;
    notifyListeners();

    final navigator = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (navigator == null || context == null) return;

    try {
      context.read<CartController>().clearCart();
    } catch (_) {}

    // Tutup semua halaman/dialog yang terbuka. RoleCheckPage (halaman paling
    // bawah) otomatis menampilkan LoginPage karena isAuthenticated == false.
    navigator.popUntil((route) => route.isFirst);

    if (message == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = navigatorKey.currentContext;
      if (c == null) return;
      ScaffoldMessenger.maybeOf(c)?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  @override
  void dispose() {
    if (ApiService.onUnauthorized == expireSession) {
      ApiService.onUnauthorized = null;
    }
    super.dispose();
  }
}
