import 'package:flutter/foundation.dart';
import 'order_model.dart';

class OrderController extends ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  void addOrder(Order order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void updateStatus(String orderId, String status) {
    final index = _orders.indexWhere(
      (order) => order.id == orderId,
    );

    if (index == -1) return;

    _orders[index].status = status;
    notifyListeners();
  }
}

final orderController = OrderController();