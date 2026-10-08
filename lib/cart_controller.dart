import 'package:flutter/foundation.dart';
import 'product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  int get subtotal => product.price * quantity;
}

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount {
    return _items.fold(
      0,
      (total, item) => total + item.quantity,
    );
  }

  int get total {
    return _items.fold(
      0,
      (total, item) => total + item.subtotal,
    );
  }

  CartItem? getItem(Product product) {
    try {
      return _items.firstWhere(
        (item) => item.product.id == product.id,
      );
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
      _items.add(
        CartItem(
          product: product,
          quantity: 1,
        ),
      );
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
    _items.removeWhere(
      (item) => item.product.id == product.id,
    );

    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

final cartController = CartController();