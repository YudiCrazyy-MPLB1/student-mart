import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product_model.dart';

class CartItem {
  Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  int get subtotal => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(
        Map<String, dynamic>.from(json['product'] as Map),
      ),
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
    );
  }
}

class CartController extends ChangeNotifier {
  static const String _storageKey = 'student_mart_saved_cart';

  final List<CartItem> _items = [];
  bool _isLoaded = false;

  CartController() {
    _loadFromPrefs();
  }

  bool get isLoaded => _isLoaded;

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount {
    return _items.fold(0, (total, item) => total + item.quantity);
  }

  int get total {
    return _items.fold(0, (total, item) => total + item.subtotal);
  }

  CartItem? getItem(Product product) {
    try {
      return _items.firstWhere((item) => item.product.id == product.id);
    } catch (_) {
      return null;
    }
  }

  void addToCart(Product product) {
    if (product.stock <= 0) {
      return;
    }

    final existingItem = getItem(product);

    if (existingItem != null) {
      if (existingItem.quantity < product.stock) {
        existingItem.quantity++;
      }
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }

    notifyListeners();
    _saveToPrefs();
  }

  void decreaseQuantity(Product product) {
    final existingItem = getItem(product);

    if (existingItem == null) {
      return;
    }

    if (existingItem.quantity > 1) {
      existingItem.quantity--;
    } else {
      _items.remove(existingItem);
    }

    notifyListeners();
    _saveToPrefs();
  }

  void removeFromCart(Product product) {
    _items.removeWhere((item) => item.product.id == product.id);

    notifyListeners();
    _saveToPrefs();
  }

  /// Samakan isi keranjang dengan data produk terbaru dari server (harga,
  /// stok, status aktif). Produk yang tidak ada di [latest] dibiarkan apa
  /// adanya. Mengembalikan daftar catatan perubahan untuk ditampilkan ke user;
  /// kosong berarti tidak ada yang berubah.
  List<String> syncWithProducts(List<Product> latest) {
    final byId = {for (final p in latest) p.id: p};
    final notes = <String>[];

    for (final item in List<CartItem>.of(_items)) {
      final fresh = byId[item.product.id];
      if (fresh == null) {
        _items.remove(item);
        notes.add('${item.product.name} tidak tersedia lagi dan dihapus dari keranjang.');
        continue;
      }

      final name = fresh.name;

      if (!fresh.isActive || fresh.stock <= 0) {
        _items.remove(item);
        notes.add('$name tidak tersedia lagi dan dihapus dari keranjang.');
        continue;
      }

      if (fresh.price != item.product.price) {
        notes.add('Harga $name berubah menjadi Rp${fresh.price}.');
      }

      if (item.quantity > fresh.stock) {
        item.quantity = fresh.stock;
        notes.add('Jumlah $name disesuaikan dengan stok (${fresh.stock}).');
      }

      item.product = fresh;
    }

    if (notes.isNotEmpty) {
      notifyListeners();
      _saveToPrefs();
    }
    return notes;
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    _saveToPrefs();
  }

  // ============================================================
  // PERSISTENSI SHARED PREFERENCES
  // ============================================================

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_storageKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson);
        if (decoded is List) {
          // Item yang sudah ditambahkan user sebelum load selesai tidak boleh
          // hilang: gabungkan, jangan clear().
          final addedBeforeLoad = List<CartItem>.of(_items);
          _items.clear();
          for (final rawItem in decoded) {
            try {
              if (rawItem is Map) {
                _items.add(
                  CartItem.fromJson(Map<String, dynamic>.from(rawItem)),
                );
              }
            } catch (e) {
              debugPrint('Gagal deserialize item keranjang: $e');
            }
          }

          for (final added in addedBeforeLoad) {
            final existing = getItem(added.product);
            if (existing == null) {
              _items.add(added);
            } else {
              existing.quantity = (existing.quantity + added.quantity)
                  .clamp(1, added.product.stock > 0 ? added.product.stock : 1)
                  .toInt();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Gagal membaca keranjang dari SharedPreferences: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_items.isEmpty) {
        await prefs.remove(_storageKey);
      } else {
        final encodedList = _items.map((item) => item.toJson()).toList();
        await prefs.setString(_storageKey, jsonEncode(encodedList));
      }
    } catch (e) {
      debugPrint('Gagal menyimpan keranjang ke SharedPreferences: $e');
    }
  }
}
