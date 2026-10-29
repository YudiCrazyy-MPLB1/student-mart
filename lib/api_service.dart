import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_exception.dart';
import 'config.dart';
import 'product_model.dart';

/// Satu-satunya pintu komunikasi ke backend Laravel.
///
/// Semua request lewat [_json] (JSON) atau [_multipart] (upload), lalu
/// diproses oleh [_send]. Artinya untuk SEMUA endpoint:
///   - timeout selalu ada,
///   - response non-JSON (HTML 502/maintenance) tidak pernah crash,
///   - body mentah server tidak pernah bocor ke pesan error,
///   - semua error dilempar sebagai [ApiException] (ada statusCode),
///   - 401 pada request ber-token ditangani di satu tempat
///     (hapus token + panggil [onUnauthorized]).
///
/// Signature method publik sengaja TIDAK diubah, jadi halaman yang sudah
/// ada tidak perlu diedit.
/// 
class ApiService {
  static const flutterSecureStorage = FlutterSecureStorage();
  static final String baseUrl = Config.baseUrl;

  static const Duration requestTimeout = Duration(seconds: 15);

  /// Upload gambar / import Excel butuh waktu lebih lama di jaringan lambat.
  static const Duration uploadTimeout = Duration(seconds: 60);

  static String? authToken;
  static String? userRole;

  /// Dipanggil SEKALI saat sesi berakhir (server membalas 401 untuk request
  /// yang membawa token). Diset oleh AuthProvider; di situlah navigasi ke
  /// halaman login dan reset state dilakukan.
  static void Function()? onUnauthorized;
  static bool _sessionExpiryHandled = false;

  static const String _tokenKey = 'student_mart_auth_token';
  static const String _roleKey = 'student_mart_user_role';

  // ============================================================
  // TOKEN & ROLE
  // ============================================================

  static Future<void> loadToken() async {
    authToken = await flutterSecureStorage.read(key: _tokenKey);
    userRole = await flutterSecureStorage.read(key: _roleKey);

    // Kalau token tidak ada, role juga tidak diperlukan.
    if (authToken == null || authToken!.isEmpty) {
      userRole = null;
    }
  }

  static Future<void> saveToken(String token, String? role) async {
    authToken = token;
    _sessionExpiryHandled = false; // sesi baru, handler 401 aktif lagi

    if (role != null && role.isNotEmpty) {
      userRole = role.toLowerCase();
    }

    await flutterSecureStorage.write(key: _tokenKey, value: token);

    if (userRole != null && userRole!.isNotEmpty) {
      await flutterSecureStorage.write(key: _roleKey, value: userRole!);
    }
  }

  static Future<void> clearToken() async {
    authToken = null;
    userRole = null;

    await flutterSecureStorage.delete(key: _tokenKey);
    await flutterSecureStorage.delete(key: _roleKey);
  }

  // ============================================================
  // IMAGE URL
  // ============================================================

  static String getImageUrl(String? image) {
    if (image == null || image.trim().isEmpty) {
      return '';
    }

    final value = image.trim();

    // Kalau backend sudah mengirim URL lengkap
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    // Hilangkan "/" di awal jika ada
    final cleanPath = value.startsWith('/') ? value.substring(1) : value;

    final serverUrl = baseUrl.replaceFirst(RegExp(r'/api(/v1)?$'), '');

    final uri = Uri.parse('$serverUrl/$cleanPath');
    return uri.toString();
  }

  // ============================================================
  // CORE: REQUEST PIPELINE (semua endpoint lewat sini)
  // ============================================================

