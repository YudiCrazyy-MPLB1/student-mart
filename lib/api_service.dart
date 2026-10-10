import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'product_model.dart';

import 'package:image_picker/image_picker.dart';

class ApiService {
  static const flutterSecureStorage = FlutterSecureStorage();
  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost/api';

  static const Duration requestTimeout =
      Duration(seconds: 15);

  static String? authToken;
  static String? userRole;

  static const String _tokenKey =
      'student_mart_auth_token';

  static const String _roleKey =
      'student_mart_user_role';

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

  static Future<void> saveToken(
    String token,
    String? role,
  ) async {
    authToken = token;

    if (role != null && role.isNotEmpty) {
      userRole = role.toLowerCase();
    }

    await flutterSecureStorage.write(
      key: _tokenKey,
      value: token,
    );

    if (userRole != null &&
        userRole!.isNotEmpty) {
      await flutterSecureStorage.write(
        key: _roleKey,
        value: userRole!,
      );
    }
  }

  static Future<void> clearToken() async {
    authToken = null;
    userRole = null;

    await flutterSecureStorage.delete(key: _tokenKey);
    await flutterSecureStorage.delete(key: _roleKey);
  }

  // ============================================================
  // HEADERS
  // ============================================================

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authToken != null &&
        authToken!.isNotEmpty) {
      headers['Authorization'] =
          'Bearer $authToken';
    }

    return headers;
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
    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }

    // Hilangkan "/" di awal jika ada
    final cleanPath = value.startsWith('/')
        ? value.substring(1)
        : value;

    // Ubah:
    // http://127.0.0.1:8000/api
    // menjadi:
    // http://127.0.0.1:8000
    final serverUrl = baseUrl.replaceFirst(
      RegExp(r'/api$'),
      '',
    );

    return '$serverUrl/storage/$cleanPath';
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(requestTimeout);

      final json = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(
          json['message'] ??
              'Email atau password salah.',
        );
      }

      if (json['success'] != true) {
        throw Exception(
          json['message'] ??
              'Login gagal.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        json['data'] ?? {},
      );

      final token = data['token'];

      if (token == null ||
          token.toString().isEmpty) {
        throw Exception(
          'Token login tidak diterima dari server.',
        );
      }

      // Ambil role dari user
      final user = data['user'];

      String? role;

      if (user is Map<String, dynamic>) {
        role = user['role']?.toString();
      }

      // Simpan token + role
      await saveToken(
        token.toString(),
        role,
      );

      return data;
    } on TimeoutException {
      throw Exception(
        'Server terlalu lama merespons. '
        'Coba lagi.',
      );
    } on http.ClientException {
      throw Exception(
        'Tidak dapat terhubung ke server.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Terjadi kesalahan saat login.',
      );
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim(),
              'password': password,
              'password_confirmation':
                  passwordConfirmation,
            }),
          )
          .timeout(requestTimeout);

      final json = _decodeResponse(response);

      if (response.statusCode != 201) {
        throw Exception(
          json['message'] ??
              'Pendaftaran gagal.',
        );
      }

      if (json['success'] != true) {
        throw Exception(
          json['message'] ??
              'Pendaftaran gagal.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        json['data'] ?? {},
      );

      final token = data['token'];

      if (token == null ||
          token.toString().isEmpty) {
        throw Exception(
          'Token registrasi tidak diterima dari server.',
        );
      }

      // Register selalu student dari backend.
      final user = data['user'];

      String? role;

      if (user is Map<String, dynamic>) {
        role =
            user['role']?.toString();
      }

      await saveToken(
        token.toString(),
        role ?? 'student',
      );

      return data;
    } on TimeoutException {
      throw Exception(
        'Server terlalu lama merespons.',
      );
    } on http.ClientException {
      throw Exception(
        'Tidak dapat terhubung ke server.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Terjadi kesalahan saat mendaftar.',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    if (authToken == null) {
      await clearToken();
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/logout'),
            headers: _headers,
          )
          .timeout(requestTimeout);

      await clearToken();

      if (response.statusCode != 200 &&
          response.statusCode != 401) {
        throw Exception(
          'Logout gagal.',
        );
      }
    } on TimeoutException {
      await clearToken();

      throw Exception(
        'Server terlalu lama merespons.',
      );
    } catch (e) {
      await clearToken();

      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Logout gagal.',
      );
    }
  }

  // ============================================================
  // GET ME
  // ============================================================

  static Future<Map<String, dynamic>> getMe() async {
    if (authToken == null ||
        authToken!.isEmpty) {
      throw Exception(
        'Tidak ada token login.',
      );
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/me'),
            headers: _headers,
          )
          .timeout(requestTimeout);

      final json = _decodeResponse(response);

      if (response.statusCode == 401) {
        await clearToken();

        throw Exception(
          'Sesi login sudah berakhir.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          json['message'] ??
              'Gagal mengambil data pengguna.',
        );
      }

      if (json['success'] != true) {
        throw Exception(
          json['message'] ??
              'Gagal mengambil data pengguna.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        json['data'] ?? {},
      );

      // Sinkronisasi role terbaru.
      final role =
          data['role']?.toString();

      if (role != null &&
          role.isNotEmpty) {
        userRole = role.toLowerCase();

        await flutterSecureStorage.write(
          key: _roleKey,
          value: userRole!,
        );
      }

      return data;
    } on TimeoutException {
      throw Exception(
        'Server terlalu lama merespons.',
      );
    } on http.ClientException {
      throw Exception(
        'Tidak dapat terhubung ke server.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Gagal mengambil data pengguna.',
      );
    }
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  static Future<void> forgotPassword(
  String email,
) async {
  try {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/forgot-password',
          ),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email.trim(),
          }),
        )
        .timeout(requestTimeout);

    final json = _decodeResponse(response);

    if (response.statusCode == 422) {
      throw Exception(
        json['message'] ??
            'Email tidak valid.',
      );
    }

    if (response.statusCode == 429) {
      throw Exception(
        json['message'] ??
            'Terlalu banyak percobaan.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        json['message'] ??
            'Gagal mengirim link reset password.',
      );
    }
  } on TimeoutException {
    throw Exception(
      'Permintaan terlalu lama.',
    );
  } on http.ClientException {
    throw Exception(
      'Tidak dapat terhubung ke server.',
    );
  } catch (e) {
    if (e is Exception) {
      rethrow;
    }

    throw Exception(
      'Gagal mengirim link reset password.',
    );
  }
}

