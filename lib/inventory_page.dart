import 'package:flutter/material.dart';

import 'api_service.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<dynamic> products = [];
  bool isLoading = true;
  String search = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.getInventoryProducts(
        search: search,
      );

      if (!mounted) return;

      setState(() {
        products = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatRupiah(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(text[i]);
    }

    return 'Rp ${buffer.toString()}';
  }

  Future<void> _stockIn(Map<String, dynamic> product) async {
    final quantityController = TextEditingController();
    final noteController = TextEditingController();

    await _showStockDialog(
      title: 'Tambah Stok',
      product: product,
      quantityController: quantityController,
      noteController: noteController,
      action: () async {
        final quantity = int.tryParse(quantityController.text);

        if (quantity == null || quantity <= 0) {
          throw Exception('Jumlah stok harus lebih dari 0.');
        }

        await ApiService.inventoryStockIn(
          productId: _toInt(product['id']),
          quantity: quantity,
          note: noteController.text,
        );
      },
    );
  }

  Future<void> _stockOut(Map<String, dynamic> product) async {
    final quantityController = TextEditingController();
    final noteController = TextEditingController();

    await _showStockDialog(
      title: 'Kurangi Stok',
      product: product,
      quantityController: quantityController,
      noteController: noteController,
      action: () async {
        final quantity = int.tryParse(quantityController.text);

        if (quantity == null || quantity <= 0) {
          throw Exception('Jumlah stok harus lebih dari 0.');
        }

        await ApiService.inventoryStockOut(
          productId: _toInt(product['id']),
          quantity: quantity,
          type: 'out',
          note: noteController.text,
        );
      },
    );
  }

  Future<void> _adjustment(Map<String, dynamic> product) async {
    final stockController = TextEditingController(
      text: _toInt(product['stock']).toString(),
    );

    final noteController = TextEditingController();

    await _showStockDialog(
      title: 'Penyesuaian Stok',
      product: product,
      quantityController: stockController,
      noteController: noteController,
      isAdjustment: true,
      action: () async {
        final stock = int.tryParse(stockController.text);

        if (stock == null || stock < 0) {
          throw Exception('Stok tidak boleh kurang dari 0.');
        }

        await ApiService.inventoryAdjustment(
          productId: _toInt(product['id']),
          stock: stock,
          note: noteController.text,
        );
      },
    );
  }

  Future<void> _showStockDialog({
    required String title,
    required Map<String, dynamic> product,
    required TextEditingController quantityController,
    required TextEditingController noteController,
    required Future<void> Function() action,
    bool isAdjustment = false,
  }) async {
    bool loading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final stock = _toInt(product['stock']);

            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']?.toString() ?? 'Produk',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stok saat ini: $stock',
                    style: TextStyle(
                      color: stock <= 0
                          ? Colors.red
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isAdjustment
                          ? 'Stok baru'
                          : 'Jumlah',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setDialogState(() {
                            loading = true;
                          });

                          try {
                            await action();

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            await _loadProducts();

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$title berhasil.',
                                ),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              loading = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                              ),
                            );
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    quantityController.dispose();
    noteController.dispose();
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'Produk';
    final stock = _toInt(product['stock']);
    final minimumStock = _toInt(product['minimum_stock']);
    final price = _toInt(product['price']);

    final isOutOfStock = stock <= 0;
    final isLowStock = stock > 0 && stock <= 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Icon(
                    isOutOfStock
                        ? Icons.remove_shopping_cart_rounded
                        : Icons.inventory_2_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_formatRupiah(price)),
                    ],
                  ),
                ),
                _buildStockBadge(
                  stock: stock,
                  isLowStock: isLowStock,
                  isOutOfStock: isOutOfStock,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              'Minimum stok: $minimumStock',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _stockIn(product),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                ),
                OutlinedButton.icon(
                  onPressed: stock > 0
                      ? () => _stockOut(product)
                      : null,
                  icon: const Icon(Icons.remove),
                  label: const Text('Kurangi'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _adjustment(product),
                  icon: const Icon(Icons.tune),
                  label: const Text('Sesuaikan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge({
    required int stock,
    required bool isLowStock,
    required bool isOutOfStock,
  }) {
    String text;
    Color? color;

    if (isOutOfStock) {
      text = 'HABIS';
      color = Colors.red;
    } else if (isLowStock) {
      text = 'MENIPIS';
      color = Colors.orange;
    } else {
      text = 'AMAN';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$text • $stock',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                search = value;

                Future.delayed(
                  const Duration(milliseconds: 400),
                  () {
                    if (search == value && mounted) {
                      _loadProducts();
                    }
                  },
                );
              },
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            search = '';
                          });
                          _loadProducts();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : products.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Produk tidak ditemukan.',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product =
                                Map<String, dynamic>.from(
                              products[index],
                            );

                            return _buildProductCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}