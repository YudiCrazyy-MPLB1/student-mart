import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'product_model.dart';

// Import domain API modules
import 'api/advertisement_api.dart';
import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'api/consignment_api.dart';
import 'api/inventory_api.dart';
import 'api/manager_api.dart';
import 'api/order_api.dart';
import 'api/product_api.dart';

// Re-export semua modul agar file lama atau baru bisa mengimpor
// langsung modul spesifik atau via api_service.dart.
export 'api/advertisement_api.dart';
export 'api/api_client.dart';
export 'api/auth_api.dart';
export 'api/consignment_api.dart';
export 'api/inventory_api.dart';
export 'api/manager_api.dart';
export 'api/order_api.dart';
export 'api/product_api.dart';

/// Facade utama untuk semua layanan API Student Mart.
///
/// Implementasi endpoint telah dimodularisasi ke dalam folder `lib/api/`:
///   - [ApiClient]: HTTP client pipeline, token, headers, & interceptor 401
///   - [AuthApi]: login, register, logout, getMe, password reset
///   - [ProductApi]: katalog produk siswa & kategori
///   - [OrderApi]: checkout & riwayat pesanan siswa
///   - [ManagerApi]: dashboard, katalog, & pesanan manager
///   - [InventoryApi]: stok, pergerakan barang, ringkasan, & import Excel
///   - [ConsignmentApi]: sistem konsinyasi supplier & verifikasi
///   - [AdvertisementApi]: pengajuan & verifikasi iklan
///
/// Semua method statis di sini tetap dipertahankan untuk backward compatibility
/// 100% sehingga kode lama tidak perlu diubah.
class ApiService {
  // ============================================================
  // CONFIG & STATE DELEGATION
  // ============================================================

  static FlutterSecureStorage get flutterSecureStorage =>
      ApiClient.flutterSecureStorage;

  static String get baseUrl => ApiClient.baseUrl;

  static Duration get requestTimeout => ApiClient.requestTimeout;
  static Duration get uploadTimeout => ApiClient.uploadTimeout;

  static String? get authToken => ApiClient.authToken;
  static set authToken(String? value) => ApiClient.authToken = value;

  static String? get userRole => ApiClient.userRole;
  static set userRole(String? value) => ApiClient.userRole = value;

  static void Function()? get onUnauthorized => ApiClient.onUnauthorized;
  static set onUnauthorized(void Function()? value) =>
      ApiClient.onUnauthorized = value;

  // ============================================================
  // TOKEN & IMAGE URL
  // ============================================================

  static Future<void> loadToken() => ApiClient.loadToken();

  static Future<void> saveToken(String token, String? role) =>
      ApiClient.saveToken(token, role);

  static Future<void> clearToken() => ApiClient.clearToken();

  static String getImageUrl(String? image) => ApiClient.getImageUrl(image);