static Future<void> resetPassword({
  required String token,
  required String email,
  required String password,
  required String passwordConfirmation,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/reset-password',
          ),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'token': token,
            'email': email,
            'password': password,
            'password_confirmation':
                passwordConfirmation,
          }),
        )
        .timeout(requestTimeout);

    final json = _decodeResponse(response);

    if (response.statusCode == 422) {
      throw Exception(
        json['message'] ??
            'Token atau password tidak valid.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        json['message'] ??
            'Gagal mereset password.',
      );
    }
  } on TimeoutException {
    throw Exception(
      'Permintaan terlalu lama.',
    );
  } on http.ClientException {
    throw Exception(
      'Tidak dapat terhubung ke server.',
    );
  } catch (e) {
    if (e is Exception) {
      rethrow;
    }

    throw Exception(
      'Gagal mereset password.',
    );
  }
}

  // ============================================================
  // MANAGER DASHBOARD
  // ============================================================

  static Future<Map<String, dynamic>>
      getManagerDashboard() async {
    if (authToken == null ||
        authToken!.isEmpty) {
      throw Exception(
        'Kamu belum login sebagai manager.',
      );
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/manager/dashboard',
            ),
            headers: _headers,
          )
          .timeout(requestTimeout);

      final json = _decodeResponse(response);

      if (response.statusCode == 401) {
        await clearToken();

        throw Exception(
          'Sesi login sudah berakhir.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'Akses ditolak. Akun ini bukan manager.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          json['message'] ??
              'Gagal mengambil dashboard manager.',
        );
      }

      if (json['success'] != true) {
        throw Exception(
          json['message'] ??
              'Gagal mengambil dashboard manager.',
        );
      }

      return Map<String, dynamic>.from(
        json['data'] ?? {},
      );
    } on TimeoutException {
      throw Exception(
        'Mengambil dashboard terlalu lama.',
      );
    } on http.ClientException {
      throw Exception(
        'Tidak dapat terhubung ke server.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Gagal mengambil dashboard manager.',
      );
    }
  }

  // ============================================================
  // MANAGER PRODUCT
  // ============================================================

  static Future<List<Product>>
      getManagerProducts() async {
    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/manager/products',
          ),
          headers: _headers,
        )
        .timeout(requestTimeout);

    final decoded =
        _decodeResponse(response);

    final data = decoded['data'];

    if (data is! List) {
      throw Exception(
        'Data produk manager tidak valid.',
      );
    }

    return data
        .map(
          (item) => Product.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
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
  if (authToken == null || authToken!.isEmpty) {
    throw Exception(
      'Kamu belum login sebagai manager.',
    );
  }

  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/manager/products'),
  );

  request.headers.addAll(_headers);

  request.fields['category_id'] =
      categoryId.toString();

  request.fields['name'] = name;

  request.fields['description'] =
      description ?? '';

  request.fields['price'] =
      price.toString();

  request.fields['stock'] =
      stock.toString();

  request.fields['is_active'] =
      isActive ? '1' : '0';

  if (imageFile != null) {
    final bytes = await imageFile.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
      ),
    );
  }

  final streamedResponse =
      await request.send().timeout(requestTimeout);

  final response =
      await http.Response.fromStream(
    streamedResponse,
  );

  final decoded = _decodeResponse(response);

  if (response.statusCode < 200 ||
      response.statusCode >= 300) {
    throw Exception(
      decoded['message'] ??
          'Gagal menambahkan produk.',
    );
  }

  return Product.fromJson(
    Map<String, dynamic>.from(
      decoded['data'],
    ),
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
  if (authToken == null || authToken!.isEmpty) {
    throw Exception(
      'Kamu belum login sebagai manager.',
    );
  }

  final request = http.MultipartRequest(
    'POST',
    Uri.parse(
      '$baseUrl/manager/products/$productId',
    ),
  );

  request.headers.addAll(_headers);

  // Laravel method spoofing.
  request.fields['_method'] = 'PUT';

  if (categoryId != null) {
    request.fields['category_id'] =
        categoryId.toString();
  }

  if (name != null) {
    request.fields['name'] = name;
  }

  if (description != null) {
    request.fields['description'] =
        description;
  }

  if (price != null) {
    request.fields['price'] =
        price.toString();
  }

  if (stock != null) {
    request.fields['stock'] =
        stock.toString();
  }

  if (isActive != null) {
    request.fields['is_active'] =
        isActive ? '1' : '0';
  }

  if (imageFile != null) {
    final bytes = await imageFile.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
      ),
    );
  }

  final streamedResponse =
      await request.send().timeout(requestTimeout);

  final response =
      await http.Response.fromStream(
    streamedResponse,
  );

  final decoded = _decodeResponse(response);

  if (response.statusCode < 200 ||
      response.statusCode >= 300) {
    throw Exception(
      decoded['message'] ??
          'Gagal memperbarui produk.',
    );
  }

  return Product.fromJson(
    Map<String, dynamic>.from(
      decoded['data'],
    ),
  );
}

  static Future<Product>
      deactivateManagerProduct(
    int productId,
  ) async {
    final response = await http
        .delete(
          Uri.parse(
            '$baseUrl/manager/products/$productId',
          ),
          headers: _headers,
        )
        .timeout(requestTimeout);

    final decoded =
        _decodeResponse(response);

    return Product.fromJson(
      Map<String, dynamic>.from(
        decoded['data'],
      ),
    );
  }

  static Future<Product>
      activateManagerProduct(
    int productId,
  ) async {
    final response = await http
        .patch(
          Uri.parse(
            '$baseUrl/manager/products/$productId/activate',
          ),
          headers: _headers,
        )
        .timeout(requestTimeout);

    final decoded =
        _decodeResponse(response);

    return Product.fromJson(
      Map<String, dynamic>.from(
        decoded['data'],
      ),
    );
  }

  // ============================================================
