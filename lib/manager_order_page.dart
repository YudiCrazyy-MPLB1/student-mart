import 'package:flutter/material.dart';

import 'api_service.dart';

class ManagerOrderPage extends StatefulWidget {
  const ManagerOrderPage({super.key});

  @override
  State<ManagerOrderPage> createState() => _ManagerOrderPageState();
}

class _ManagerOrderPageState extends State<ManagerOrderPage> {
  List<Map<String, dynamic>> orders = [];

  bool isLoading = true;
  String searchQuery = '';
  String selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.getManagerOrders();

      if (!mounted) return;

      setState(() {
        orders = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Gagal mengambil pesanan: $e',
        isError: true,
      );
    }
  }

  Future<void> updateOrderStatus(
  Map<String, dynamic> order,
  String newStatus,
) async {
  final orderId = int.tryParse(
    order['id'].toString(),
  );

  if (orderId == null) {
    showMessage(
      'ID pesanan tidak valid.',
      isError: true,
    );
    return;
  }

  try {
    await ApiService.updateManagerOrderStatus(
      orderId: orderId,
      status: newStatus,
    );

    if (!mounted) return;

    Navigator.pop(context);

    showMessage(
      'Status pesanan berhasil diubah menjadi '
      '${formatStatus(newStatus)}.',
    );

    await loadOrders();
  } catch (e) {
    if (!mounted) return;

    showMessage(
      'Gagal mengubah status: $e',
      isError: true,
    );
  }
}

  List<Map<String, dynamic>> get filteredOrders {
    return orders.where((order) {
      final status =
          order['status']?.toString().toLowerCase() ?? '';

      final orderNumber =
          order['order_number']?.toString().toLowerCase() ?? '';

      final user = order['user'];

      final userName = user is Map
          ? user['name']?.toString().toLowerCase() ?? ''
          : '';

      final matchesSearch =
          searchQuery.trim().isEmpty ||
          orderNumber.contains(searchQuery.toLowerCase()) ||
          userName.contains(searchQuery.toLowerCase());

      final matchesStatus =
          selectedStatus == 'all' ||
          status == selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  String formatPrice(dynamic value) {
    final price = int.tryParse(value.toString()) ?? 0;

    return 'Rp ${price.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}';
  }

  String formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';

      case 'processing':
        return 'Diproses';

      case 'completed':
      case 'complete':
        return 'Selesai';

      case 'cancelled':
      case 'canceled':
        return 'Dibatalkan';

      default:
        return status;
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;

      case 'processing':
        return Colors.blue;

      case 'completed':
      case 'complete':
        return Colors.green;

      case 'cancelled':
      case 'canceled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void showStatusMenu(
  Map<String, dynamic> order,
) {
  final currentStatus =
      order['status']?.toString().toLowerCase() ?? '';

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Ubah Status Pesanan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _statusOption(
                order,
                'pending',
                Icons.hourglass_empty,
                currentStatus,
              ),

              _statusOption(
                order,
                'processing',
                Icons.inventory_2,
                currentStatus,
              ),

              _statusOption(
                order,
                'completed',
                Icons.check_circle,
                currentStatus,
              ),

              _statusOption(
                order,
                'cancelled',
                Icons.cancel,
                currentStatus,
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void showOrderDetail(
    Map<String, dynamic> order,
  ) {
    final user = order['user'];

    final customerName = user is Map
        ? user['name']?.toString() ?? 'Tidak diketahui'
        : 'Tidak diketahui';

    final customerEmail = user is Map
        ? user['email']?.toString() ?? '-'
        : '-';

    final items = order['items'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['order_number']?.toString() ??
                        'Pesanan',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text('Pelanggan: $customerName'),
                  Text('Email: $customerEmail'),

                  const SizedBox(height: 16),

                  const Text(
                    'Produk',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (items is List && items.isNotEmpty)
                    ...items.map((item) {
                      final product = item['product'];

                      final productName = product is Map
                          ? product['name']?.toString() ??
                              'Produk'
                          : 'Produk';

                      final quantity =
                          item['quantity'] ?? 0;

                      final price = item['price'] ?? 0;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(productName),
                        subtitle: Text(
                          '$quantity x ${formatPrice(price)}',
                        ),
                      );
                    })
                  else
                    const Text(
                      'Tidak ada detail produk.',
                    ),

                  const Divider(),

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
                        formatPrice(order['total']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () {
      showStatusMenu(order);
    },
    icon: const Icon(Icons.sync),
    label: const Text('Ubah Status'),
  ),
),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget statusChip(String status) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        formatStatus(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = filteredOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pesanan'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nomor pesanan / pelanggan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          SizedBox(
            height: 55,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              children: [
                _statusFilter('all', 'Semua'),
                _statusFilter('pending', 'Menunggu'),
                _statusFilter('processing', 'Diproses'),
                _statusFilter('completed', 'Selesai'),
                _statusFilter('cancelled', 'Dibatalkan'),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : visibleOrders.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada pesanan.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            20,
                          ),
                          itemCount: visibleOrders.length,
                          itemBuilder: (context, index) {
                            final order =
                                visibleOrders[index];

                            final user = order['user'];

                            final customerName = user is Map
                                ? user['name']?.toString() ??
                                    'Tidak diketahui'
                                : 'Tidak diketahui';

                            final status =
                                order['status']
                                        ?.toString() ??
                                    'unknown';

                            return Card(
  margin: const EdgeInsets.only(
    bottom: 12,
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER ORDER
        Row(
          children: [
            const Icon(
              Icons.receipt_long,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                order['order_number']?.toString() ??
                    'Pesanan',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),

            statusChip(status),
          ],
        ),

        const SizedBox(height: 12),

        // CUSTOMER
        Text(
          customerName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 12),

        // DAFTAR PRODUK
        const Text(
          'Produk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 6),

        if (order['items'] is List &&
            (order['items'] as List).isNotEmpty)
          ...(order['items'] as List).map(
            (item) {
              final product = item['product'];

              final productName = product is Map
                  ? product['name']?.toString() ??
                      'Produk'
                  : 'Produk';

              final quantity =
                  int.tryParse(
                        item['quantity']?.toString() ??
                            '0',
                      ) ??
                      0;

              final price =
                  int.tryParse(
                        item['price']?.toString() ??
                            '0',
                      ) ??
                      0;

              final subtotal =
                  quantity * price;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 5,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            '$quantity × ${formatPrice(price)}',
                            style: TextStyle(
                              color: Colors
                                  .grey
                                  .shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      formatPrice(subtotal),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        else
          const Text(
            'Tidak ada produk.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

        const SizedBox(height: 8),

        const Divider(),

        const SizedBox(height: 4),

        // TOTAL
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),

            Text(
              formatPrice(order['total']),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // PICKUP
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                order['pickup_method']?.toString() ??
                    '-',
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // PAYMENT
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.payment_outlined,
              size: 18,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                order['payment_method']?.toString() ??
                    '-',
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // BUTTON UBAH STATUS
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showStatusMenu(order);
            },
            icon: const Icon(
              Icons.sync,
            ),
            label: const Text(
              'Ubah Status',
            ),
          ),
        ),
      ],
    ),
  ),
);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statusFilter(
    String value,
    String label,
  ) {
    final selected = selectedStatus == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            selectedStatus = value;
          });
        },
      ),
    );
  }

  Widget _statusOption(
  Map<String, dynamic> order,
  String status,
  IconData icon,
  String currentStatus,
) {
  final isCurrent = currentStatus == status;

  return ListTile(
    leading: Icon(
      icon,
      color: statusColor(status),
    ),
    title: Text(
      formatStatus(status),
    ),
    trailing: isCurrent
        ? const Icon(Icons.check)
        : null,
    enabled: !isCurrent,
    onTap: isCurrent
        ? null
        : () async {
            Navigator.pop(context);

            await updateOrderStatus(
              order,
              status,
            );
          },
  );
}
}