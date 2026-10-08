import 'package:flutter/material.dart';
import 'api_service.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<Map<String, dynamic>> orders = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getOrders();

      if (!mounted) return;

      setState(() {
        orders = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  String formatRupiah(dynamic value) {
    final number = int.tryParse(value.toString()) ?? 0;

    final text = number.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 &&
          (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return 'Rp ${buffer.toString()}';
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Selesai':
        return Colors.green;

      case 'Siap Diambil':
        return Colors.blue;

      case 'Diproses':
        return Colors.orange;

      case 'Menunggu Pembayaran':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),

              const SizedBox(height: 16),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _loadOrders,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          children: const [
            SizedBox(height: 180),

            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey,
            ),

            SizedBox(height: 20),

            Center(
              child: Text(
                'Belum ada pesanan.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 8),

            Center(
              child: Text(
                'Pesanan kamu akan muncul di sini.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,

      child: ListView.builder(
        padding: const EdgeInsets.all(16),

        itemCount: orders.length,

        itemBuilder: (context, index) {
          final order = orders[index];

          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order,
  ) {
    final String orderNumber =
        order['order_number'] ?? '-';

    final String status =
        order['status'] ?? '-';

    final String pickupMethod =
        order['pickup_method'] ?? '-';

    final String paymentMethod =
        order['payment_method'] ?? '-';

    final int total =
        int.tryParse(
          order['total'].toString(),
        ) ??
        0;

    final List<dynamic> items =
        order['items'] ?? [];

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                Expanded(
                  child: Text(
                    orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: statusColor(status)
                        .withValues(alpha: 0.12),

                    borderRadius:
                        BorderRadius.circular(20),
                  ),

                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            ...items.map(
              (item) {
                final product =
                    item['product'] ?? {};

                final String name =
                    product['name'] ?? 'Produk';

                final int quantity =
                    int.tryParse(
                      item['quantity']
                          .toString(),
                    ) ??
                    0;

                final int subtotal =
                    int.tryParse(
                      item['subtotal']
                          .toString(),
                    ) ??
                    0;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),

                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$name x$quantity',
                        ),
                      ),

                      Text(
                        formatRupiah(subtotal),
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Divider(height: 20),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  formatRupiah(total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 18,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    pickupMethod,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(
                  Icons.payment_outlined,
                  size: 18,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    paymentMethod,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}