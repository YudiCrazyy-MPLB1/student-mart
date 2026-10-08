import 'package:flutter/material.dart';

import 'api_service.dart';
import 'manager_order_page.dart';
import 'manager_product_page.dart';
import 'accounting_dashboard_page.dart';
import 'login_page.dart';
import 'sapaan_random.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() =>
      _ManagerDashboardPageState();
}

class _ManagerDashboardPageState
    extends State<ManagerDashboardPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  late final String _greetingMessage;

  int totalProducts = 0;
  int totalCategories = 0;
  int totalOrders = 0;
  int pendingOrders = 0;
  int lowStockProducts = 0;
  int totalSales = 0;

  List<dynamic> recentOrders = [];

  @override
  void initState() {
    super.initState();
    _greetingMessage = SapaanRandom.generate();
    _loadDashboard();
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> _loadDashboard({
    bool refresh = false,
  }) async {
    if (refresh) {
      if (_isRefreshing) return;

      setState(() {
        _isRefreshing = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response =
          await ApiService.getManagerDashboard();

      final data = response;

      final statistics = data['statistics'];

      if (statistics is! Map) {
        throw Exception(
          'Data statistik dashboard tidak valid.',
        );
      }

      final recent = data['recent_orders'];

      if (!mounted) return;

      setState(() {
        totalProducts =
            _toInt(statistics['total_products']);

        totalCategories =
            _toInt(statistics['total_categories']);

        totalOrders =
            _toInt(statistics['total_orders']);

        pendingOrders =
            _toInt(statistics['pending_orders']);

        lowStockProducts =
            _toInt(statistics['low_stock_products']);

        totalSales =
            _toInt(statistics['total_sales']);

        recentOrders =
            recent is List ? recent : [];

        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _cleanErrorMessage(dynamic error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  // ============================================================
  // FORMATTER
  // ============================================================

  String _formatRupiah(dynamic value) {
    final number = _toInt(value);

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

  String _formatStatus(String status) {
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
        return status.isEmpty
            ? 'Tidak diketahui'
            : status;
    }
  }

  Color _statusColor(String status) {
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

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _openProducts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ManagerProductPage(),
      ),
    );

    if (!mounted) return;

    await _loadDashboard(
      refresh: true,
    );
  }

  Future<void> _openOrders() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ManagerOrderPage(),
      ),
    );

    if (!mounted) return;

    await _loadDashboard(
      refresh: true,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Manager Dashboard'),
      actions: [
        // LOGOUT
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await ApiService.logout();

            if (!mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginPage(),
              ),
              (route) => false,
            );
          },
        ),

        // REFRESH
        IconButton(
          tooltip: 'Refresh',
          onPressed: _isLoading || _isRefreshing
              ? null
              : () {
                  _loadDashboard(refresh: true);
                },
          icon: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                ),
        ),

        const SizedBox(width: 8),
      ],
    ),
    body: _buildBody(),
  );
}

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadDashboard(
        refresh: true,
      ),
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          _buildSalesCard(),

          const SizedBox(height: 16),

          _buildStatisticsGrid(),

          const SizedBox(height: 24),

          _buildQuickActions(),

          const SizedBox(height: 24),

          _buildRecentOrders(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context)
                .colorScheme
                .primaryContainer,
            Theme.of(context)
                .colorScheme
                .secondaryContainer,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 30,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _greetingMessage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Pantau aktivitas Student Mart dari satu tempat.',
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SALES CARD
  // ============================================================

  Widget _buildSalesCard() {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context)
                .dividerColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.payments_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Penjualan',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatRupiah(totalSales),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.trending_up_rounded,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatisticsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide =
            constraints.maxWidth >= 700;

        final crossAxisCount =
            isWide ? 3 : 2;

        return GridView.count(
          crossAxisCount:
              crossAxisCount,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio:
              isWide ? 1.8 : 1.45,
          children: [
            _buildStatCard(
              title: 'Produk',
              value:
                  totalProducts.toString(),
              icon:
                  Icons.inventory_2_rounded,
            ),

            _buildStatCard(
              title: 'Kategori',
              value:
                  totalCategories.toString(),
              icon:
                  Icons.category_rounded,
            ),

            _buildStatCard(
              title: 'Pesanan',
              value:
                  totalOrders.toString(),
              icon:
                  Icons.shopping_bag_rounded,
            ),

            _buildStatCard(
              title: 'Menunggu',
              value:
                  pendingOrders.toString(),
              icon:
                  Icons.pending_actions_rounded,
            ),

            _buildStatCard(
              title: 'Stok Menipis',
              value:
                  lowStockProducts.toString(),
              icon:
                  Icons.warning_amber_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Manager',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Kelola Produk',
                subtitle:
                    'Tambah dan edit produk',
                icon:
                    Icons.inventory_2_rounded,
                onTap: _openProducts,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildActionCard(
                title: 'Kelola Pesanan',
                subtitle:
                    'Pantau pesanan siswa',
                icon:
                    Icons.shopping_bag_rounded,
                onTap: _openOrders,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildActionCard(
                title: 'Inventaris',
                subtitle:
                    'Pantau inventaris student mart',
                icon:
                    Icons.bar_chart_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AccountingDashboardPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  Text(
                    'Buka',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons
                        .arrow_forward_rounded,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RECENT ORDERS
  // ============================================================

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pesanan Terbaru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (recentOrders.isNotEmpty)
              TextButton(
                onPressed: _openOrders,
                child:
                    const Text('Lihat Semua'),
              ),
          ],
        ),

        const SizedBox(height: 12),

        if (recentOrders.isEmpty)
          _buildEmptyOrders()
        else
          ...recentOrders
              .take(5)
              .map(
                (order) =>
                    _buildRecentOrderCard(
                  order,
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyOrders() {
    return Card(
      elevation: 0,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 32,
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 12),

            const Text(
              'Belum ada pesanan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Pesanan baru akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderCard(
    dynamic order,
  ) {
    if (order is! Map) {
      return const SizedBox.shrink();
    }

    final user = order['user'];

    final orderNumber =
        order['order_number']
                ?.toString() ??
            'Pesanan';

    final customerName =
        user is Map
            ? user['name']?.toString() ??
                'Pengguna'
            : 'Pengguna';

    final total =
        _toInt(order['total']);

    final status =
        order['status']?.toString() ??
            'unknown';

    final color =
        _statusColor(status);

    return Card(
      elevation: 0,
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: _openOrders,
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
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
                      orderNumber,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      customerName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _formatRupiah(total),
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _buildStatusBadge(status),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(
    String status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.1),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .cloud_off_rounded,
                color: Colors.red,
                size: 36,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Gagal memuat dashboard',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ??
                  'Terjadi kesalahan.',
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: () {
                _loadDashboard();
              },
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label:
                  const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

}