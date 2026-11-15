import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'app_cached_image.dart';
import 'auth_provider.dart';
import 'tos_dialog.dart';
import 'tos_redialog.dart';
import 'utils.dart';

class SupplierDashboardPage extends StatefulWidget {
  const SupplierDashboardPage({super.key});

  @override
  State<SupplierDashboardPage> createState() => _SupplierDashboardPageState();
}

class _SupplierDashboardPageState extends State<SupplierDashboardPage>
    with SingleTickerProviderStateMixin {
  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  bool _isSupplier = false;
  bool _isLoading = true;
  int _balance = 0;

  late TabController _tabController;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  List<dynamic> _myProducts = [];
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final cachedUser = context.read<AuthProvider>().user;
    if (cachedUser != null) {
      _balance = cachedUser.balance;
      _isSupplier = cachedUser.isSupplier;
    }
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    _safeSetState(() => _isLoading = true);
    try {
      final user = await ApiService.getMe();
      if (mounted) {
        context.read<AuthProvider>().syncFromApi(userData: user);
      }
      final supplierStatus = user['is_supplier'];
      _safeSetState(() {
        _isSupplier = (supplierStatus == 1 ||
            supplierStatus == true ||
            supplierStatus == '1');
        _balance = AppUtils.toInt(user['balance']);
      });
      if (_isSupplier) {
        await _fetchMyConsignmentProducts();
      }
    } catch (e) {
      _showMessage('Gagal memuat status akun: $e', isError: true);
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMyConsignmentProducts() async {
    _safeSetState(() => _isLoadingProducts = true);
    try {
      final products = await ApiService.getMyConsignmentProducts();
      _safeSetState(() {
        _myProducts = products;
      });
    } catch (e) {
      debugPrint('Gagal memuat daftar produk: $e');
    } finally {
      _safeSetState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _tampilkanTOS() async {
    final bool? setuju = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const TosDialog();
      },
    );
    if (setuju == true && !_isSupplier) {
      _safeSetState(() => _isLoading = true);
      try {
        await ApiService.agreeTos();
        await _loadUserData();
        _showMessage('Berhasil! Anda sekarang adalah pemasok Student Mart.');
      } catch (e) {
        _showMessage(e.toString(), isError: true);
      } finally {
        _safeSetState(() => _isLoading = false);
      }
    }
  }

  void _tampilkanTOreRead() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const TosReadDialog();
      },
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      _safeSetState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
      });
    }
  }

  Future<void> _submitProduct() async {
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _stockController.text.trim().isEmpty ||
        _selectedImageBytes == null) {
      _showMessage(
        'Harap lengkapi semua form dan pilih gambar!',
        isError: true,
      );
      return;
    }

    _safeSetState(() => _isLoading = true);
    try {
      await ApiService.submitConsignmentProduct(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: _priceController.text.trim(),
        stock: _stockController.text.trim(),
        imageBytes: _selectedImageBytes!,
        imageName: _selectedImageName ?? 'produk_konsinyasi.png',
      );
      _showMessage('Produk berhasil diajukan! Menunggu verifikasi Admin.');
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _stockController.clear();
      _safeSetState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
      });
      if (!mounted) return;
      await _fetchMyConsignmentProducts();
      _tabController.animateTo(1);
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.teal,
      ),
    );
  }

  Widget _buildBalanceCard() {
    final approvedCount =
        _myProducts.where((p) => p['status'] == 'approved').length;
    final pendingCount =
        _myProducts.where((p) => p['status'] == 'pending').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10505B), Color(0xFF1BB1A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10505B).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Pendapatan Konsinyasi',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Dompet Pemasok Siswa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Perbarui Saldo',
                onPressed: _isLoading ? null : _loadUserData,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppUtils.formatRupiah(_balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 15),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Otomatis bertambah 98% dari harga jual (potongan 2% fee platform) saat pesanan selesai.',
                    style: TextStyle(color: Colors.white, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStatPill('Produk Tayang', '$approvedCount'),
              const SizedBox(width: 8),
              _miniStatPill('Menunggu Kurasi', '$pendingCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStatPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard Pemasok',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromARGB(255, 27, 177, 164),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isSupplier) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard Pemasok',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromARGB(255, 27, 177, 164),
          actions: [
            IconButton(
              icon: const Icon(Icons.rule, color: Colors.white),
              tooltip: 'Syarat & Ketentuan Konsinyasi',
              onPressed: _tampilkanTOreRead,
            ),
          ],
        ),
        body: _buildTosPrompt(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard Pemasok',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 27, 177, 164),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Data',
            onPressed: _loadUserData,
          ),
          IconButton(
            icon: const Icon(Icons.rule, color: Colors.white),
            tooltip: 'Syarat & Ketentuan Konsinyasi',
            onPressed: _tampilkanTOreRead,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.add_box), text: 'Upload Barang'),
            Tab(icon: Icon(Icons.list_alt), text: 'Status Barang Saya'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildBalanceCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildUploadForm(), _buildStatusTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTosPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              'Ingin mulai jualan di Student Mart?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Baca dan setujui Syarat & Ketentuan Konsinyasi terlebih dahulu.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _tampilkanTOS,
              icon: const Icon(Icons.handshake),
              label: const Text('Baca Ketentuan & Daftar Pemasok'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                backgroundColor: const Color.fromARGB(255, 27, 177, 164),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Barang Titipan Baru',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Barang yang diunggah akan ditinjau oleh Admin sebelum tampil di toko.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Singkat',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Jual',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stok Titipan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Foto Produk:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_selectedImageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _selectedImageBytes!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      _selectedImageBytes == null
                          ? 'Pilih Gambar'
                          : 'Ganti Gambar',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedImageName ?? 'Belum ada gambar dipilih',
                      style: TextStyle(
                        color: _selectedImageName == null
                            ? Colors.grey
                            : Colors.teal.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submitProduct,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text(
                    'Ajukan Produk Konsinyasi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 27, 177, 164),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTab() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myProducts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Center(
              child: Text(
                'Belum ada produk konsinyasi yang diajukan.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myProducts.length,
        itemBuilder: (context, index) {
          final item = _myProducts[index];
          final status = (item['status'] ?? 'pending').toString().toLowerCase();
          final price = AppUtils.toInt(item['price']);
          final stock = AppUtils.toInt(item['stock']);
          final estNet = (price * 0.98).round();

          Color badgeColor;
          String badgeLabel;
          switch (status) {
            case 'approved':
              badgeColor = Colors.green;
              badgeLabel = 'Disetujui & Tayang';
              break;
            case 'rejected':
              badgeColor = Colors.red;
              badgeLabel = 'Ditolak';
              break;
            default:
              badgeColor = Colors.orange;
              badgeLabel = 'Menunggu Verifikasi';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  AppCachedNetworkImage(
                    imageUrl: item['image']?.toString(),
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']?.toString() ?? 'Produk',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Harga: ${AppUtils.formatRupiah(price)} • Sisa Stok: $stock',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bersih/item (98%): ${AppUtils.formatRupiah(estNet)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}