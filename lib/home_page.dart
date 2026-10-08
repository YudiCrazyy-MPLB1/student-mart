import 'package:flutter/material.dart';

import 'product_model.dart';
import 'cart_controller.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';
import 'order_page.dart';
import 'api_service.dart';
import 'login_page.dart';
import 'sapaan_random.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  late final String custgreetings;
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
  // SEARCH
  // =====================================================

  final TextEditingController searchController =
      TextEditingController();

  String searchQuery = '';

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    custgreetings = SapaanCustRandom.generate();

    cartController.addListener(_cartUpdated);
    searchController.addListener(_searchUpdated);

    _loadProducts();
    _loadCategories();
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    cartController.removeListener(_cartUpdated);
    searchController.removeListener(_searchUpdated);

    searchController.dispose();

    super.dispose();
  }

  // =====================================================
  // CART UPDATE
  // =====================================================

  void _cartUpdated() {
    if (!mounted) return;

    setState(() {});
  }

  // =====================================================
  // SEARCH UPDATE
  // =====================================================

  void _searchUpdated() {
    if (!mounted) return;

    setState(() {
      searchQuery =
          searchController.text.trim().toLowerCase();
    });
  }

  // =====================================================
  // LOAD PRODUCTS
  // =====================================================

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

      setState(() {
        errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');

        isLoading = false;
      });
    }
  }

  // =====================================================
  // LOAD CATEGORIES
  // =====================================================

  Future<void> _loadCategories() async {
    if (mounted) {
      setState(() {
        isLoadingCategories = true;
      });
    }

    try {
      final result = await ApiService.getCategories();

      if (!mounted) return;

      setState(() {
        categories = result;
        isLoadingCategories = false;
      });

      // Jika kategori yang sebelumnya dipilih
      // sudah tidak tersedia di database.
      final categoryExists = categories.any(
        (category) =>
            category['name']?.toString() ==
            selectedCategory,
      );

      if (selectedCategory != 'Semua' &&
          !categoryExists) {
        setState(() {
          selectedCategory = 'Semua';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingCategories = false;
      });

      debugPrint(
        'Gagal mengambil kategori: $e',
      );
    }
  }

  // =====================================================
  // REFRESH HOME
  // =====================================================

  Future<void> _refreshHome() async {
    await Future.wait([
      _loadProducts(),
      _loadCategories(),
    ]);
  }

  // =====================================================
  // CATEGORY ICON
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

  // =====================================================
  // FILTERED PRODUCTS
  // =====================================================

  List<Product> get filteredProducts {
    return products.where((product) {
      final name = product.name.toLowerCase();

      final category =
          product.category.toLowerCase();

      final description =
          product.description.toLowerCase();

      final matchesSearch =
          searchQuery.isEmpty ||
          name.contains(searchQuery) ||
          category.contains(searchQuery) ||
          description.contains(searchQuery);

      final matchesCategory =
          selectedCategory == 'Semua' ||
          category ==
              selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // =====================================================
  // FORMAT RUPIAH
  // =====================================================

  String formatRupiah(int price) {
    return 'Rp${price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  // =====================================================
  // ADD TO CART
  // =====================================================

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Produk sedang habis.',
          ),
        ),
      );

      return;
    }

    final existingItem =
        cartController.getItem(product);

    if (existingItem != null &&
        existingItem.quantity >= product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Jumlah produk di keranjang sudah mencapai stok.',
          ),
        ),
      );

      return;
    }

    cartController.addToCart(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} ditambahkan ke keranjang',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // =====================================================
  // ACCOUNT
  // =====================================================

  Future<void> _showAccountDialog() async {
    Map<String, dynamic>? user;

    try {
      user = await ApiService.getMe();
    } catch (_) {
      user = null;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PROFILE ICON
                const CircleAvatar(
                  radius: 38,
                  child: Icon(
                    Icons.person,
                    size: 42,
                  ),
                ),

                const SizedBox(height: 12),

                // NAME
                Text(
                  user?['name'] ??
                      'Pengguna Student Mart',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // EMAIL
                if (user?['email'] != null)
                  Text(
                    user!['email'].toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                const SizedBox(height: 20),

                const Divider(),

                // PROFILE
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                  ),
                  title: const Text(
                    'Profil Saya',
                  ),
                  subtitle: const Text(
                    'Lihat informasi akun',
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    _showProfileDialog(user);
                  },
                ),

                // LOGOUT
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Keluar dari akun Student Mart',
                  ),
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

  // =====================================================
  // PROFILE DIALOG
  // =====================================================

  void _showProfileDialog(
    Map<String, dynamic>? user,
  ) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Profil Saya',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 35,
                  child: Icon(
                    Icons.person,
                    size: 40,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Nama',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                user?['name'] ??
                    'Tidak tersedia',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                user?['email'] ??
                    'Tidak tersedia',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Tutup',
              ),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // CONFIRM LOGOUT
  // =====================================================

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Logout',
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Batal',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    await _logout();
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> _logout() async {
    try {
      await ApiService.logout();
    } catch (_) {
      // ApiService tetap menghapus token lokal.
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  // =====================================================
  // OPEN PRODUCT
  // =====================================================

  void _openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: product,
        ),
      ),
    );
  }

  // =====================================================
  // OPEN CART
  // =====================================================

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CartPage(),
      ),
    );
  }

  // =====================================================
  // OPEN ORDERS
  // =====================================================

  void _openOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OrderPage(),
      ),
    );
  }

  // =====================================================
  // CATEGORY ITEM
  // =====================================================

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
        margin: const EdgeInsets.only(
          right: 12,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 200),
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                      : Colors.grey.shade200,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Colors.blue,
                size: 28,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              name,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final visibleProducts =
        filteredProducts;

    return Scaffold(
      backgroundColor:
          Colors.grey.shade100,

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              custgreetings,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            Text(
              'Student Mart',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [
          // NOTIFICATION
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Belum ada notifikasi.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none,
            ),
          ),

          // CART
          Stack(
            children: [
              IconButton(
                onPressed: _openCart,
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                ),
              ),

              if (cartController.itemCount > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding:
                        const EdgeInsets.all(5),
                    decoration:
                        const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      cartController.itemCount >
                              99
                          ? '99+'
                          : '${cartController.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      // =================================================
      // BODY
      // =================================================

      body: RefreshIndicator(
        onRefresh: _refreshHome,

        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // =========================================
              // SEARCH
              // =========================================

              TextField(
                controller:
                    searchController,

                textInputAction:
                    TextInputAction.search,

                decoration:
                    InputDecoration(
                  hintText:
                      'Cari produk...',

                  prefixIcon:
                      const Icon(
                    Icons.search,
                  ),

                  suffixIcon:
                      searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController
                                    .clear();
                              },
                              icon:
                                  const Icon(
                                Icons.clear,
                              ),
                            )
                          : null,

                  filled: true,

                  fillColor:
                      Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =========================================
              // PROMO
              // =========================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(20),

                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  color: Colors.blue,
                ),

                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'PROMO STUDENT MART 🎉',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Belanja kebutuhan sekolah lebih mudah!',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =========================================
              // CATEGORY
              // =========================================

              const Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 105,

                child: isLoadingCategories
                    ? const Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    : categories.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada kategori.',
                              style: TextStyle(
                                color:
                                    Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection:
                                Axis.horizontal,

                            itemCount:
                                categories.length +
                                    1,

                            itemBuilder:
                                (context, index) {
                              // SEMUA
                              if (index == 0) {
                                final isSelected =
                                    selectedCategory ==
                                        'Semua';

                                return _buildCategoryItem(
                                  name: 'Semua',
                                  icon: Icons.apps,
                                  isSelected:
                                      isSelected,
                                  onTap: () {
                                    setState(() {
                                      selectedCategory =
                                          'Semua';
                                    });
                                  },
                                );
                              }

                              // CATEGORY DATABASE
                              final category =
                                  categories[
                                      index - 1];

                              final categoryName =
                                  category['name']
                                          ?.toString() ??
                                      'Kategori';

                              final isSelected =
                                  selectedCategory ==
                                      categoryName;

                              return _buildCategoryItem(
                                name:
                                    categoryName,
                                icon:
                                    _categoryIcon(
                                  categoryName,
                                ),
                                isSelected:
                                    isSelected,
                                onTap: () {
                                  setState(() {
                                    selectedCategory =
                                        categoryName;
                                  });
                                },
                              );
                            },
                          ),
              ),

              const SizedBox(height: 24),

              // =========================================
              // PRODUCT TITLE
              // =========================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  Text(
                    selectedCategory == 'Semua'
                        ? 'Produk Populer'
                        : 'Produk $selectedCategory',

                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (searchQuery.isNotEmpty)
                    Text(
                      '${visibleProducts.length} hasil',
                      style:
                          const TextStyle(
                        color:
                            Colors.grey,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // =========================================
              // LOADING
              // =========================================

              if (isLoading)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 50,
                  ),

                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )

              // =========================================
              // ERROR
              // =========================================

              else if (errorMessage != null)
                Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      30,
                    ),

                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 60,
                          color:
                              Colors.grey,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        const Text(
                          'Gagal mengambil produk',
                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          errorMessage!,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        ElevatedButton
                            .icon(
                          onPressed:
                              _loadProducts,
                          icon:
                              const Icon(
                            Icons.refresh,
                          ),
                          label:
                              const Text(
                            'Coba Lagi',
                          ),
                        ),
                      ],
                    ),
                  ),
                )

              // =========================================
              // EMPTY
              // =========================================

              else if (visibleProducts.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 50,
                  ),

                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 60,
                          color:
                              Colors.grey,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Text(
                          searchQuery
                                  .isEmpty
                              ? selectedCategory ==
                                      'Semua'
                                  ? 'Belum ada produk.'
                                  : 'Belum ada produk di kategori ini.'
                              : 'Produk tidak ditemukan.',

                          textAlign:
                              TextAlign.center,

                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                            fontSize: 16,
                          ),
                        ),

                        if (searchQuery
                            .isNotEmpty)
                          TextButton(
                            onPressed: () {
                              searchController
                                  .clear();
                            },
                            child:
                                const Text(
                              'Hapus pencarian',
                            ),
                          ),

                        if (selectedCategory !=
                                'Semua' &&
                            searchQuery.isEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory =
                                    'Semua';
                              });
                            },
                            child:
                                const Text(
                              'Lihat semua produk',
                            ),
                          ),
                      ],
                    ),
                  ),
                )

              // =========================================
              // PRODUCT GRID
              // =========================================

              else
                GridView.builder(
                  shrinkWrap: true,

                  physics:
                      const NeverScrollableScrollPhysics(),

                  itemCount:
                      visibleProducts.length,

                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,

                    crossAxisSpacing:
                        12,

                    mainAxisSpacing:
                        12,

                    childAspectRatio:
                        0.72,
                  ),

                  itemBuilder:
                      (context, index) {
                    final product =
                        visibleProducts[
                            index];

                    return InkWell(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),

                      onTap: () {
                        _openProduct(
                          product,
                        );
                      },

                      child: Container(
                        padding:
                            const EdgeInsets
                                .all(
                          12,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            // IMAGE
                            Expanded(
                              child: Center(
                                child: product
                                            .image !=
                                        null &&
                                    product
                                        .image!
                                        .isNotEmpty
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          12,
                                        ),
                                        child:
                                            Image.network(
                                          product
                                              .image!,
                                          fit: BoxFit
                                              .contain,
                                          errorBuilder:
                                              (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Icon(
                                              Icons
                                                  .shopping_bag,
                                              size:
                                                  70,
                                              color:
                                                  Colors.blue,
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons
                                            .shopping_bag,
                                        size:
                                            70,
                                        color:
                                            Colors.blue,
                                      ),
                              ),
                            ),

                            // NAME
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,

                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            const SizedBox(
                              height: 6,
                            ),

                            // PRICE
                            Text(
                              formatRupiah(
                                product.price,
                              ),

                              style:
                                  const TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color:
                                    Colors.blue,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            // STOCK
                            Text(
                              'Stok: ${product.stock}',

                              style:
                                  TextStyle(
                                fontSize:
                                    12,
                                color: product
                                            .stock >
                                        0
                                    ? Colors
                                        .grey
                                    : Colors
                                        .red,
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            // BUTTON
                            SizedBox(
                              width:
                                  double.infinity,

                              child:
                                  ElevatedButton(
                                onPressed:
                                    product.stock >
                                            0
                                        ? () {
                                            _addToCart(
                                              product,
                                            );
                                          }
                                        : null,

                                child: Text(
                                  product.stock >
                                          0
                                      ? 'Tambah'
                                      : 'Habis',
                                ),
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
        ),
      ),

      // =================================================
      // BOTTOM NAVIGATION
      // =================================================

      bottomNavigationBar:
          NavigationBar(
        selectedIndex: 0,

        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.receipt_long_outlined,
            ),
            selectedIcon: Icon(
              Icons.receipt_long,
            ),
            label: 'Pesanan',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Akun',
          ),
        ],

        onDestinationSelected:
            (index) {
          if (index == 1) {
            _openOrders();
          }

          if (index == 2) {
            _showAccountDialog();
          }
        },
      ),
    );
  }
}