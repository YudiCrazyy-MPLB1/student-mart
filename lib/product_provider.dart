import 'package:flutter/material.dart';
import 'api_exception.dart';
import 'api_service.dart';
import 'product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    // Jika data sudah ada dan tidak dipaksa refresh, jangan load ulang
    if (_products.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await ApiService.getProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e is ApiException
          ? e.message
          : 'Terjadi kesalahan saat memuat produk.';
      notifyListeners();
    }
  }
}