// ACCOUNTING / INVENTORY
// ============================================================

static Future<Map<String, dynamic>> getInventorySummary() async {
  final response = await http
      .get(
        Uri.parse('$baseUrl/manager/inventory/summary'),
        headers: _headers,
      )
      .timeout(requestTimeout);

  final body = jsonDecode(response.body);

  if (response.statusCode < 200 ||
      response.statusCode >= 300 ||
      body['success'] != true) {
    throw Exception(
      body['message'] ?? 'Gagal mengambil ringkasan inventaris.',
    );
  }

  return Map<String, dynamic>.from(body['data'] ?? {});
}

static Future<Map<String, dynamic>> previewProductExcel(
  Uint8List bytes,
  String fileName,
) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/manager/products/import/preview'),
  );

  request.headers.addAll(_headers);

  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    ),
  );

  final streamedResponse = await request.send().timeout(
    requestTimeout,
  );

  final response = await http.Response.fromStream(
    streamedResponse,
  );

  final body = jsonDecode(response.body);

  if (response.statusCode < 200 ||
      response.statusCode >= 300 ||
      body['success'] != true) {
    throw Exception(
      body['message'] ?? 'Gagal membaca file Excel.',
    );
  }

  return Map<String, dynamic>.from(
    body['data'] ?? {},
  );
}

