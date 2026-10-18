import 'package:flutter/material.dart';

import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart'; // Tambahkan ini

import 'product_model.dart';
import 'cart_controller.dart'; // Hanya impor class modelnya saja
import 'cart_page.dart';
import 'product_detail_page.dart';
import 'order_page.dart';
import 'api_service.dart';
import 'login_page.dart';
import 'sapaan_random.dart';
import 'supplier_dashboard_page.dart';
import 'submit_advertisement_page.dart';
import 'theme.dart' as theme;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final String custgreetings;

  // Manajemen Navigasi Bawah
  int _bottomNavIndex = 0;

  Timer? _debounceTimer;

  // =====================================================
  // KATEGORI
  // =====================================================
  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = true;
  String selectedCategory = 'Semua';

  // =====================================================
  // PRODUCTS
  // =====================================================
  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;

  // =====================================================
  // ADVERTISEMENTS (IKLAN)
  // =====================================================
  List<dynamic> activeAds = [];
  bool isLoadingAds = true;

  // =====================================================
  // SEARCH
  // =====================================================
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  // =====================================================
  // INIT
  // =====================================================
  @override
  void initState() {
    super.initState();
    custgreetings = SapaanCustRandom.generate();
    searchController.addListener(_searchUpdated);
    _loadAds();
    _loadProducts();
    _loadCategories();
  }

  // =====================================================
  // DISPOSE
  // =====================================================
  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchController.removeListener(_searchUpdated);
    searchController.dispose();
    super.dispose();
  }

  // =====================================================
  // SEARCH UPDATE
  // =====================================================
  void _searchUpdated() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        searchQuery = searchController.text.trim().toLowerCase();
      });
    });
  }

  // =====================================================
  // _goToLogin
  // ====================================================

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // =====================================================
  // LOAD DATA API
  // =====================================================
  Future<void> _loadAds() async {
    if (!mounted) return;
    setState(() => isLoadingAds = true);
    try {
      final data = await ApiService.getActiveAds();
      if (mounted) {
        setState(() {
          activeAds = data;
          isLoadingAds = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingAds = false);
    }
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }
    try {
      final data = await ApiService.getProducts();
      if (!mounted) return;
      setState(() {
        products = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      String friendlyError(Object e) {
        final text = e.toString();
        return text.startsWith('Exception: ')
            ? text.substring('Exception: '.length)
            : 'Terjadi kesalahan. Coba lagi.';
      }

      setState(() {
        errorMessage = friendlyError(e);
        isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    if (mounted) {
      setState(() => isLoadingCategories = true);
    }
    try {
      final result = await ApiService.getCategories();
      if (!mounted) return;
      setState(() {
        categories = result;
        isLoadingCategories = false;
      });
      final categoryExists = categories.any(
        (category) => category['name']?.toString() == selectedCategory,
      );
      if (selectedCategory != 'Semua' && !categoryExists) {
        setState(() {
          selectedCategory = 'Semua';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingCategories = false);
      debugPrint('Gagal mengambil kategori: $e');
    }
  }

  Future<void> _refreshHome() async {
    await Future.wait([_loadAds(), _loadProducts(), _loadCategories()]);
  }

  // =====================================================
  // KELOLA PRODUK
  // =====================================================
  List<Product> get filteredProducts {
    return products.where((product) {
      final name = product.name.toLowerCase();
      final category = product.category.toLowerCase();
      final description = product.description.toLowerCase();
      final matchesSearch =
          searchQuery.isEmpty ||
          name.contains(searchQuery) ||
          category.contains(searchQuery) ||
          description.contains(searchQuery);
      final matchesCategory =
          selectedCategory == 'Semua' ||
          category == selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  String formatRupiah(int price) {
    return 'Rp${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Produk sedang habis.')));
      return;
    }

    // Menggunakan provider secara read untuk menjalankan action
    final cart = context.read<CartController>();
    final existingItem = cart.getItem(product);

    if (existingItem != null && existingItem.quantity >= product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah produk di keranjang sudah mencapai stok.'),
        ),
      );
      return;
    }

    cart.addToCart(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ditambahkan ke keranjang'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // =====================================================
  // NAVIGASI
  // =====================================================
  void _openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
    );
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
  }

  // =====================================================
  // DIALOG AKUN
  // =====================================================
  Future<void> _showAccountDialog() async {
    Map<String, dynamic>? user;
    try {
      user = await ApiService.getMe();
    } catch (_) {
      user = null;
    }
    if (!mounted) return;
    final sessionExpired =
        user == null &&
        (ApiService.authToken == null || ApiService.authToken!.isEmpty);

    if (sessionExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login berakhir. Silakan login kembali.'),
        ),
      );
      _goToLogin();
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hilangkan const karena theme bukan konstan di waktu compile
                CircleAvatar(
                  radius: 38,
                  backgroundColor: theme.paleGreen,
                  child: Icon(
                    Icons.person_rounded,
                    size: 42,
                    color: theme.darkGreen,
                  ),
                ),
                const SizedBox(height: 12),
                if (user?['name'] != null)
                  Text(
                    user?['name'].toString() ?? 'Pengguna Student Mart',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 4),
                if (user?['email'] != null)
                  Text(
                    user!['email'].toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textMuted),
                  ),
                const SizedBox(height: 20),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profil Saya'),
                  subtitle: const Text('Lihat informasi akun'),
                  onTap: () {
                    Navigator.pop(context);
                    _showProfileDialog(user);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.storefront_rounded,
                    color: theme.darkGreen,
                  ),
                  title: const Text('Consignor Dashboard'),
                  subtitle: const Text('Daftar & jual produk titipanmu'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SupplierDashboardPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.campaign_rounded,
                    color: theme.brandGreen,
                  ),
                  title: const Text('Advertisement'),
                  subtitle: const Text('Pasang iklan untuk promosimu'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubmitAdvertisementPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text('Keluar dari akun Student Mart'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLogout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileDialog(Map<String, dynamic>? user) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profil Saya'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 35,
                  child: Icon(Icons.person, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nama',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                user?['name'] ?? 'Tidak tersedia',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Email',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                user?['email'] ?? 'Tidak tersedia',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
    if (result != true) return;
    await _logout();
  }

  Future<void> _logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}
    if (!mounted) return;
    context.read<CartController>().clearCart();
    _goToLogin();
  }

  // =====================================================
  // ICONS & WIDGETS
  // =====================================================
  IconData _categoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'makanan':
        return Icons.fastfood;
      case 'minuman':
        return Icons.local_drink;
      case 'atk':
        return Icons.edit;
      case 'buku':
        return Icons.menu_book;
      case 'elektronik':
        return Icons.devices;
      case 'aksesoris':
        return Icons.shopping_bag;
      case 'kesehatan':
        return Icons.health_and_safety;
      default:
        return Icons.category;
    }
  }

  Widget _buildCategoryItem({
    required String name,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: isSelected ? theme.darkGreen : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? theme.darkGreen : theme.paleGreen,
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.darkGreen.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : theme.brandGreen,
                size: 27,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? theme.darkGreen : theme.textDark,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openProduct(product),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.paleGreen, width: 0.9),
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
            Expanded(
              child: Center(
                child: product.image != null && product.image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ApiService.getImageUrl(product.image),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.shopping_bag,
                            size: 70,
                            color: theme.brandGreen,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.shopping_bag,
                        size: 70,
                        color: theme.brandGreen,
                      ),
              ),
            ),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: theme.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatRupiah(product.price),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: theme.darkGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Stok: ${product.stock}',
              style: TextStyle(
                fontSize: 12,
                color: product.stock > 0 ? theme.textMuted : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: product.stock > 0 ? () => _addToCart(product) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.darkGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: theme.paleGreen,
                  disabledForegroundColor: theme.textMuted,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(product.stock > 0 ? 'Tambah' : 'Habis'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // MAIN HOME CONTENT (Ekstraksi untuk mempermudah Tab)
  // =====================================================
  Widget _buildMainHomeContent(List<Product> visibleProducts, bool showGrid) {
    return RefreshIndicator(
      onRefresh: _refreshHome,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, showGrid ? 0 : 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      hintStyle: const TextStyle(
                        color: theme.textMuted,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: theme.brandGreen,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: searchController,
                        builder: (context, value, _) {
                          if (value.text.isEmpty) return const SizedBox.shrink();
                          return IconButton(
                            onPressed: searchController.clear,
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: theme.textMuted,
                            ),
                          );
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 17,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: theme.paleGreen),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.brandGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (isLoadingAds)
                    SizedBox(
                      height: 160,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.brandGreen,
                        ),
                      ),
                    )
                  else if (activeAds.isNotEmpty)
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 160.0,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 4),
                        enlargeCenterPage: true,
                        viewportFraction: 0.9,
                        aspectRatio: 16 / 9,
                        autoPlayAnimationDuration: const Duration(
                          milliseconds: 800,
                        ),
                      ),
                      items: activeAds.map((ad) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 5.0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: theme.paleGreen,
                                border: Border.all(color: theme.paleGreen),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.darkGreen.withValues(
                                      alpha: 0.10,
                                    ),
                                    spreadRadius: 1,
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: ad['image'] != null
                                    ? Image.network(
                                        ApiService.getImageUrl(ad['image']),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Center(
                                                  child: Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 46,
                                                    color: theme.textMuted,
                                                  ),
                                                ),
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.campaign_rounded,
                                          size: 46,
                                          color: theme.darkGreen,
                                        ),
                                      ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    )
                  else
                    Container(
                      width: double.infinity,
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
                            blurRadius: 16,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROMO STUDENT MART 🎉',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Belanja kebutuhan sekolah lebih mudah!',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  const Text(
                    'Kategori',
                    style: TextStyle(
                      color: theme.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 105,
                    child: isLoadingCategories
                        ? Center(
                            child: CircularProgressIndicator(
                              color: theme.brandGreen,
                            ),
                          )
                        : categories.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada kategori.',
                              style: TextStyle(
                                color: theme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildCategoryItem(
                                  name: 'Semua',
                                  icon: Icons.apps,
                                  isSelected: selectedCategory == 'Semua',
                                  onTap: () => setState(
                                    () => selectedCategory = 'Semua',
                                  ),
                                );
                              }
                              final category = categories[index - 1];
                              final categoryName =
                                  category['name']?.toString() ?? 'Kategori';
                              return _buildCategoryItem(
                                name: categoryName,
                                icon: _categoryIcon(categoryName),
                                isSelected: selectedCategory == categoryName,
                                onTap: () => setState(
                                  () => selectedCategory = categoryName,
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedCategory == 'Semua'
                            ? 'Produk Populer'
                            : 'Produk $selectedCategory',
                        style: const TextStyle(
                          color: theme.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (searchQuery.isNotEmpty)
                        Text(
                          '${visibleProducts.length} hasil',
                          style: const TextStyle(
                            color: theme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.brandGreen,
                        ),
                      ),
                    )
                  else if (errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 58,
                              color: theme.textMuted,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Gagal mengambil produk',
                              style: TextStyle(
                                color: theme.textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: theme.textMuted,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadProducts,
                              icon: const Icon(Icons.refresh_rounded),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.darkGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (visibleProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 58,
                              color: theme.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              searchQuery.isEmpty
                                  ? selectedCategory == 'Semua'
                                        ? 'Belum ada produk.'
                                        : 'Belum ada produk di kategori ini.'
                                  : 'Produk tidak ditemukan.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: theme.textMuted,
                                fontSize: 15,
                                height: 1.45,
                              ),
                            ),
                            if (searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () => searchController.clear(),
                                child: const Text('Hapus pencarian'),
                              ),
                            if (selectedCategory != 'Semua' &&
                                searchQuery.isEmpty)
                              TextButton(
                                onPressed: () =>
                                    setState(() => selectedCategory = 'Semua'),
                                child: const Text('Lihat semua produk'),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (showGrid)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildProductCard(visibleProducts[index]),
                  childCount: visibleProducts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final visibleProducts = filteredProducts;
    final showGrid =
        !isLoading && errorMessage == null && visibleProducts.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.pageBackground,

      // =================================================
      // APP BAR
      // =================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: theme.darkGreen,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              custgreetings,
              style: const TextStyle(
                fontSize: 13,
                color: theme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              'Student Mart',
              style: TextStyle(
                fontSize: 21,
                color: theme.textDark,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belum ada notifikasi.')),
              );
            },
            icon: Icon(
              Icons.notifications_none_rounded,
              color: theme.darkGreen,
            ),
          ),

          // Menggunakan Consumer untuk memantau nilai Badge Keranjang
          Consumer<CartController>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: _openCart,
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      color: theme.darkGreen,
                    ),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          cart.itemCount > 99 ? '99+' : '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      // =================================================
      // BODY (Dengan IndexedStack)
      // =================================================
      body: IndexedStack(
        index: _bottomNavIndex,
        children: [
          // Index 0: Halaman Utama
          _buildMainHomeContent(visibleProducts, showGrid),

          // Index 1: Halaman Pesanan
          const OrderPage(),
        ],
      ),

      // =================================================
      // BOTTOM NAVIGATION
      // =================================================
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: theme.pageBackground,
          indicatorColor: theme.paleGreen,
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: isSelected ? theme.darkGreen : theme.textMuted,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              color: isSelected ? theme.darkGreen : theme.textMuted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _bottomNavIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Pesanan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Akun',
            ),
          ],
          onDestinationSelected: (index) {
            if (index == 2) {
              // Jika menu akun ditekan, hanya buka dialog profil (jangan pindah tab)
              _showAccountDialog();
            } else {
              // Jika menu home/pesanan ditekan, pindahkan IndexedStack
              setState(() {
                _bottomNavIndex = index;
              });
            }
          },
        ),
      ),
    );
  }
}
