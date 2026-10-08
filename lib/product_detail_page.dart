import 'package:flutter/material.dart';

import 'product_model.dart';
import 'cart_controller.dart';
import 'cart_page.dart';
import 'api_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() =>
      _ProductDetailPageState();
}

class _ProductDetailPageState
    extends State<ProductDetailPage> {
  Product? product;

  bool isLoading = true;
  String? errorMessage;

  int quantity = 1;

  String formatRupiah(int price) {
    return 'Rp${price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  @override
  void initState() {
    super.initState();

    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final data = await ApiService.getProduct(
        widget.product.id,
      );

      if (!mounted) return;

      setState(() {
        product = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _increaseQuantity() {
    if (product == null) return;

    if (quantity < product!.stock) {
      setState(() {
        quantity++;
      });
    }
  }

  void _decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  void _addToCart() {
    if (product == null) return;

    if (product!.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk sedang habis.'),
        ),
      );

      return;
    }

    for (int i = 0; i < quantity; i++) {
      cartController.addToCart(product!);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$quantity ${product!.name} ditambahkan ke keranjang',
        ),
        action: SnackBarAction(
          label: 'Lihat',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CartPage(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal mengambil produk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });

                  _loadProduct();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (product == null) {
      return const Center(
        child: Text('Produk tidak ditemukan.'),
      );
    }

    final currentProduct = product!;

    final int subtotal =
        currentProduct.price * quantity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // GAMBAR
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.shopping_bag,
              size: 120,
              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 24),

          // KATEGORI
          Text(
            currentProduct.category,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // NAMA
          Text(
            currentProduct.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // HARGA
          Text(
            formatRupiah(currentProduct.price),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 8),

          // STOK
          Text(
            'Stok tersedia: ${currentProduct.stock}',
            style: TextStyle(
              color: currentProduct.stock > 0
                  ? Colors.grey
                  : Colors.red,
            ),
          ),

          const SizedBox(height: 20),

          // DESKRIPSI
          const Text(
            'Deskripsi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            currentProduct.description.isEmpty
                ? 'Tidak ada deskripsi.'
                : currentProduct.description,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // JUMLAH
          const Text(
            'Jumlah',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              IconButton(
                onPressed: _decreaseQuantity,
                icon: const Icon(
                  Icons.remove_circle_outline,
                ),
              ),

              Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              IconButton(
                onPressed: _increaseQuantity,
                icon: const Icon(
                  Icons.add_circle_outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // SUBTOTAL
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                formatRupiah(subtotal),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // TOMBOL
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: currentProduct.stock > 0
                  ? _addToCart
                  : null,
              child: Text(
                currentProduct.stock > 0
                    ? 'Tambah ke Keranjang'
                    : 'Produk Habis',
              ),
            ),
          ),
        ],
      ),
    );
  }
}