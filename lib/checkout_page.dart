import 'package:flutter/material.dart';
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
    return 'Rp${price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  Future<void> createOrder() async {
    if (cartController.items.isEmpty) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final items = cartController.items.map((item) {
        return {
          'product_id': item.product.id,
          'quantity': item.quantity,
        };
      }).toList();

      final orderData = await ApiService.createOrder(
        pickupMethod: pickupMethod,
        paymentMethod: paymentMethod,
        items: items,
      );

      if (!mounted) return;

      cartController.clearCart();

      setState(() {
        isProcessing = false;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Pesanan Berhasil 🎉',
            ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Checkout gagal: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = cartController.items;
    final total = cartController.total;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: items.isEmpty
          ? const Center(
              child: Text('Keranjang kosong'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // =========================
                  // PESANAN
                  // =========================

                  const Text(
                    'Pesanan Kamu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: items.map((item) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.grey.shade100,
                                  borderRadius:
                                      BorderRadius.circular(
                                    12,
                                  ),
                                ),
                                child: const Icon(
                                  Icons
                                      .shopping_bag_outlined,
                                  color: Colors.blue,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      '${item.quantity} x ${formatRupiah(item.product.price)}',
                                      style: TextStyle(
                                        color: Colors
                                            .grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                formatRupiah(
                                  item.product.price *
                                      item.quantity,
                                ),
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value:
                              'Ambil di Student Mart',
                          groupValue: pickupMethod,
                          title: const Text(
                            'Ambil di Student Mart',
                          ),
                          subtitle: const Text(
                            'Ambil pesanan langsung di koperasi',
                          ),
                          onChanged: isProcessing
                              ? null
                              : (value) {
                                  setState(() {
                                    pickupMethod =
                                        value!;
                                  });
                                },
                        ),

                        RadioListTile<String>(
                          value: 'Antar ke Kelas',
                          groupValue: pickupMethod,
                          title: const Text(
                            'Antar ke Kelas',
                          ),
                          subtitle: const Text(
                            'Pesanan diantar ke kelas',
                          ),
                          onChanged: isProcessing
                              ? null
                              : (value) {
                                  setState(() {
                                    pickupMethod =
                                        value!;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =========================
                  // PEMBAYARAN
                  // =========================

                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'Bayar di Kasir',
                          groupValue: paymentMethod,
                          title: const Text(
                            'Bayar di Kasir',
                          ),
                          subtitle: const Text(
                            'Bayar saat mengambil pesanan',
                          ),
                          onChanged: isProcessing
                              ? null
                              : (value) {
                                  setState(() {
                                    paymentMethod =
                                        value!;
                                  });
                                },
                        ),

                        RadioListTile<String>(
                          value: 'Saldo Siswa',
                          groupValue: paymentMethod,
                          title: const Text(
                            'Saldo Siswa',
                          ),
                          subtitle: const Text(
                            'Gunakan saldo akun Student Mart',
                          ),
                          onChanged: isProcessing
                              ? null
                              : (value) {
                                  setState(() {
                                    paymentMethod =
                                        value!;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =========================
                  // RINGKASAN
                  // =========================

                  const Text(
                    'Ringkasan Pembayaran',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text(
                              formatRupiah(total),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text(
                              'Biaya layanan',
                            ),
                            const Text('Rp0'),
                          ],
                        ),

                        const Divider(
                          height: 24,
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            Text(
                              formatRupiah(total),
                              style:
                                  const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
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
                      onPressed: isProcessing
                          ? null
                          : createOrder,

                      child: isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Buat Pesanan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
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