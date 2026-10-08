import 'package:flutter/material.dart';

import 'api_service.dart';

class InventoryMovementPage extends StatefulWidget {
  const InventoryMovementPage({super.key});

  @override
  State<InventoryMovementPage> createState() =>
      _InventoryMovementPageState();
}

class _InventoryMovementPageState
    extends State<InventoryMovementPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _movements = [];

  String? _selectedType;

  final List<Map<String, String?>> _filters = [
    {
      'label': 'Semua',
      'value': null,
    },
    {
      'label': 'Stok Masuk',
      'value': 'in',
    },
    {
      'label': 'Penjualan',
      'value': 'sale',
    },
    {
      'label': 'Stok Keluar',
      'value': 'out',
    },
    {
      'label': 'Barang Rusak',
      'value': 'damage',
    },
    {
      'label': 'Penyesuaian',
      'value': 'adjustment',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result =
          await ApiService.getInventoryMovements(
        type: _selectedType,
      );

      if (!mounted) return;

      setState(() {
        _movements = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'in':
        return 'Stok Masuk';

      case 'out':
        return 'Stok Keluar';

      case 'sale':
        return 'Penjualan';

      case 'damage':
        return 'Barang Rusak';

      case 'return':
        return 'Retur';

      case 'adjustment':
        return 'Penyesuaian';

      default:
        return type;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'in':
        return Icons.add_circle_outline;

      case 'out':
        return Icons.remove_circle_outline;

      case 'sale':
        return Icons.shopping_cart_outlined;

      case 'damage':
        return Icons.warning_amber_rounded;

      case 'return':
        return Icons.assignment_return_outlined;

      case 'adjustment':
        return Icons.tune;

      default:
        return Icons.inventory_2_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'in':
        return Colors.green;

      case 'out':
        return Colors.orange;

      case 'sale':
        return Colors.blue;

      case 'damage':
        return Colors.red;

      case 'return':
        return Colors.purple;

      case 'adjustment':
        return Colors.teal;

      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(
      value.toString(),
    );

    if (date == null) return value.toString();

    final local = date.toLocal();

    String two(int number) =>
        number.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _productName(dynamic movement) {
    final product = movement['product'];

    if (product is Map) {
      return product['name']?.toString() ??
          'Produk #${movement['product_id']}';
    }

    return 'Produk #${movement['product_id']}';
  }

  String _userName(dynamic movement) {
    final user = movement['user'];

    if (user is Map) {
      return user['name']?.toString() ?? 'User';
    }

    return 'User';
  }

  Widget _buildFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final value = filter['value'];
          final selected =
              _selectedType == value;

          return Padding(
            padding: const EdgeInsets.only(
              right: 8,
            ),
            child: ChoiceChip(
              label: Text(
                filter['label'] ?? '',
              ),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedType = value;
                });

                _loadMovements();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMovementCard(
    Map<String, dynamic> movement,
  ) {
    final type =
        movement['type']?.toString() ?? '';

    final quantity =
        _toInt(movement['quantity']);

    final stockBefore =
        _toInt(movement['stock_before']);

    final stockAfter =
        _toInt(movement['stock_after']);

    final color = _typeColor(type);

    final note =
        movement['note']?.toString();

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      color.withValues(alpha: 0.12),
                  child: Icon(
                    _typeIcon(type),
                    color: color,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _productName(movement),
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _typeLabel(type),
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  type == 'in'
                      ? '+$quantity'
                      : type == 'return'
                          ? '+$quantity'
                          : '-$quantity',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Divider(),

            const SizedBox(height: 4),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Stok sebelum\n$stockBefore',
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    'Stok sesudah\n$stockAfter',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (note != null &&
                note.trim().isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 8,
                ),
                child: Text(
                  '📝 $note',
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                  ),
                ),
              ),

            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    _userName(movement),
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),

                Text(
                  _formatDate(
                    movement['created_at'],
                  ),
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
              ),

              const SizedBox(height: 12),

              const Text(
                'Gagal mengambil riwayat stok.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _errorMessage!,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed:
                    _loadMovements,
                icon: const Icon(
                  Icons.refresh,
                ),
                label:
                    const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_movements.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMovements,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),

            Icon(
              Icons.history,
              size: 70,
            ),

            SizedBox(height: 16),

            Center(
              child: Text(
                'Belum ada riwayat stok.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMovements,
      child: ListView.builder(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24,
        ),
        physics:
            const AlwaysScrollableScrollPhysics(),
        itemCount: _movements.length,
        itemBuilder: (context, index) {
          final movement =
              Map<String, dynamic>.from(
            _movements[index],
          );

          return _buildMovementCard(
            movement,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Inventaris',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading
                    ? null
                    : _loadMovements,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: _buildFilter(),
          ),

          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }
}