static Future<Map<String, dynamic>> confirmProductExcel(
  List<dynamic> rows,
) async {
  final response = await http
      .post(
        Uri.parse(
          '$baseUrl/manager/products/import/confirm',
        ),
        headers: _headers,
        body: jsonEncode({
          'rows': rows,
        }),
      )
      .timeout(requestTimeout);

  final body = jsonDecode(response.body);

  if (response.statusCode < 200 ||
      response.statusCode >= 300 ||
      body['success'] != true) {
    throw Exception(
      body['message'] ?? 'Gagal melakukan import Excel.',
    );
  }

  return Map<String, dynamic>.from(
    body['data'] ?? {},
  );
}

static Future<List<dynamic>> getInventoryProducts({
  String search = '',
}) async {
  final uri = Uri.parse(
    '$baseUrl/manager/inventory/products',
  ).replace(
    queryParameters: search.trim().isEmpty
        ? null
        : {'search': search.trim()},
  );

  final response = await http
      .get(
        uri,
        headers: _headers,
      )
      .timeout(requestTimeout);

  final body = jsonDecode(response.body);

  if (response.statusCode < 200 ||
      response.statusCode >= 300 ||
      body['success'] != true) {
    throw Exception(
      body['message'] ?? 'Gagal mengambil daftar inventaris.',
    );
  }

  return List<dynamic>.from(body['data'] ?? []);
}

static Future<List<dynamic>> getLowStockProducts() async {
  final response = await http
      .get(
        Uri.parse('$baseUrl/manager/inventory/low-stock'),
        headers: _headers,
      )
      .timeout(requestTimeout);

  final body = jsonDecode(response.body);

  if (response.statusCode < 200 ||
      response.statusCode >= 300 ||
      body['success'] != true) {
    throw Exception(
      body['message'] ?? 'Gagal mengambil stok menipis.',
    );
  }

  return List<dynamic>.from(body['data'] ?? []);
}

static Future<List<dynamic>> getInventoryMovements({
  int? productId,
  String? type,
}) async {
  final queryParameters = <String, String>{};

  if (productId != null) {
    queryParameters['product_id'] = productId.toString();
  }

  if (type != null && type.trim().isNotEmpty) {
    queryParameters['type'] = type.trim();
  }

  final uri = Uri.parse(
    '$baseUrl/manager/inventory-movements',
  ).replace(
    queryParameters:
        queryParameters.isEmpty ? null : queryParameters,
  );

  final response = await http
      .get(
        uri,
        headers: _headers,
      )
      .timeout(requestTimeout);

  final body = jsonDecode(response.body);

  if (response.statusCode < 200 ||
      response.statusCode >= 300 ||
      body['success'] != true) {
    throw Exception(
      body['message'] ?? 'Gagal mengambil riwayat inventaris.',
    );
  }

  final data = body['data'];

  // Endpoint menggunakan paginate(30),
  // sehingga Laravel mengembalikan object pagination.
  if (data is Map && data['data'] is List) {
    return List<dynamic>.from(data['data']);
  }

  if (data is List) {
    return List<dynamic>.from(data);
  }

  return [];
}

