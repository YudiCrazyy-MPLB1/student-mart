import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cart_controller.dart';
import 'api_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String pickupMethod = 'Ambil di Student Mart';
  String paymentMethod = 'Bayar di Kasir';

  bool isProcessing = false;

  String formatRupiah(int price) {
    return 'Rp${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  Future<void> createOrder() async {
    if (isProcessing) return; // Prevent multiple submissions
    final cart = context.read<CartController>();
    if (cart.items.isEmpty) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final items = cart.items.map((item) {
        return {'product_id': item.product.id, 'quantity': item.quantity};
      }).toList();

      final orderData = await ApiService.createOrder(
        pickupMethod: pickupMethod,
        paymentMethod: paymentMethod,
        items: items,
      );

      if (!mounted) return;

      cart.clearCart();

      setState(() {
        isProcessing = false;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pesanan Berhasil 🎉'),
            content: Text(
              'Pesanan ${orderData['order_number']} '
              'berhasil dibuat.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      final errorText = e.toString();

      if (errorText.contains('401') ||
          errorText.toLowerCase().contains('unauthorized')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi telah habis. Silakan login kembali.'),
            backgroundColor: Colors.red,
          ),
        );
        // Tendang ke halaman login
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }

      if (errorText.contains('422') ||
          errorText.toLowerCase().contains('stok')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Menampilkan pesan asli dari Laravel ("Stok Mie Ayam tidak mencukupi...")
            content: Text(errorText.replaceFirst('Exception: ', '')),
            backgroundColor: Colors.orange.shade800, // Warna orange/merah agar terlihat sebagai peringatan
            duration: const Duration(seconds: 4),
          ),
        );

        // (Opsional) Jika ingin me-refresh keranjang otomatis saat stok habis:
        // cartController.clearCart();

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Checkout gagal: ${errorText.replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.read<CartController>().items;
    final total = context.read<CartController>().total;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: items.isEmpty
          ? const Center(child: Text('Keranjang kosong'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =========================
                  // PESANAN
                  // =========================

                  const Text(
                    'Pesanan Kamu',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.blue,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      '${item.quantity} x ${formatRupiah(item.product.price)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                formatRupiah(
                                  item.product.price * item.quantity,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =========================
                  // PENGAMBILAN
                  // =========================
                  const Text(
                    'Metode Pengambilan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: RadioGroup<String>(
                      groupValue: pickupMethod,
                      onChanged: (value) {
                        if (isProcessing || value == null) return; // Disable changes while processing
                        setState(() {
                          pickupMethod = value;
                          // OTOMATIS UBAH PEMBAYARAN SESUAI PENGAMBILAN
                          if (pickupMethod == 'Ambil di Student Mart') {
                            paymentMethod = 'Bayar di Kasir';
                          } else {
                            paymentMethod = 'Bayar di Tempat';
                          }
                        });
                      },
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'Ambil di Student Mart',
                            title: const Text('Ambil di Student Mart'),
                            subtitle: const Text(
                              'Ambil pesanan langsung di koperasi',
                            ),
                          ),
                          RadioListTile<String>(
                            value: 'Antar ke Kelas',
                            title: const Text('Antar ke Kelas'),
                            subtitle: const Text('Pesanan diantar ke kelas'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =========================
                  // PEMBAYARAN
                  // =========================
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: RadioGroup<String>(
                      groupValue: paymentMethod,
                      onChanged: (value) {
                        if (isProcessing || value == null) return;
                        setState(() {
                          paymentMethod = value;
                        });
                      },
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'Bayar di Kasir',
                            title: const Text('Bayar di Kasir'),
                            subtitle: const Text(
                              'Bayar saat mengambil pesanan di koperasi',
                            ),
                          ),
                          RadioListTile<String>(
                            value: 'Bayar di Tempat',
                            title: const Text('Bayar di Tempat'),
                            subtitle: const Text(
                              'Bayar saat pesanan diantar ke kelas',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =========================
                  // RINGKASAN
                  // =========================
                  const Text(
                    'Ringkasan Pembayaran',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text(formatRupiah(total)),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Biaya layanan'),
                            const Text('Rp0'),
                          ],
                        ),

                        const Divider(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              formatRupiah(total),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // BUAT PESANAN
                  // =========================
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : createOrder,

                      child: isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Buat Pesanan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
