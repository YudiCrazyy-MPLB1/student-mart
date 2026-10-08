import 'package:flutter/material.dart';

import 'api_service.dart';
import 'inventory_page.dart';
import 'inventory_movement_page.dart';
import 'manager_product_import_page.dart';

class AccountingDashboardPage extends StatefulWidget {
  const AccountingDashboardPage({super.key});

  @override
  State<AccountingDashboardPage> createState() =>
      _AccountingDashboardPageState();
}

class _AccountingDashboardPageState
    extends State<AccountingDashboardPage> {
  bool _isLoading = true;
  String? _errorMessage;

  int _totalProducts = 0;
  int _totalStock = 0;
  int _lowStockProducts = 0;
  int _outOfStockProducts = 0;

  List<dynamic> _lowStockItems = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary =
          await ApiService.getInventorySummary();

      final lowStock =
          await ApiService.getLowStockProducts();

      if (!mounted) return;

      setState(() {
        _totalProducts =
            _toInt(summary['total_products']);

        _totalStock =
            _toInt(summary['total_stock']);

        _lowStockProducts =
            _toInt(summary['low_stock_products']);

        _outOfStockProducts =
            _toInt(summary['out_of_stock_products']);

        _lowStockItems = lowStock;

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

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        children: [
          SizedBox(
            height: 500,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat Inventaris Dashboard',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildHeader(),

        const SizedBox(height: 20),

        _buildStatistics(),

        const SizedBox(height: 24),

        _buildInventoryActions(),

        const SizedBox(height: 24),

        _buildLowStockSection(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📦 Inventaris',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola inventaris dan stok Student Mart.',
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard(
          icon: Icons.inventory_2,
          title: 'Total Produk',
          value: _totalProducts.toString(),
        ),
        _statCard(
          icon: Icons.storage,
          title: 'Total Stok',
          value: _totalStock.toString(),
        ),
        _statCard(
          icon: Icons.warning_amber,
          title: 'Stok Menipis',
          value: _lowStockProducts.toString(),
        ),
        _statCard(
          icon: Icons.remove_shopping_cart,
          title: 'Stok Habis',
          value: _outOfStockProducts.toString(),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildInventoryActions() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Kelola Stok',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 12),

      // MENU INVENTARIS
      Card(
        child: ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.inventory_2_rounded),
          ),
          title: const Text(
            'Inventaris',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'Lihat produk dan kelola stok',
          ),
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InventoryPage(),
              ),
            );
          },
        ),
      ),

      const SizedBox(height: 12),

      Card(
  child: ListTile(
    leading: const CircleAvatar(
      child: Icon(Icons.history),
    ),
    title: const Text(
      'Riwayat Inventaris',
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: const Text(
      'Lihat semua perubahan stok',
    ),
    trailing: const Icon(
      Icons.chevron_right,
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const InventoryMovementPage(),
        ),
      );
    },
  ),
),

Card(
  child: ListTile(
    leading: const CircleAvatar(
      child: Icon(Icons.upload_file_rounded),
    ),
    title: const Text(
      'Import Excel',
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: const Text(
      'Tambah atau perbarui produk dari Excel',
    ),
    trailing: const Icon(
      Icons.chevron_right,
    ),
    onTap: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ManagerProductImportPage(),
        ),
      );

      if (result == true) {
        await _loadDashboard();
      }
    },
  ),
),

    ],
  );
}

  Widget _buildLowStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '🚨 Stok Menipis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: _loadDashboard,
              child: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_lowStockItems.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tidak ada produk dengan stok menipis.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._lowStockItems.map(
            (item) => _buildLowStockItem(item),
          ),
      ],
    );
  }

  Widget _buildLowStockItem(dynamic item) {
    final name =
        item['name']?.toString() ?? 'Produk';

    final stock =
        _toInt(item['stock']);

    final minimumStock =
        _toInt(item['minimum_stock']);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.warning_amber),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Stok: $stock • Minimum: $minimumStock',
        ),
        trailing: Text(
          '$stock',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  
}