import 'product_model.dart';

class OrderItem {
  final Product product;
  final int quantity;

  OrderItem({
    required this.product,
    required this.quantity,
  });

  int get subtotal => product.price * quantity;
}

class Order {
  final String id;
  final List<OrderItem> items;
  final int total;
  final String pickupMethod;
  final String paymentMethod;
  String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.pickupMethod,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });
}