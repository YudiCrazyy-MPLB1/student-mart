import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';

import 'api_service.dart';

class SubmitAdvertisementPage extends StatefulWidget {
  const SubmitAdvertisementPage({super.key});

  @override
  State<SubmitAdvertisementPage> createState() =>
      _SubmitAdvertisementPageState();
}

class _SubmitAdvertisementPageState extends State<SubmitAdvertisementPage> {
  final _titleController = TextEditingController();
  final _targetUrlController = TextEditingController();

  // Pilihan default paket & metode bayar
  String _selectedPackage = '1_month_promo';
  String _selectedPaymentMethod = 'cash_koperasi';

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isLoading = false;

  // Daftar Pilihan Paket Iklan sesuai kesepakatan
  final Map<String, Map<String, dynamic>> _packages = {
    '1_month_promo': {
      'name': 'Paket 1 Bulan (Promo Launching)',
      'price': 10000,
      'desc': 'Banner tayang di beranda selama 1 bulan.',
    },
    '2_month_promo': {
      'name': 'Paket 2 Bulan (Paling Laris 🔥)',
      'price': 15000,
      'desc':
          'Hemat Rp5.000 + Bonus Produk Unggulan/Disponsori di urutan teratas!',
    },
  };

  @override
  void dispose() {
    _titleController.dispose();
    _targetUrlController.dispose();
    super.dispose();
  }

  // Pilih Banner Iklan
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
      });
    }
  }

  // Kirim Pengajuan Iklan ke Backend
  Future<void> _submitAd() async {
    if (_titleController.text.isEmpty || _selectedImageBytes == null) {
      _showMessage(
        'Harap isi Judul Usaha dan pilih Banner Iklan!',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.submitAdvertisement(
        title: _titleController.text,
        targetUrl: _targetUrlController.text,
        packageType: _selectedPackage,
        paymentMethod: _selectedPaymentMethod,
        imageBytes: _selectedImageBytes!,
        imageName: _selectedImageName ?? 'banner_ads.png',
      );

      _showMessage('Pengajuan iklan berhasil! Silakan selesaikan pembayaran.');
      Navigator.pop(context); // Kembali ke halaman sebelumnya setelah sukses
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
    final currentPackageInfo = _packages[_selectedPackage]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pasang Iklan / Sponsor',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 27, 177, 164),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Formulir Pengajuan Iklan Student Mart',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Promosikan produk atau usahamu agar tampil di halaman utama.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Judul Usaha / Iklan
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Usaha / Judul Iklan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Link Tujuan (Opsional)
                TextField(
                  controller: _targetUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Link Produk / Tujuan (Opsional)',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Pilihan Paket Durasi
                const Text(
                  'Pilih Paket Durasi Iklan:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPackage,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _packages.keys.map((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(
                        '${_packages[key]!['name']} (Rp ${_packages[key]!['price']})',
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => _selectedPackage = newValue!);
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Text(
                    'Info Paket: ${currentPackageInfo['desc']}',
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Pilihan Metode Pembayaran
                const Text(
                  'Metode Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: _selectedPaymentMethod,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPaymentMethod = val);
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Tunai di Koperasi'),
                          subtitle: const Text('Bayar langsung ke kasir'),
                          value: 'cash_koperasi',
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Digital / E-Wallet'),
                          subtitle: const Text('Transfer / DANA'),
                          value: 'digital_wallet',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Pilih Gambar Banner Iklan
                const Text(
                  'Banner Iklan (Foto/Poster):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Gambar Banner'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedImageName ?? 'Belum ada banner dipilih',
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

                // Tombol Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitAd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 27, 177, 164),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Ajukan Iklan (Total: Rp ${currentPackageInfo['price']})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