  static Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  static Map<String, String> _headers({String? token, bool json = true}) {
    final headers = <String, String>{'Accept': 'application/json'};

    if (json) headers['Content-Type'] = 'application/json';

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Menentukan token yang dipakai request ini.
  /// [isPublic] = endpoint tanpa login (token tidak dikirim sama sekali).
  /// [requireAuth] = langsung gagal kalau belum login (tanpa hit server).
  static String? _resolveToken({
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

  /// Request JSON. Mengembalikan body response (Map) kalau sukses.
  static Future<Map<String, dynamic>> _json(
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
    final token = _resolveToken(
      isPublic: isPublic,
      requireAuth: requireAuth,
      notLoggedInMessage: notLoggedInMessage,
    );

    final request = http.Request(method, _uri(path, query))
      ..headers.addAll(_headers(token: token, json: body != null));

    if (body != null) request.body = jsonEncode(body);

    return _send(
      request,
      usedToken: token,
      isPublic: isPublic,
      fallback: fallback,
      timeout: timeout ?? requestTimeout,
      timeoutMessage: timeoutMessage,
      statusMessages: statusMessages,
    );
  }

  /// Request multipart (upload file). Selalu POST.
  static Future<Map<String, dynamic>> _multipart(
    String path, {
    required String fallback,
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
    bool requireAuth = false,
    String? notLoggedInMessage,
    String? timeoutMessage,
  }) async {
    final token = _resolveToken(
      isPublic: false,
      requireAuth: requireAuth,
      notLoggedInMessage: notLoggedInMessage,
    );

    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(_headers(token: token, json: false))
      ..fields.addAll(fields)
      ..files.addAll(files);

    return _send(
      request,
      usedToken: token,
      isPublic: false,
      fallback: fallback,
      timeout: uploadTimeout,
      timeoutMessage: timeoutMessage ?? 'Upload terlalu lama. Coba lagi.',
    );
  }

  static Future<Map<String, dynamic>> _send(
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

      return await _parse(
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
      // SocketException dll. Tidak meng-import dart:io supaya tetap
      // bisa dibuild untuk web.
      if (e.toString().contains('SocketException')) {
        throw ApiException(503, 'Tidak dapat terhubung ke server.');
      }
      throw ApiException(500, fallback);
    }
  }

  static Future<Map<String, dynamic>> _parse(
    http.Response response, {
    required String? usedToken,
    required bool isPublic,
    required String fallback,
    Map<int, String>? statusMessages,
  }) async {
    final status = response.statusCode;
    final isOk = status >= 200 && status < 300;
    final json = _tryDecode(response.body);

    // 401 pada request yang membawa token = sesi berakhir.
    var isSessionExpiry = false;
    if (status == 401 && !isPublic && usedToken != null) {
      isSessionExpiry = true;
      await _expireSession(usedToken);
    }

    // Gagal: status non-2xx, atau server eksplisit bilang success:false.
    if (!isOk || (json != null && json['success'] == false)) {
      throw ApiException(
        status,
        _errorMessage(
          status,
          json,
          fallback,
          statusMessages: statusMessages,
          sessionExpiry: isSessionExpiry,
        ),
      );
    }

    if (json == null) {
      // 2xx tanpa body (mis. 204) dianggap sukses kosong.
      if (response.body.trim().isEmpty) return <String, dynamic>{};
      throw ApiException(502, 'Server mengirim response yang tidak valid.');
    }

    return json;
  }

  static Map<String, dynamic>? _tryDecode(String body) {
    if (body.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Pesan error yang aman ditampilkan ke user.
  /// Body mentah server TIDAK PERNAH dipakai; untuk 5xx pesan server juga
  /// diabaikan (APP_DEBUG=true di Laravel bisa membocorkan SQL/stacktrace).
  static String _errorMessage(
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

    // Validasi Laravel: {"errors": {"email": ["..."]}}
    final errors = json?['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first is String && first.isNotEmpty) return first;
    }

    if (status == 429) return 'Terlalu banyak percobaan. Coba lagi nanti.';

    return fallback;
  }

  /// Satu-satunya tempat sesi dinyatakan berakhir.
  static Future<void> _expireSession(String usedToken) async {
    // Kalau token sudah berganti (user login ulang saat request lama masih
    // berjalan), jangan hapus token baru.
    if (authToken != usedToken) return;

    await clearToken();

    if (!_sessionExpiryHandled) {
      _sessionExpiryHandled = true;
      onUnauthorized?.call();
    }
  }

  // ---------- helper membaca field "data" ----------

  static Map<String, dynamic> _dataMap(Map<String, dynamic> json) {
    final data = json['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  static Map<String, dynamic> _requireDataMap(
    Map<String, dynamic> json,
    String invalidMessage,
  ) {
    final data = json['data'];
    if (data is! Map) throw ApiException(502, invalidMessage);
    return Map<String, dynamic>.from(data);
  }

  /// Menerima `data: [...]` maupun hasil paginate() `data: {data: [...]}`.
  /// Kalau [invalidMessage] diisi, bentuk yang tidak dikenal melempar error
  /// (bukan diam-diam menjadi list kosong).
  static List<dynamic> _dataList(
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

  static List<Map<String, dynamic>> _mapList(List<dynamic> list) {
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static List<Product> _productList(List<dynamic> list) {
    return list
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final json = await _json(
      'POST',
      '/login',
      body: {'email': email.trim(), 'password': password},
      isPublic: true,
      fallback: 'Email atau password salah.',
      timeoutMessage: 'Server terlalu lama merespons. Coba lagi.',
    );

    final data = _dataMap(json);

    final token = data['token'];
    final user = data['user'];
    String? role;

    if (user is Map) {
      role = user['role']?.toString();
    }

    if (token != null && token.toString().isNotEmpty) {
      await saveToken(token.toString(), role ?? 'student');
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
    final json = await _json(
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

    return _dataMap(json);
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  /// Selalu menghapus token lokal dan TIDAK PERNAH melempar error.
  /// Pemanggilan ke server hanya best-effort: kalau server tidak terjangkau,
  /// user tetap harus bisa keluar.
  static Future<void> logout() async {
    final token = authToken;

    try {
      if (token != null && token.isNotEmpty) {
        await http
            .post(
              _uri('/logout'),
              headers: _headers(token: token, json: false),
            )
            .timeout(requestTimeout);
      }
    } catch (_) {
      // sengaja diabaikan
    } finally {
      await clearToken();
    }
  }

  // ============================================================
  // GET ME
  // ============================================================

  static Future<Map<String, dynamic>> getMe() async {
    final json = await _json(
      'GET',
      '/me',
      requireAuth: true,
      notLoggedInMessage: 'Tidak ada token login.',
      fallback: 'Gagal mengambil data pengguna.',
    );

    final data = _dataMap(json);

    // Sinkronisasi role terbaru.
    final role = data['role']?.toString();

    if (role != null && role.isNotEmpty) {
      userRole = role.toLowerCase();
      await flutterSecureStorage.write(key: _roleKey, value: userRole!);
    }

    return data;
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  static Future<void> forgotPassword(String email) async {
    await _json(
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
    await _json(
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

  // ============================================================
  // MANAGER DASHBOARD
  // ============================================================

  static Future<Map<String, dynamic>> getManagerDashboard() async {
    final json = await _json(
      'GET',
      '/manager/dashboard',
      requireAuth: true,
      notLoggedInMessage: 'Kamu belum login sebagai manager.',
      fallback: 'Gagal mengambil dashboard manager.',
      timeoutMessage: 'Mengambil dashboard terlalu lama.',
      statusMessages: {403: 'Akses ditolak. Akun ini bukan manager.'},
    );

    return _dataMap(json);
  }

  // ============================================================
  // MANAGER PRODUCT
  // ============================================================

  static Future<List<Product>> getManagerProducts() async {
    final json = await _json(
      'GET',
      '/manager/products',
      fallback: 'Gagal mengambil produk manager.',
    );

    return _productList(
      _dataList(json, invalidMessage: 'Data produk manager tidak valid.'),
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

    final json = await _multipart(
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
      _requireDataMap(json, 'Response tidak berisi data produk.'),
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

    final json = await _multipart(
      '/manager/products/$productId',
      requireAuth: true,
      notLoggedInMessage: 'Kamu belum login sebagai manager.',
      fallback: 'Gagal memperbarui produk.',
      fields: fields,
      files: files,
    );

    return Product.fromJson(
      _requireDataMap(json, 'Response tidak berisi data produk.'),
    );
  }

  static Future<Product> deactivateManagerProduct(int productId) async {
    final json = await _json(
      'DELETE',
      '/manager/products/$productId',
      fallback: 'Gagal menonaktifkan produk.',
    );

    return Product.fromJson(
      _requireDataMap(json, 'Response tidak berisi data produk.'),
    );
  }

  static Future<Product> activateManagerProduct(int productId) async {
    final json = await _json(
      'PATCH',
      '/manager/products/$productId/activate',
      fallback: 'Gagal mengaktifkan produk.',
    );

    return Product.fromJson(
      _requireDataMap(json, 'Response tidak berisi data produk.'),
    );
  }

  // ============================================================
  // ACCOUNTING / INVENTORY
  // ============================================================

  static Future<Map<String, dynamic>> getInventorySummary() async {
    final json = await _json(
      'GET',
      '/manager/inventory/summary',
      fallback: 'Gagal mengambil ringkasan inventaris.',
    );

    return _dataMap(json);
  }

  static Future<Map<String, dynamic>> previewProductExcel(
    Uint8List bytes,
    String fileName,
  ) async {
    final json = await _multipart(
      '/manager/products/import/preview',
      fallback: 'Gagal membaca file Excel.',
      files: [http.MultipartFile.fromBytes('file', bytes, filename: fileName)],
    );

    return _dataMap(json);
  }

  static Future<Map<String, dynamic>> confirmProductExcel(
    List<dynamic> rows,
  ) async {
    final json = await _json(
      'POST',
      '/manager/products/import/confirm',
      body: {'rows': rows},
      fallback: 'Gagal melakukan import Excel.',
      timeout: uploadTimeout, // import banyak baris bisa lama
    );

    return _dataMap(json);
  }

  static Future<List<dynamic>> getInventoryProducts({
    String search = '',
  }) async {
    final json = await _json(
      'GET',
      '/manager/inventory/products',
      query: search.trim().isEmpty ? null : {'search': search.trim()},
      fallback: 'Gagal mengambil daftar inventaris.',
    );

    return _dataList(json);
  }

  static Future<List<dynamic>> getLowStockProducts() async {
    final json = await _json(
      'GET',
      '/manager/inventory/low-stock',
      fallback: 'Gagal mengambil stok menipis.',
    );

    return _dataList(json);
  }

  static Future<List<dynamic>> getInventoryMovements({
    int? productId,
    String? type,
  }) async {
    final query = <String, String>{
      'product_id': ?productId?.toString(),
      if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
    };

    final json = await _json(
      'GET',
      '/manager/inventory-movements',
      query: query,
      fallback: 'Gagal mengambil riwayat inventaris.',
    );

    // Endpoint memakai paginate(30); _dataList menangani kedua bentuk.
    return _dataList(json);
  }

  static Future<Map<String, dynamic>> inventoryStockIn({
    required int productId,
    required int quantity,
    String? note,
  }) async {
    final json = await _json(
      'POST',
      '/manager/inventory/products/$productId/stock-in',
      body: {
        'quantity': quantity,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      fallback: 'Gagal menambahkan stok.',
    );

    return _dataMap(json);
  }

  static Future<Map<String, dynamic>> inventoryStockOut({
    required int productId,
    required int quantity,
    String type = 'out',
    String? note,
  }) async {
    final json = await _json(
      'POST',
      '/manager/inventory/products/$productId/stock-out',
      body: {
        'quantity': quantity,
        'type': type,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      fallback: 'Gagal mengurangi stok.',
    );

    return _dataMap(json);
  }

  static Future<Map<String, dynamic>> inventoryAdjustment({
    required int productId,
    required int stock,
    String? note,
  }) async {
    final json = await _json(
      'POST',
      '/manager/inventory/products/$productId/adjust-stock',
      body: {
        'stock': stock,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      fallback: 'Gagal menyesuaikan stok.',
    );

    return _dataMap(json);
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  static Future<List<Product>> getProducts() async {
    final json = await _json(
      'GET',
      '/products',
      fallback: 'Gagal mengambil produk.',
      timeoutMessage: 'Mengambil produk terlalu lama.',
    );

    // _dataList menangani paginate() maupun get() biasa.
    return _productList(_dataList(json));
  }

  static Future<Product> getProduct(int id) async {
    final json = await _json(
      'GET',
      '/products/$id',
      fallback: 'Gagal mengambil detail produk.',
      timeoutMessage: 'Mengambil detail produk terlalu lama.',
    );

    return Product.fromJson(
      _requireDataMap(json, 'Data detail produk tidak valid.'),
    );
  }

  // ============================================================
  // ORDERS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final json = await _json(
      'GET',
      '/orders',
      requireAuth: true,
      fallback: 'Gagal mengambil riwayat pesanan.',
      timeoutMessage: 'Mengambil pesanan terlalu lama.',
    );

    return _mapList(_dataList(json));
  }

  static Future<Map<String, dynamic>> createOrder({
    required String pickupMethod,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final json = await _json(
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

    return _dataMap(json);
  }

  // ============================================================
  // MANAGER ORDERS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getManagerOrders() async {
    final json = await _json(
      'GET',
      '/manager/orders',
      fallback: 'Gagal mengambil pesanan.',
    );

    return _mapList(
      _dataList(json, invalidMessage: 'Data pesanan manager tidak valid.'),
    );
  }

  /// Sekarang melempar [ApiException] kalau gagal (sebelumnya diam-diam
  /// mengembalikan body error sehingga UI menampilkan "berhasil").
  /// Return value tetap body response penuh seperti sebelumnya.
  static Future<Map<String, dynamic>> updateManagerOrderStatus({
    required int orderId,
    required String status,
  }) async {
    return _json(
      'PATCH',
      '/manager/orders/$orderId/status',
      body: {'status': status},
      fallback: 'Gagal mengubah status pesanan.',
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final json = await _json(
      'GET',
      '/categories',
      fallback: 'Gagal mengambil kategori.',
      timeoutMessage: 'Mengambil kategori terlalu lama.',
    );

    return _mapList(_dataList(json));
  }

  // ============================================================
  // CONSIGNMENT (KONSINYASI)
  // ============================================================

  static Future<Map<String, dynamic>> agreeTos() {
    return _json(
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
    return _multipart(
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
    final json = await _json(
      'GET',
      '/manager/consignment/products/pending',
      fallback: 'Gagal memuat produk pending.',
    );

    return _dataList(json);
  }

  static Future<Map<String, dynamic>> verifyProduct({
    required int productId,
    required String status,
  }) {
    return _json(
      'PUT',
      '/manager/consignment/products/$productId/verify',
      body: {'status': status},
      fallback: 'Gagal memverifikasi produk.',
    );
  }

  static Future<List<dynamic>> getMyConsignmentProducts() async {
    final json = await _json(
      'GET',
      '/consignment/my-products',
      fallback: 'Gagal memuat produk saya.',
    );

    return _dataList(json);
  }

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
    await _multipart(
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
    final json = await _json(
      'GET',
      '/manager/advertisements/pending',
      fallback: 'Gagal memuat antrean iklan.',
    );

    return _dataList(json);
  }

  /// [action]: 'approve' atau 'reject'.
  static Future<Map<String, dynamic>> verifyAd({
    required int adId,
    required String action,
  }) {
    return _json(
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
      final json = await _json(
        'GET',
        '/advertisements',
        isPublic: true,
        fallback: 'Gagal memuat iklan.',
      );

      return _dataList(json);
    } on ApiException {
      return <dynamic>[];
    }
  }
}