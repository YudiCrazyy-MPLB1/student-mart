import 'dart:async';
import 'package:provider/provider.dart';
import 'product_provider.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';

class ManagerVerificationPage extends StatefulWidget {
  // Tidak perlu lagi meminta token di sini, biarkan ApiService yang menanganinya
  const ManagerVerificationPage({super.key});

  @override
  State<ManagerVerificationPage> createState() =>
      _ManagerVerificationPageState();
}

class _ManagerVerificationPageState extends State<ManagerVerificationPage> {
  /// setState yang aman dipanggil setelah `await` (halaman bisa sudah ditutup).
  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  List<dynamic> _pendingProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingProducts();
  }

  Future<void> _fetchPendingProducts() async {
    _safeSetState(() => _isLoading = true);
    try {
      // Memanggil fungsi dari ApiService
      final products = await ApiService.getPendingProducts();
      _safeSetState(() {
        _pendingProducts = products;
      });
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _verifyProduct(int productId, String status) async {
    try {
      // Tampilkan loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ApiService.verifyProduct(productId: productId, status: status);

      // Tutup loading indicator
      if (mounted) Navigator.pop(context);

      _showMessage(
        status == 'approved'
            ? 'Produk disetujui dan berhasil tayang!'
            : 'Produk ditolak.',
      );

      // Invalidasi & auto refresh katalog siswa jika produk disetujui
      if (status == 'approved' && mounted) {
        try {
          context.read<ProductProvider>().fetchProducts(forceRefresh: true);
        } catch (_) {}
      }

      // Refresh daftar setelah produk diverifikasi
      _fetchPendingProducts();
    } catch (e) {
      if (mounted) Navigator.pop(context); // Tutup loading jika error
      _showMessage(e.toString(), isError: true);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Colors.red
            : const Color.fromARGB(255, 27, 177, 164),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verifikasi Konsinyasi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(
          255,
          16,
          80,
          91,
        ), // Warna Dark Green
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Ubah tombol back jadi putih
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchPendingProducts,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF6F8F6),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingProducts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada barang konsinyasi baru.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingProducts.length,
              itemBuilder: (context, index) {
                final product = _pendingProducts[index];
                final supplierName =
                    product['supplier']?['name'] ?? 'Siswa (Tidak Diketahui)';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail Gambar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                image: product['image'] != null
                                    ? DecorationImage(
                                        // Asumsi base url Laravel Anda
                                        image: NetworkImage(
                                          ApiService.getImageUrl(
                                            product['image'],
                                          ),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: product['image'] == null
                                  ? const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // Info Produk
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? 'Produk Tanpa Nama',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Penitip: $supplierName',
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Harga: Rp ${product['price']}  |  Stok: ${product['stock']}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        // Tombol Aksi (Tolak / Setujui)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _verifyProduct(product['id'], 'rejected'),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 18,
                              ),
                              label: const Text(
                                'Tolak',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _verifyProduct(product['id'], 'approved'),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Setujui'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  27,
                                  177,
                                  164,
                                ),
                                foregroundColor: Colors.white,
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
    );
  }
}