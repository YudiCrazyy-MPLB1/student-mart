import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';

import 'api_service.dart';
import 'tos_dialog.dart';
import 'tos_redialog.dart';

class SupplierDashboardPage extends StatefulWidget {
  const SupplierDashboardPage({super.key});

  @override
  State<SupplierDashboardPage> createState() => _SupplierDashboardPageState();
}

class _SupplierDashboardPageState extends State<SupplierDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _isSupplier = false;
  bool _isLoading = true;

  // Tab Controller untuk beralih antara Form Upload & Status Barang
  late TabController _tabController;

  // Controller Form Upload
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  // Daftar produk konsinyasi milik supplier
  List<dynamic> _myProducts = [];
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  // --- AMBIL DATA USER TERBARU DARI API ---
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ApiService.getMe();
      final supplierStatus = user['is_supplier'];

      setState(() {
        _isSupplier =
            (supplierStatus == 1 ||
            supplierStatus == true ||
            supplierStatus == '1');
      });

      if (_isSupplier) {
        _fetchMyConsignmentProducts();
      }
    } catch (e) {
      _showMessage('Gagal memuat status akun: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- AMBIL DAFTAR PRODUK KONSINYASI SAYA ---
  Future<void> _fetchMyConsignmentProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      // Pastikan method getMyConsignmentProducts tersedia di ApiService Anda,
      // atau gunakan endpoint yang sesuai untuk mengambil produk milik supplier yang sedang login.
      final products = await ApiService.getMyConsignmentProducts(); // Sesuaikan jika ada endpoint khusus produk saya
      setState(() {
        _myProducts = products;
      });
    } catch (e) {
      debugPrint('Gagal memuat daftar produk: $e');
    } finally {
      setState(() => _isLoadingProducts = false);
    }
  }

  // --- FUNGSI MUNCULKAN TOS (UNTUK PENDAFTARAN) ---
  void _tampilkanTOS() async {
    final bool? setuju = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const TosDialog();
      },
    );

    if (setuju == true) {
      if (!_isSupplier) {
        setState(() => _isLoading = true);
        try {
          await ApiService.agreeTos();
          await _loadUserData();
          _showMessage('Berhasil! Anda sekarang adalah pemasok Student Mart.');
        } catch (e) {
          _showMessage(e.toString(), isError: true);
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // --- FUNGSI BACA ULANG TOS (READ-ONLY) ---
  void _tampilkanTOreRead() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const TosReadDialog(); // Menggunakan tos_redialog.dart
      },
    );
  }

  // --- FUNGSI PILIH GAMBAR (Khusus Web) ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
      });
    }
  }

  // --- FUNGSI UPLOAD PRODUK ---
  Future<void> _submitProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _stockController.text.isEmpty ||
        _selectedImageBytes == null) {
      _showMessage(
        'Harap lengkapi semua form dan pilih gambar!',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.submitConsignmentProduct(
        name: _nameController.text,
        description: _descController.text,
        price: _priceController.text,
        stock: _stockController.text,
        imageBytes: _selectedImageBytes!,
        imageName: _selectedImageName ?? 'produk_konsinyasi.png',
      );

      _showMessage('Produk berhasil diajukan! Menunggu verifikasi Admin.');

      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _stockController.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
      });

      // Refresh daftar produk & pindah ke tab status
      _fetchMyConsignmentProducts();
      _tabController.animateTo(1);
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.teal,
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
        actions: [
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
      body: TabBarView(
        controller: _tabController,
        children: [_buildUploadForm(), _buildStatusTab()],
      ),
    );
  }

  // UI JIKA BELUM SETUJU TOS
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

  // TAB 1: FORM UPLOAD PRODUK
  Widget _buildUploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Barang Titipan Baru',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Barang yang diunggah akan masuk antrean untuk ditinjau oleh Admin sebelum tampil di toko.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Singkat',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Jual (Rp)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stok Awal',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pilih Foto Barang'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _selectedImageName ?? 'Belum ada gambar terpilih',
                      style: TextStyle(
                        color: _selectedImageName == null
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 27, 177, 164),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Ajukan Barang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 2: STATISTIK & STATUS PRODUK SAYA
  Widget _buildStatusTab() {
    int approvedCount = _myProducts
        .where((p) => p['status'] == 'approved')
        .length;
    int pendingCount = _myProducts
        .where((p) => p['status'] == 'pending' || p['status'] == null)
        .length;
    int totalItems = _myProducts.length;

    return RefreshIndicator(
      onRefresh: _fetchMyConsignmentProducts,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // KARTU STATISTIK / RINGKASAN
          const Text(
            'Ringkasan Aktivitas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Disetujui',
                  '$approvedCount',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  '$pendingCount',
                  Colors.orange,
                  Icons.hourglass_top,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Produk',
                  '$totalItems',
                  Colors.teal,
                  Icons.inventory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // DAFTAR PRODUK SAYA
          const Text(
            'Daftar Status Barang Titipan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _isLoadingProducts
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _myProducts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        const Icon(Icons.inbox, size: 60, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada barang titipan yang diajukan.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _tabController.animateTo(0),
                          child: const Text('Upload Sekarang'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _myProducts.length,
                  itemBuilder: (context, index) {
                    final p = _myProducts[index];
                    final status = p['status'] ?? 'pending';

                    Color badgeColor = Colors.orange;
                    String badgeText = 'Menunggu Review';
                    if (status == 'approved') {
                      badgeColor = Colors.green;
                      badgeText = 'Disetujui (Aktif)';
                    } else if (status == 'rejected') {
                      badgeColor = Colors.red;
                      badgeText = 'Ditolak';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: p['image'] != null
                                  ? Image.network(
                                      ApiService.getImageUrl(p['image']),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, error, stackTrace) => const Icon(
                                        Icons.broken_image,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.store,
                                        color: Colors.teal,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name'] ?? 'Tanpa Nama',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Harga: Rp${p['price']} | Stok: ${p['stock']}',
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: badgeColor),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: TextStyle(
                                        color: badgeColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