static Future<Map<String, dynamic>> inventoryStockIn({
  required int productId,
  required int quantity,
  String? note,
}) async {
  final response = await http
      .post(
        Uri.parse(
          '$baseUrl/manager/inventory/products/$productId/stock-in',
        ),
        headers: _headers,
        body: jsonEncode({
          'quantity': quantity,
          if (note != null && note.trim().isNotEmpty)
            'note': note.trim(),
        }),
      )
      .timeout(requestTimeout);

  final body = jsonDecode(response.body);

  if (response.statusCode < 200 ||
      response.statusCode >= 300 ||
      body['success'] != true) {
    throw Exception(
      body['message'] ?? 'Gagal menambahkan stok.',
    );
  }

  return Map<String, dynamic>.from(body['data'] ?? {});
}

static Future<Map<String, dynamic>> inventoryStockOut({
  required int productId,
  required int quantity,
  String type = 'out',
  String? note,
}) async {
  final response = await http
      .post(
        Uri.parse(
          '$baseUrl/manager/inventory/products/$productId/stock-out',
        ),
        headers: _headers,
        body: jsonEncode({
          'quantity': quantity,
          'type': type,
          if (note != null && note.trim().isNotEmpty)
            'note': note.trim(),
        }),
      )
      .timeout(requestTimeout);

  final body = jsonDecode(response.body);

  if (response.statusCode < 200 ||
      response.statusCode >= 300 ||
      body['success'] != true) {
    throw Exception(
      body['message'] ?? 'Gagal mengurangi stok.',
    );
  }

  return Map<String, dynamic>.from(body['data'] ?? {});
}

