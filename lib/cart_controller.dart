import 'package:flutter/foundation.dart';

import 'product_model.dart';

class CartItem {
  Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  int get subtotal => product.price * quantity;
}

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];

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
  }

  void removeFromCart(Product product) {
    _items.removeWhere((item) => item.product.id == product.id);

    notifyListeners();
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

    if (notes.isNotEmpty) notifyListeners();
    return notes;
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}