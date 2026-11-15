import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_exception.dart';
import 'api_service.dart';
import 'skeleton_widgets.dart';
import 'theme.dart' as theme;
import 'utils.dart';
import 'utils/file_downloader.dart';

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
  Timer? _autoRefreshTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadOrders();
    _startAutoRefreshTimer();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    // Auto refresh setiap 15 detik agar pesanan baru dari siswa langsung masuk
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      loadOrders(silent: true);
    });
  }

  Future<void> loadOrders({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final result = await ApiService.getManagerOrders();
      if (!mounted) return;
      setState(() {
        orders = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          isLoading = false;
        });
        showMessage('Gagal mengambil pesanan: $e', isError: true);
      }
    }
  }

  bool _isFinalStatus(String status) {
    final s = status.toLowerCase();
    return s == 'completed' || s == 'cancelled';
  }

  List<String> _allowedNextStatuses(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ['processing', 'completed', 'cancelled'];
      case 'processing':
        return ['completed', 'cancelled'];
      case 'completed':
      case 'cancelled':
      default:
        return [];
    }
  }

  Future<void> updateOrderStatus(
    Map<String, dynamic> order,
    String newStatus,
  ) async {
    final orderId = int.tryParse(order['id'].toString());
    if (orderId == null) {
      showMessage('ID pesanan tidak valid.', isError: true);
      return;
    }

    try {
      await ApiService.updateManagerOrderStatus(
        orderId: orderId,
        status: newStatus,
      );
      if (!mounted) return;
      showMessage(
        'Status pesanan berhasil diubah menjadi '
        '${formatStatus(newStatus)}.',
      );
      await loadOrders();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Gagal mengubah status: $e';
      showMessage(msg, isError: true);
    }
  }

  List<Map<String, dynamic>> get filteredOrders {
    return orders.where((order) {
      final status = order['status']?.toString().toLowerCase() ?? '';
      final orderNumber = order['order_number']?.toString().toLowerCase() ?? '';
      final user = order['user'];
      final userName = user is Map
          ? user['name']?.toString().toLowerCase() ?? ''
          : '';

      final matchesSearch = searchQuery.trim().isEmpty ||
          orderNumber.contains(searchQuery.toLowerCase()) ||
          userName.contains(searchQuery.toLowerCase());

      final matchesStatus = selectedStatus == 'all' || status == selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
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

  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : theme.darkGreen,
        ),
      );
  }

  void showStatusMenu(Map<String, dynamic> order) {
    final currentStatus = order['status']?.toString().toLowerCase() ?? '';
    final isFinal = _isFinalStatus(currentStatus);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubah Status Pesanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: theme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                if (isFinal) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.amber.shade800),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Status ${formatStatus(currentStatus)} bersifat final dan tidak dapat diubah lagi.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ] else ...[
                  Text(
                    'Pilih status selanjutnya yang diizinkan untuk pesanan ini:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: theme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _statusOption(
                  order,
                  'pending',
                  Icons.hourglass_empty_rounded,
                  currentStatus,
                ),
                _statusOption(
                  order,
                  'processing',
                  Icons.inventory_2_rounded,
                  currentStatus,
                ),
                _statusOption(
                  order,
                  'completed',
                  Icons.check_circle_rounded,
                  currentStatus,
                ),
                _statusOption(
                  order,
                  'cancelled',
                  Icons.cancel_rounded,
                  currentStatus,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showOrderDetail(Map<String, dynamic> order) {
    final user = order['user'];
    final customerName = user is Map
        ? user['name']?.toString() ?? 'Tidak diketahui'
        : 'Tidak diketahui';
    final customerEmail = user is Map ? user['email']?.toString() ?? '-' : '-';
    final items = order['items'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order['order_number']?.toString() ?? 'Pesanan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.textDark,
                          ),
                        ),
                      ),
                      statusChip(order['status']?.toString() ?? ''),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.pageBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.paleGreen),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pelanggan: $customerName',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: theme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Email: $customerEmail',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: theme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Daftar Produk',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: theme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (items is List && items.isNotEmpty)
                    ...items.map((item) {
                      final product = item['product'];
                      final productName = product is Map
                          ? product['name']?.toString() ?? 'Produk'
                          : 'Produk';
                      final quantity = item['quantity'] ?? 0;
                      final price = item['price'] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: theme.textDark,
                                    ),
                                  ),
                                  Text(
                                    '$quantity x ${AppUtils.formatRupiah(price)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: theme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    Text(
                      'Tidak ada detail produk.',
                      style: GoogleFonts.plusJakartaSans(color: theme.textMuted),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: theme.paleGreen),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pembayaran',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: theme.textDark,
                        ),
                      ),
                      Text(
                        AppUtils.formatRupiah(order['total']),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: theme.darkGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Builder(
                    builder: (context) {
                      final orderStatus = order['status']?.toString() ?? '';
                      final isFinal = _isFinalStatus(orderStatus);
                      return SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: isFinal
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  showStatusMenu(order);
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.darkGreen,
                            side: BorderSide(
                              color: isFinal
                                  ? Colors.grey.shade300
                                  : theme.darkGreen,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            isFinal ? Icons.lock_outline : Icons.sync_rounded,
                            size: 18,
                          ),
                          label: Text(
                            isFinal
                                ? 'Status Final (${formatStatus(orderStatus)})'
                                : 'Ubah Status',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.darkGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tutup',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        formatStatus(status),
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Future<void> _exportOrdersExcel() async {
    showMessage('Mempersiapkan ekspor pesanan Excel...');
    try {
      final file = await ApiService.exportOrders(
        status: selectedStatus == 'all' ? null : selectedStatus,
      );
      final path = await saveExcelFile(
        bytes: file.bytes,
        fileName: file.fileName,
      );
      if (!mounted) return;
      if (path != null) {
        showMessage('Laporan pesanan berhasil disimpan: $path');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Gagal ekspor pesanan: $e';
      showMessage(msg, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = filteredOrders;

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
              'MANAJEMEN TRANSAKSI',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: theme.brandGreen,
              ),
            ),
            Text(
              'Kelola Pesanan',
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
            tooltip: 'Export Excel (.xlsx)',
            icon: const Icon(Icons.download_rounded),
            onPressed: _exportOrdersExcel,
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadOrders,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: theme.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'Cari nomor pesanan / nama siswa...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: theme.textMuted,
                  fontSize: 13.5,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: theme.brandGreen),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                        icon: Icon(Icons.clear_rounded, color: theme.textMuted),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: theme.paleGreen),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: theme.paleGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.brandGreen, width: 1.5),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          // FILTER CHIPS
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _statusFilter('all', 'Semua'),
                _statusFilter('pending', 'Menunggu'),
                _statusFilter('processing', 'Diproses'),
                _statusFilter('completed', 'Selesai'),
                _statusFilter('cancelled', 'Dibatalkan'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // ORDER LIST
          Expanded(
            child: isLoading
                ? const SkeletonList()
                : visibleOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: theme.paleGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 32,
                                color: theme.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada pesanan.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: theme.textDark,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: theme.darkGreen,
                        onRefresh: loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                          itemCount: visibleOrders.length,
                          itemBuilder: (context, index) {
                            final order = visibleOrders[index];
                            final user = order['user'];
                            final customerName = user is Map
                                ? user['name']?.toString() ?? 'Tidak diketahui'
                                : 'Tidak diketahui';
                            final status =
                                order['status']?.toString() ?? 'unknown';
                            final isFinal = _isFinalStatus(status);

                            return GestureDetector(
                              onTap: () => showOrderDetail(order),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: theme.paleGreen),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.darkGreen
                                          .withValues(alpha: 0.045),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // HEADER ORDER
                                    Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: theme.paleGreen,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.receipt_long_rounded,
                                            size: 19,
                                            color: theme.darkGreen,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                order['order_number']
                                                        ?.toString() ??
                                                    'Pesanan',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14.5,
                                                  color: theme.textDark,
                                                ),
                                              ),
                                              Text(
                                                customerName,
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12.5,
                                                  color: theme.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        statusChip(status),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // DAFTAR PRODUK
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.pageBackground,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Item Pesanan',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: theme.textMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (order['items'] is List &&
                                              (order['items'] as List)
                                                  .isNotEmpty)
                                            ...(order['items'] as List)
                                                .map((item) {
                                              final product = item['product'];
                                              final productName = product is Map
                                                  ? product['name']
                                                          ?.toString() ??
                                                      'Produk'
                                                  : 'Produk';
                                              final quantity = int.tryParse(
                                                    item['quantity']
                                                            ?.toString() ??
                                                        '0',
                                                  ) ??
                                                  0;
                                              final price = int.tryParse(
                                                    item['price']?.toString() ??
                                                        '0',
                                                  ) ??
                                                  0;
                                              final subtotal = quantity * price;

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 4,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .shopping_bag_outlined,
                                                      size: 16,
                                                      color: theme.brandGreen,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            productName,
                                                            style: GoogleFonts
                                                                .plusJakartaSans(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 13,
                                                              color: theme
                                                                  .textDark,
                                                            ),
                                                          ),
                                                          Text(
                                                            '$quantity x ${AppUtils.formatRupiah(price)}',
                                                            style: GoogleFonts
                                                                .plusJakartaSans(
                                                              color: theme
                                                                  .textMuted,
                                                              fontSize: 11.5,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      AppUtils.formatRupiah(
                                                        subtotal,
                                                      ),
                                                      style: GoogleFonts
                                                          .plusJakartaSans(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 13,
                                                        color: theme.textDark,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            })
                                          else
                                            Text(
                                              'Tidak ada produk.',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                color: theme.textMuted,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // PICKUP & PAYMENT
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 16,
                                                color: theme.brandGreen,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  order['pickup_method']
                                                          ?.toString() ??
                                                      '-',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 12,
                                                    color: theme.textMuted,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.payment_outlined,
                                                size: 16,
                                                color: theme.brandGreen,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  order['payment_method']
                                                          ?.toString() ??
                                                      '-',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 12,
                                                    color: theme.textMuted,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Divider(
                                        color: theme.paleGreen,
                                        height: 1,
                                      ),
                                    ),
                                    // TOTAL & ACTION
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Pesanan',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 11.5,
                                                color: theme.textMuted,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              AppUtils.formatRupiah(
                                                order['total'],
                                              ),
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16.5,
                                                color: theme.darkGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                        FilledButton.icon(
                                          onPressed: isFinal
                                              ? null
                                              : () => showStatusMenu(order),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: theme.darkGreen,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor:
                                                theme.paleGreen,
                                            disabledForegroundColor:
                                                theme.textMuted,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          icon: Icon(
                                            isFinal
                                                ? Icons.lock_outline
                                                : Icons.sync_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            isFinal
                                                ? 'Status Final (${formatStatus(status)})'
                                                : 'Ubah Status',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
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

  Widget _statusFilter(String value, String label) {
    final selected = selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? Colors.white : theme.textDark,
          ),
        ),
        selected: selected,
        selectedColor: theme.darkGreen,
        backgroundColor: Colors.white,
        showCheckmark: false,
        side: BorderSide(
          color: selected ? theme.darkGreen : theme.paleGreen,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
    final isCurrent = currentStatus.toLowerCase() == status.toLowerCase();
    final isAllowed =
        _allowedNextStatuses(currentStatus).contains(status.toLowerCase());
    final color = statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withValues(alpha: 0.08)
            : (isAllowed ? theme.pageBackground : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? color.withValues(alpha: 0.3) : theme.paleGreen,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isCurrent || isAllowed ? color : Colors.grey.shade400,
        ),
        title: Text(
          formatStatus(status),
          style: GoogleFonts.plusJakartaSans(
            color: isCurrent || isAllowed ? theme.textDark : Colors.grey.shade400,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: isCurrent
            ? Text(
                'Status saat ini',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              )
            : (!isAllowed
                ? Text(
                    'Tidak diizinkan dari status saat ini',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                    ),
                  )
                : null),
        trailing: isCurrent
            ? Icon(Icons.check_circle_rounded, color: color)
            : (isAllowed
                ? Icon(Icons.chevron_right_rounded, color: theme.textMuted)
                : null),
        enabled: isAllowed,
        onTap: !isAllowed
            ? null
            : () async {
                Navigator.pop(context);
                await updateOrderStatus(order, status);
              },
      ),
    );
  }
}