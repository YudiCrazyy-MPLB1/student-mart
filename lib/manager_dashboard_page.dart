import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'accounting_dashboard_page.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'manager_ads_management.dart';
import 'manager_order_page.dart';
import 'manager_product_page.dart';
import 'manager_verification_page.dart';
import 'sapaan_random.dart';
import 'skeleton_widgets.dart';
import 'theme.dart' as theme;
import 'utils.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  late final String _greetingMessage;

  int totalProducts = 0;
  int totalCategories = 0;
  int totalOrders = 0;
  int pendingOrders = 0;
  int processingOrders = 0;
  int lowStockProducts = 0;
  int outOfStockProducts = 0;
  int totalSales = 0;

  // Indikator Harian & Payout Konsinyasi (WIB)
  int todayOrders = 0;
  int todaySales = 0;
  int todayPayout = 0;

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
  Future<void> _loadDashboard({bool refresh = false}) async {
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
      final response = await ApiService.getManagerDashboard();
      final data = response;
      final statistics = data['statistics'];

      if (statistics is! Map) {
        throw Exception('Data statistik dashboard tidak valid.');
      }

      final recent = data['recent_orders'];

      if (!mounted) return;
      setState(() {
        totalProducts = AppUtils.toInt(statistics['total_products']);
        totalCategories = AppUtils.toInt(statistics['total_categories']);
        totalOrders = AppUtils.toInt(statistics['total_orders']);
        pendingOrders = AppUtils.toInt(statistics['pending_orders']);
        processingOrders = AppUtils.toInt(statistics['processing_orders']);
        lowStockProducts = AppUtils.toInt(statistics['low_stock_products']);
        outOfStockProducts =
            AppUtils.toInt(statistics['out_of_stock_products']);
        totalSales = AppUtils.toInt(statistics['total_sales']);

        todayOrders = AppUtils.toInt(statistics['today_orders']);
        todaySales = AppUtils.toInt(statistics['today_sales']);
        todayPayout = AppUtils.toInt(statistics['today_payout']);

        recentOrders = recent is List ? recent : [];
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
        return status.isEmpty ? 'Tidak diketahui' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'processing':
        return const Color(0xFF2563EB);
      case 'completed':
      case 'complete':
        return theme.brandGreen;
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFDC2626);
      default:
        return theme.textMuted;
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================
  Future<void> _openProducts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManagerProductPage()),
    );
    if (!mounted) return;
    await _loadDashboard(refresh: true);
  }

  Future<void> _openOrders() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManagerOrderPage()),
    );
    if (!mounted) return;
    await _loadDashboard(refresh: true);
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: theme.darkGreen,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PANEL KONTROL',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: theme.brandGreen,
              ),
            ),
            Text(
              'Manager Dashboard',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: theme.textDark,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading || _isRefreshing
                ? null
                : () => _loadDashboard(refresh: true),
            icon: _isRefreshing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.darkGreen,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Logout',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
              },
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: theme.darkGreen,
      onRefresh: () => _loadDashboard(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSalesAndTodayCard(),
          const SizedBox(height: 20),
          _buildSectionTitle(
            title: 'Ringkasan Operasional',
            subtitle: 'Status katalog, pesanan, dan ketersediaan stok',
          ),
          const SizedBox(height: 12),
          _buildStatisticsGrid(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentOrders(),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SkeletonShimmer(
          child: SkeletonBlock(height: 104, radius: 20),
        ),
        const SizedBox(height: 16),
        const SkeletonShimmer(
          child: SkeletonBlock(height: 210, radius: 20),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: List.generate(
            4,
            (_) => const SkeletonShimmer(
              child: SkeletonBlock(radius: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: theme.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.darkGreen, theme.brandGreen],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.darkGreen.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'STUDENT MART SMKN 4 JEMBER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _greetingMessage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pantau transaksi, stok, dan operasional toko dari satu tempat.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.35,
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
  // FINANCIAL & TODAY ACTIVITY SECTION (WIB)
  // ============================================================
  Widget _buildSalesAndTodayCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.paleGreen, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: theme.darkGreen.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Penjualan Semua Waktu
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.paleGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.payments_rounded,
                  color: theme.darkGreen,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Penjualan (Semua Waktu)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppUtils.formatRupiah(totalSales),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: theme.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: theme.paleGreen, height: 1),
          ),
          // Header Aktivitas Hari Ini
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: theme.brandGreen,
              ),
              const SizedBox(width: 6),
              Text(
                'Aktivitas Hari Ini (WIB)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: theme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTodayMetricCard(
                  label: 'Omzet Selesai',
                  value: AppUtils.formatRupiah(todaySales),
                  icon: Icons.trending_up_rounded,
                  color: theme.brandGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTodayMetricCard(
                  label: 'Pesanan Masuk',
                  value: '$todayOrders Pesanan',
                  icon: Icons.shopping_bag_outlined,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTodayMetricCard(
            label: 'Pencairan Dana Konsinyasi Siswa Hari Ini',
            value: AppUtils.formatRupiah(todayPayout),
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFFD97706),
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: theme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: fullWidth ? 15 : 14,
                    fontWeight: FontWeight.w800,
                    color: color,
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
  // STATISTICS
  // ============================================================
  Widget _buildStatisticsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final crossAxisCount = isWide ? 3 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 1.85 : 1.5,
          children: [
            _buildStatCard(
              title: 'Total Produk Aktif',
              value: totalProducts.toString(),
              icon: Icons.inventory_2_rounded,
            ),
            _buildStatCard(
              title: 'Total Kategori',
              value: totalCategories.toString(),
              icon: Icons.category_rounded,
            ),
            _buildStatCard(
              title: 'Total Pesanan',
              value: totalOrders.toString(),
              icon: Icons.shopping_bag_rounded,
            ),
            _buildStatCard(
              title: 'Pesanan Diproses',
              value: processingOrders.toString(),
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF2563EB),
            ),
            _buildStatCard(
              title: 'Pesanan Menunggu',
              value: pendingOrders.toString(),
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFD97706),
            ),
            _buildStatCard(
              title: 'Stok Menipis',
              value: lowStockProducts.toString(),
              icon: Icons.warning_amber_rounded,
              color: lowStockProducts > 0
                  ? const Color(0xFFB45309)
                  : theme.brandGreen,
            ),
            _buildStatCard(
              title: 'Stok Habis (0)',
              value: outOfStockProducts.toString(),
              icon: Icons.remove_shopping_cart_rounded,
              color: outOfStockProducts > 0
                  ? const Color(0xFFDC2626)
                  : theme.brandGreen,
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
    Color? color,
  }) {
    final effectiveColor = color ?? theme.darkGreen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.paleGreen, width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.darkGreen.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: effectiveColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: color ?? theme.textDark,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================
  Widget _buildQuickActions() {
    final actions = [
      (
        title: 'Kelola Produk',
        subtitle: 'Tambah, ubah & atur katalog',
        icon: Icons.inventory_2_rounded,
        accent: theme.darkGreen,
        onTap: _openProducts,
      ),
      (
        title: 'Kelola Pesanan',
        subtitle: 'Proses pesanan masuk siswa',
        icon: Icons.shopping_bag_rounded,
        accent: const Color(0xFF2563EB),
        onTap: _openOrders,
      ),
      (
        title: 'Inventaris',
        subtitle: 'Audit stok & import Excel',
        icon: Icons.bar_chart_rounded,
        accent: theme.brandGreen,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AccountingDashboardPage(),
            ),
          );
        },
      ),
      (
        title: 'Verifikasi Barang',
        subtitle: 'Tinjau produk konsinyasi siswa',
        icon: Icons.fact_check_rounded,
        accent: const Color(0xFFD97706),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ManagerVerificationPage(),
            ),
          );
        },
      ),
      (
        title: 'Kelola Iklan',
        subtitle: 'Verifikasi banner & promo',
        icon: Icons.campaign_rounded,
        accent: const Color(0xFF7C3AED),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManagerAdsManagementPage()),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Menu Manager',
          subtitle: 'Akses cepat pengelolaan modul toko',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final crossAxisCount = isWide ? 3 : 2;
            return GridView.builder(
              itemCount: actions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWide ? 1.55 : 1.18,
              ),
              itemBuilder: (context, index) {
                final item = actions[index];
                return _buildActionCard(
                  title: item.title,
                  subtitle: item.subtitle,
                  icon: item.icon,
                  accent: item.accent,
                  onTap: item.onTap,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.paleGreen, width: 1),
            boxShadow: [
              BoxShadow(
                color: theme.darkGreen.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.pageBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: theme.darkGreen,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: theme.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.textMuted,
                  fontSize: 11.5,
                  height: 1.3,
                ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Pesanan Terbaru',
          subtitle: '5 transaksi terakhir yang masuk ke sistem',
          trailing: recentOrders.isNotEmpty
              ? TextButton.icon(
                  onPressed: _openOrders,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.darkGreen,
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Lihat Semua'),
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (recentOrders.isEmpty)
          _buildEmptyOrders()
        else
          ...recentOrders.take(5).map((order) => _buildRecentOrderCard(order)),
      ],
    );
  }

  Widget _buildEmptyOrders() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.paleGreen),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.paleGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 28,
              color: theme.darkGreen,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada pesanan',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              color: theme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pesanan baru dari siswa akan muncul di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: theme.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrderCard(dynamic order) {
    if (order is! Map) {
      return const SizedBox.shrink();
    }

    final user = order['user'];
    final orderNumber = order['order_number']?.toString() ?? 'Pesanan';
    final customerName = user is Map
        ? user['name']?.toString() ?? 'Pengguna'
        : 'Pengguna';
    final total = AppUtils.toInt(order['total']);
    final status = order['status']?.toString() ?? 'unknown';
    final color = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openOrders,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.paleGreen),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: theme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: theme.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppUtils.formatRupiah(total),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: theme.darkGreen,
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
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================
  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        _formatStatus(status),
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.paleGreen),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.red.shade700,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat dashboard',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Terjadi kesalahan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.textMuted,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _loadDashboard(),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.darkGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Coba Lagi',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}