static Future<Map<String, dynamic>> inventoryAdjustment({
  required int productId,
  required int stock,
  String? note,
}) async {
  final response = await http
      .post(
        Uri.parse(
          '$baseUrl/manager/inventory/products/$productId/adjust-stock',
        ),
        headers: _headers,
        body: jsonEncode({
          'stock': stock,
          if (note != null && note.trim().isNotEmpty)
            'note': note.trim(),
        }),
      )
      .timeout(requestTimeout);

  final body = jsonDecode(response.body);

  if (response.statusCode < 200 ||
      response.statusCode >= 300 ||
      body['success'] != true) {
    throw Exception(
      body['message'] ?? 'Gagal menyesuaikan stok.',
    );
  }

  return Map<String, dynamic>.from(body['data'] ?? {});
}

  // ============================================================
  // PRODUCTS
  // ============================================================

  static Future<List<Product>>
      getProducts() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/products'),
            headers: _headers,
          )
          .timeout(requestTimeout);

      final json =
          _decodeResponse(response);

      if (response.statusCode == 401) {
        await clearToken();

        throw Exception(
          'Sesi login sudah berakhir.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          json['message'] ??
              'Gagal mengambil produk.',
        );
      }

      if (json['success'] != true) {
        throw Exception(
          json['message'] ??
              'Gagal mengambil produk.',
        );
      }

      final List<dynamic> data =
          json['data'] ?? [];

      return data
          .map(
            (item) => Product.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on TimeoutException {
      throw Exception(
        'Mengambil produk terlalu lama.',
      );
    } on http.ClientException {
      throw Exception(
        'Tidak dapat terhubung ke server.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Gagal mengambil produk.',
      );
    }
  }

  // ============================================================
  // PRODUCT DETAIL
  // ============================================================

  static Future<Product> getProduct(
    int id,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/products/$id',
            ),
            headers: _headers,
          )
          .timeout(requestTimeout);

      final json =
          _decodeResponse(response);

      if (response.statusCode == 401) {
        await clearToken();

        throw Exception(
          'Sesi login sudah berakhir.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          json['message'] ??
              'Gagal mengambil detail produk.',
        );
      }

      if (json['success'] != true) {
        throw Exception(
          json['message'] ??
              'Gagal mengambil detail produk.',
        );
      }

      return Product.fromJson(
        Map<String, dynamic>.from(
          json['data'],
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Mengambil detail produk terlalu lama.',
      );
    } on http.ClientException {
      throw Exception(
        'Tidak dapat terhubung ke server.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Gagal mengambil detail produk.',
      );
    }
  }

  // ============================================================
  // ORDERS
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      getOrders() async {
    if (authToken == null ||
        authToken!.isEmpty) {
      throw Exception(
        'Kamu belum login. Silakan login terlebih dahulu.',
      );
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/orders'),
            headers: _headers,
          )
          .timeout(requestTimeout);

      final json =
          _decodeResponse(response);

      if (response.statusCode == 401) {
        await clearToken();

        throw Exception(
          'Sesi login sudah berakhir. Silakan login kembali.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          json['message'] ??
              'Gagal mengambil riwayat pesanan.',
        );
      }

      if (json['success'] != true) {
        throw Exception(
          json['message'] ??
              'Gagal mengambil riwayat pesanan.',
        );
      }

      final List<dynamic> data =
          json['data'] ?? [];

      return data
          .map(
            (item) =>
                Map<String, dynamic>.from(item),
          )
          .toList();
    } on TimeoutException {
      throw Exception(
        'Mengambil pesanan terlalu lama.',
      );
    } on http.ClientException {
      throw Exception(
        'Tidak dapat terhubung ke server.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Gagal mengambil riwayat pesanan.',
      );
    }
  }

  // ============================================================
  // CREATE ORDER
  // ============================================================

  static Future<Map<String, dynamic>>
      createOrder({
    required String pickupMethod,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    if (authToken == null ||
        authToken!.isEmpty) {
      throw Exception(
        'Kamu belum login. Silakan login terlebih dahulu.',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/orders'),
            headers: _headers,
            body: jsonEncode({
              'pickup_method': pickupMethod,
              'payment_method': paymentMethod,
              'items': items,
            }),
          )
          .timeout(requestTimeout);

      final json =
          _decodeResponse(response);

      if (response.statusCode == 401) {
        await clearToken();

        throw Exception(
          'Sesi login sudah berakhir. Silakan login kembali.',
        );
      }

      if (response.statusCode != 201) {
        throw Exception(
          json['message'] ??
              'Gagal membuat pesanan.',
        );
      }

      if (json['success'] != true) {
        throw Exception(
          json['message'] ??
              'Gagal membuat pesanan.',
        );
      }

      return Map<String, dynamic>.from(
        json['data'] ?? {},
      );
    } on TimeoutException {
      throw Exception(
        'Pembuatan pesanan terlalu lama.',
      );
    } on http.ClientException {
      throw Exception(
        'Tidak dapat terhubung ke server.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Gagal membuat pesanan.',
      );
    }
  }

  // ============================================================
  // MANAGER ORDERS
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      getManagerOrders() async {
    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/manager/orders',
          ),
          headers: _headers,
        )
        .timeout(requestTimeout);

    final decoded =
        _decodeResponse(response);

    final data = decoded['data'];

    if (data is! List) {
      throw Exception(
        'Data pesanan manager tidak valid.',
      );
    }

    return data
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }

  // ============================================================
  // MANAGER ORDER STATUS
  // ============================================================

  static Future<Map<String, dynamic>>
      updateManagerOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final response = await http
        .patch(
          Uri.parse(
            '$baseUrl/manager/orders/$orderId/status',
          ),
          headers: _headers,
          body: jsonEncode({
            'status': status,
          }),
        )
        .timeout(requestTimeout);

    return _decodeResponse(response);
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      getCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/categories'),
            headers: _headers,
          )
          .timeout(requestTimeout);

      final json =
          _decodeResponse(response);

      if (response.statusCode == 401) {
        await clearToken();

        throw Exception(
          'Sesi login sudah berakhir.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          json['message'] ??
              'Gagal mengambil kategori.',
        );
      }

      if (json['success'] != true) {
        throw Exception(
          json['message'] ??
              'Gagal mengambil kategori.',
        );
      }

      final List<dynamic> data =
          json['data'] ?? [];

      return data
          .map(
            (item) =>
                Map<String, dynamic>.from(item),
          )
          .toList();
    } on TimeoutException {
      throw Exception(
        'Mengambil kategori terlalu lama.',
      );
    } on http.ClientException {
      throw Exception(
        'Tidak dapat terhubung ke server.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Gagal mengambil kategori.',
      );
    }
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  static Map<String, dynamic>
      _decodeResponse(
    http.Response response,
  ) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      final decoded =
          jsonDecode(response.body);

      if (decoded
          is Map<String, dynamic>) {
        return decoded;
      }

      return {};
    } catch (_) {
      throw Exception(
        'Server mengirim response yang tidak valid.',
      );
    }
  }
}