  // ============================================================
  // AUTH
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) =>
      AuthApi.login(email: email, password: password);

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String kodeUndangan,
  }) =>
      AuthApi.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        kodeUndangan: kodeUndangan,
      );

  static Future<void> logout() => AuthApi.logout();

  static Future<Map<String, dynamic>> getMe() => AuthApi.getMe();

  static Future<void> forgotPassword(String email) =>
      AuthApi.forgotPassword(email);

  static Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      AuthApi.resetPassword(
        token: token,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

  // ============================================================
  // PRODUCTS & CATEGORIES
  // ============================================================

  static Future<List<Product>> getProducts() => ProductApi.getProducts();

  static Future<Product> getProduct(int id) => ProductApi.getProduct(id);

  static Future<List<Map<String, dynamic>>> getCategories() =>
      ProductApi.getCategories();

  // ============================================================
  // ORDERS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getOrders() => OrderApi.getOrders();

  static Future<Map<String, dynamic>> createOrder({
    required String pickupMethod,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) =>
      OrderApi.createOrder(
        pickupMethod: pickupMethod,
        paymentMethod: paymentMethod,
        items: items,
      );

  // ============================================================
  // MANAGER DASHBOARD, PRODUCTS & ORDERS
  // ============================================================

  static Future<Map<String, dynamic>> getManagerDashboard() =>
      ManagerApi.getManagerDashboard();

  static Future<List<Product>> getManagerProducts() =>
      ManagerApi.getManagerProducts();

  static Future<Product> createManagerProduct({
    required int categoryId,
    required String name,
    String? description,
    required int price,
    required int stock,
    XFile? imageFile,
    bool isActive = true,
  }) =>
      ManagerApi.createManagerProduct(
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        stock: stock,
        imageFile: imageFile,
        isActive: isActive,
      );

  static Future<Product> updateManagerProduct({
    required int productId,
    int? categoryId,
    String? name,
    String? description,
    int? price,
    int? stock,
    XFile? imageFile,
    bool? isActive,
  }) =>
      ManagerApi.updateManagerProduct(
        productId: productId,
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        stock: stock,
        imageFile: imageFile,
        isActive: isActive,
      );

  static Future<Product> deactivateManagerProduct(int productId) =>
      ManagerApi.deactivateManagerProduct(productId);

  static Future<Product> activateManagerProduct(int productId) =>
      ManagerApi.activateManagerProduct(productId);

  static Future<List<Map<String, dynamic>>> getManagerOrders() =>
      ManagerApi.getManagerOrders();

  static Future<Map<String, dynamic>> updateManagerOrderStatus({
    required int orderId,
    required String status,
  }) =>
      ManagerApi.updateManagerOrderStatus(orderId: orderId, status: status);

  // ============================================================
  // ACCOUNTING / INVENTORY
  // ============================================================

  static Future<Map<String, dynamic>> getInventorySummary() =>
      InventoryApi.getInventorySummary();

  static Future<Map<String, dynamic>> previewProductExcel(
    Uint8List bytes,
    String fileName,
  ) =>
      InventoryApi.previewProductExcel(bytes, fileName);

  static Future<Map<String, dynamic>> confirmProductExcel(List<dynamic> rows) =>
      InventoryApi.confirmProductExcel(rows);

  static Future<List<dynamic>> getInventoryProducts({String search = ''}) =>
      InventoryApi.getInventoryProducts(search: search);

  static Future<List<dynamic>> getLowStockProducts() =>
      InventoryApi.getLowStockProducts();

  static Future<List<dynamic>> getInventoryMovements({
    int? productId,
    String? type,
  }) =>
      InventoryApi.getInventoryMovements(productId: productId, type: type);

  static Future<Map<String, dynamic>> inventoryStockIn({
    required int productId,
    required int quantity,
    String? note,
  }) =>
      InventoryApi.inventoryStockIn(
        productId: productId,
        quantity: quantity,
        note: note,
      );

  static Future<Map<String, dynamic>> inventoryStockOut({
    required int productId,
    required int quantity,
    String type = 'out',
    String? note,
  }) =>
      InventoryApi.inventoryStockOut(
        productId: productId,
        quantity: quantity,
        type: type,
        note: note,
      );

  static Future<Map<String, dynamic>> inventoryAdjustment({
    required int productId,
    required int stock,
    String? note,
  }) =>
      InventoryApi.inventoryAdjustment(
        productId: productId,
        stock: stock,
        note: note,
      );

  // ============================================================
  // CONSIGNMENT (KONSINYASI)
  // ============================================================

  static Future<Map<String, dynamic>> agreeTos() => ConsignmentApi.agreeTos();

  static Future<Map<String, dynamic>> submitConsignmentProduct({
    required String name,
    required String description,
    required String price,
    required String stock,
    required List<int> imageBytes,
    required String imageName,
  }) =>
      ConsignmentApi.submitConsignmentProduct(
        name: name,
        description: description,
        price: price,
        stock: stock,
        imageBytes: imageBytes,
        imageName: imageName,
      );

  static Future<List<dynamic>> getPendingProducts() =>
      ConsignmentApi.getPendingProducts();

  static Future<Map<String, dynamic>> verifyProduct({
    required int productId,
    required String status,
  }) =>
      ConsignmentApi.verifyProduct(productId: productId, status: status);

  static Future<List<dynamic>> getMyConsignmentProducts() =>
      ConsignmentApi.getMyConsignmentProducts();

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
  }) =>
      AdvertisementApi.submitAdvertisement(
        title: title,
        targetUrl: targetUrl,
        packageType: packageType,
        paymentMethod: paymentMethod,
        imageBytes: imageBytes,
        imageName: imageName,
      );

  static Future<List<dynamic>> getPendingAds() =>
      AdvertisementApi.getPendingAds();

  static Future<Map<String, dynamic>> verifyAd({
    required int adId,
    required String action,
  }) =>
      AdvertisementApi.verifyAd(adId: adId, action: action);

  static Future<List<dynamic>> getActiveAds() =>
      AdvertisementApi.getActiveAds();
}
