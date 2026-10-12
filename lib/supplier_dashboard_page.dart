import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // Untuk menampung bytes gambar web

import 'api_service.dart';
import 'tos_dialog.dart'; // Import dialog TOS yang dibuat sebelumnya

class SupplierDashboardPage extends StatefulWidget {
  final String token;
  // Bawa data user dari halaman sebelumnya untuk mengecek status is_supplier
  final Map<String, dynamic> userData; 

  const SupplierDashboardPage({
    super.key,
    required this.token,
    required this.userData,
  });

  @override
  State<SupplierDashboardPage> createState() => _SupplierDashboardPageState();
}

class _SupplierDashboardPageState extends State<SupplierDashboardPage> {
  bool _isSupplier = false;
  bool _isLoading = false;

  // Controller Form
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  // Variabel untuk menampung gambar
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    // Cek apakah user sudah pernah menyetujui TOS
    // Tergantung tipe data dari database Laravel (bisa 1, '1', atau true)
    final supplierStatus = widget.userData['is_supplier'];
    _isSupplier = (supplierStatus == 1 || supplierStatus == true || supplierStatus == '1');
  }

  // --- FUNGSI MUNCULKAN TOS ---
  void _tampilkanTOS() async {
    final bool? setuju = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const TosDialog(); // Memanggil UI TOS
      },
    );

    if (setuju == true) {
      setState(() => _isLoading = true);
      try {
        await ApiService.agreeTos(); // Fungsi untuk mengirim persetujuan ke backend
        setState(() {
          _isSupplier = true; // Langsung ubah UI ke form
        });
        _showMessage('Berhasil! Anda sekarang adalah pemasok Student Mart.');
      } catch (e) {
        _showMessage(e.toString(), isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- FUNGSI PILIH GAMBAR (Khusus Web) ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Untuk Flutter Web, kita gunakan readAsBytes() 
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
      _showMessage('Harap lengkapi semua form dan pilih gambar!', isError: true);
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
      
      // Kosongkan form setelah sukses
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _stockController.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
      });

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pemasok', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 27, 177, 164),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : !_isSupplier 
            ? _buildTosPrompt() 
            : _buildUploadForm(),
    );
  }

  // UI JIKA BELUM SETUJU TOS
  Widget _buildTosPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Ingin mulai jualan di Student Mart?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Baca dan setujui Syarat & Ketentuan Konsinyasi terlebih dahulu.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _tampilkanTOS,
            icon: const Icon(Icons.handshake),
            label: const Text('Baca Ketentuan & Daftar Pemasok'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              backgroundColor: const Color.fromARGB(255, 27, 177, 164),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // UI JIKA SUDAH JADI SUPPLIER (FORM UPLOAD)
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
              
              // Kolom Input
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Barang', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi Singkat', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga Jual (Rp)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stok Awal', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Pilih Gambar
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
                        color: _selectedImageName == null ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Tombol Ajukan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 27, 177, 164),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ajukan Barang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}