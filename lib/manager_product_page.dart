import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';
import 'product_model.dart';

class ManagerProductPage extends StatefulWidget {
  const ManagerProductPage({super.key});

  @override
  State<ManagerProductPage> createState() => _ManagerProductPageState();
}

class _ManagerProductPageState extends State<ManagerProductPage> {
  List<Product> products = [];
  List<Map<String, dynamic>> categories = [];

  bool isLoading = true;
  bool isLoadingCategories = true;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();

    loadProducts();
    loadCategories();
  }

  // ============================================================
  // LOAD PRODUCTS
  // ============================================================

  Future<void> loadProducts() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final result = await ApiService.getManagerProducts();

      if (!mounted) return;

      setState(() {
        products = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Gagal mengambil produk: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // LOAD CATEGORIES
  // ============================================================

  Future<void> loadCategories() async {
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingCategories = false;
      });

      showMessage(
        'Gagal mengambil kategori: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // FILTER PRODUCT
  // ============================================================

  List<Product> get filteredProducts {
    if (searchQuery.trim().isEmpty) {
      return products;
    }

    final query = searchQuery.toLowerCase().trim();

    return products.where((product) {
      return product.name.toLowerCase().contains(query);
    }).toList();
  }

  // ============================================================
  // DEACTIVATE PRODUCT
  // ============================================================

  Future<void> deactivateProduct(Product product) async {
    try {
      await ApiService.deactivateManagerProduct(product.id);

      if (!mounted) return;

      showMessage(
        'Produk berhasil dinonaktifkan.',
      );

      await loadProducts();
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Gagal menonaktifkan produk: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // ACTIVATE PRODUCT
  // ============================================================

  Future<void> activateProduct(Product product) async {
    try {
      await ApiService.activateManagerProduct(product.id);

      if (!mounted) return;

      showMessage(
        'Produk berhasil diaktifkan.',
      );

      await loadProducts();
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Gagal mengaktifkan produk: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> pickProductImage({
    required ImagePicker imagePicker,
    required void Function(void Function()) setDialogState,
    required void Function(XFile?) setSelectedImage,
    required void Function(Uint8List?) setSelectedImageBytes,
  }) async {
    try {
      final image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();

      setDialogState(() {
        setSelectedImage(image);
        setSelectedImageBytes(bytes);
      });
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Gagal memilih gambar: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // PRODUCT FORM
  // ============================================================

  Future<void> showProductForm({
    Product? product,
  }) async {
    final nameController = TextEditingController(
      text: product?.name ?? '',
    );

    final descriptionController = TextEditingController(
      text: product?.description ?? '',
    );

    final priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );

    final stockController = TextEditingController(
      text: product?.stock.toString() ?? '',
    );

    final imagePicker = ImagePicker();

    XFile? selectedImage;
    Uint8List? selectedImageBytes;

    int? selectedCategoryId = product?.categoryId;

    bool isActive = product?.isActive ?? true;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                product == null
                    ? 'Tambah Produk'
                    : 'Edit Produk',
              ),

              content: SizedBox(
                width: 500,

                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        // ==================================================
                        // NAMA
                        // ==================================================

                        TextFormField(
                          controller: nameController,

                          decoration: const InputDecoration(
                            labelText: 'Nama Produk',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.inventory_2_outlined,
                            ),
                          ),

                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Nama produk wajib diisi.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // ==================================================
                        // DESKRIPSI
                        // ==================================================

                        TextFormField(
                          controller: descriptionController,

                          maxLines: 3,

                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.description_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ==================================================
                        // KATEGORI
                        // ==================================================

                        if (isLoadingCategories)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            child: CircularProgressIndicator(),
                          )
                        else
                          DropdownButtonFormField<int>(
  initialValue: selectedCategoryId,

  decoration: const InputDecoration(
    labelText: 'Kategori',
    border: OutlineInputBorder(),
    prefixIcon: Icon(
      Icons.category_outlined,
    ),
  ),

  items: categories.map((category) {
    final dynamic rawId = category['id'];

    final int? categoryId = rawId is int
        ? rawId
        : int.tryParse(rawId.toString());

    if (categoryId == null) {
      return null;
    }

    return DropdownMenuItem<int>(
      value: categoryId,
      child: Text(
        category['name']?.toString() ?? 'Tanpa Nama',
      ),
    );
  }).whereType<DropdownMenuItem<int>>().toList(),

  onChanged: categories.isEmpty
      ? null
      : (value) {
          setDialogState(() {
            selectedCategoryId = value;
          });
        },

  validator: (value) {
    if (value == null) {
      return 'Kategori wajib dipilih.';
    }

    return null;
  },
),

                        const SizedBox(height: 12),

                        // ==================================================
                        // HARGA
                        // ==================================================

                        TextFormField(
                          controller: priceController,

                          keyboardType:
                              TextInputType.number,

                          decoration:
                              const InputDecoration(
                            labelText: 'Harga',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.payments_outlined,
                            ),
                          ),

                          validator: (value) {
                            final price =
                                int.tryParse(
                              value ?? '',
                            );

                            if (price == null ||
                                price < 0) {
                              return 'Harga tidak valid.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // ==================================================
                        // STOK
                        // ==================================================

                        TextFormField(
                          controller: stockController,

                          keyboardType:
                              TextInputType.number,

                          decoration:
                              const InputDecoration(
                            labelText: 'Stok',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.inventory_outlined,
                            ),
                          ),

                          validator: (value) {
                            final stock =
                                int.tryParse(
                              value ?? '',
                            );

                            if (stock == null ||
                                stock < 0) {
                              return 'Stok tidak valid.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // IMAGE UPLOAD
                        // ==================================================

                        Align(
                          alignment:
                              Alignment.centerLeft,

                          child: const Text(
                            'Gambar Produk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          height: 200,

                          decoration: BoxDecoration(
                            color:
                                Colors.grey.shade100,

                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),

                            border: Border.all(
                              color:
                                  Colors.grey.shade400,
                            ),
                          ),

                          clipBehavior:
                              Clip.antiAlias,

                          child:
                              selectedImageBytes != null
                                  ? Image.memory(
                                      selectedImageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : product?.image != null &&
                                          product!.image!
                                              .trim()
                                              .isNotEmpty
                                      ? Image.network(
                                          ApiService
                                              .getImageUrl(
                                            product.image,
                                          ),

                                          fit:
                                              BoxFit.cover,

                                          loadingBuilder:
                                              (
                                            context,
                                            child,
                                            loadingProgress,
                                          ) {
                                            if (loadingProgress ==
                                                null) {
                                              return child;
                                            }

                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },

                                          errorBuilder:
                                              (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    size: 50,
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        8,
                                                  ),
                                                  Text(
                                                    'Gambar tidak dapat dimuat',
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                      : const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                size: 55,
                                              ),
                                              SizedBox(
                                                height: 8,
                                              ),
                                              Text(
                                                'Belum ada gambar',
                                              ),
                                            ],
                                          ),
                                        ),
                        ),

                        const SizedBox(height: 10),

                        // ==================================================
                        // BUTTON PICK IMAGE
                        // ==================================================

                        SizedBox(
                          width: double.infinity,

                          child:
                              OutlinedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    await pickProductImage(
                                      imagePicker:
                                          imagePicker,

                                      setDialogState:
                                          setDialogState,

                                      setSelectedImage:
                                          (image) {
                                        selectedImage =
                                            image;
                                      },

                                      setSelectedImageBytes:
                                          (bytes) {
                                        selectedImageBytes =
                                            bytes;
                                      },
                                    );
                                  },

                            icon: const Icon(
                              Icons
                                  .add_photo_alternate_outlined,
                            ),

                            label: Text(
                              selectedImage == null
                                  ? 'Pilih Gambar'
                                  : 'Ganti Gambar',
                            ),
                          ),
                        ),

                        // ==================================================
                        // IMAGE INFO
                        // ==================================================

                        if (selectedImage != null) ...[
                          const SizedBox(height: 6),

                          Align(
                            alignment:
                                Alignment.centerLeft,

                            child: Text(
                              selectedImage!.name,

                              style: TextStyle(
                                fontSize: 12,
                                color: Colors
                                    .grey.shade700,
                              ),

                              maxLines: 1,

                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // ==================================================
                        // ACTIVE SWITCH
                        // ==================================================

                        SwitchListTile(
                          contentPadding:
                              EdgeInsets.zero,

                          title: const Text(
                            'Produk Aktif',
                          ),

                          subtitle: Text(
                            isActive
                                ? 'Produk dapat dilihat dan dibeli siswa'
                                : 'Produk tidak ditampilkan kepada siswa',
                          ),

                          value: isActive,

                          onChanged: isSaving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    isActive =
                                        value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ============================================================
              // ACTIONS
              // ============================================================

              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                          );
                        },

                  child: const Text(
                    'Batal',
                  ),
                ),

                FilledButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey
                              .currentState!
                              .validate()) {
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            final name =
                                nameController
                                    .text
                                    .trim();

                            final description =
                                descriptionController
                                    .text
                                    .trim();

                            final price =
                                int.parse(
                              priceController
                                  .text
                                  .trim(),
                            );

                            final stock =
                                int.parse(
                              stockController
                                  .text
                                  .trim(),
                            );

                            // ==================================================
                            // CREATE
                            // ==================================================

                            if (product == null) {
                              await ApiService
                                  .createManagerProduct(
                                categoryId:
                                    selectedCategoryId!,

                                name: name,

                                description:
                                    description
                                            .isEmpty
                                        ? null
                                        : description,

                                price: price,

                                stock: stock,

                                isActive: isActive,

                                imageFile:
                                    selectedImage,
                              );
                            }

                            // ==================================================
                            // UPDATE
                            // ==================================================

                            else {
                              await ApiService
                                  .updateManagerProduct(
                                productId:
                                    product.id,

                                categoryId:
                                    selectedCategoryId!,

                                name: name,

                                description:
                                    description
                                            .isEmpty
                                        ? null
                                        : description,

                                price: price,

                                stock: stock,

                                isActive: isActive,

                                imageFile:
                                    selectedImage,
                              );
                            }

                            if (!mounted) return;

                            Navigator.pop(
                              context,
                            );

                            showMessage(
                              product == null
                                  ? 'Produk berhasil ditambahkan.'
                                  : 'Produk berhasil diperbarui.',
                            );

                            await loadProducts();
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            if (!mounted) return;

                            showMessage(
                              'Gagal menyimpan produk: $e',
                              isError: true,
                            );
                          }
                        },

                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                        ),

                  label: Text(
                    isSaving
                        ? 'Menyimpan...'
                        : 'Simpan',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // ============================================================
    // DISPOSE CONTROLLERS
    // ============================================================

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : null,
      ),
    );
  }

  // ============================================================
  // FORMAT PRICE
  // ============================================================

  String formatPrice(int price) {
    return 'Rp ${price.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}';
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget buildProductImage(
  String? image, {
  double width = 60,
  double height = 60,
  double borderRadius = 8,
}) {
  final imageUrl = ApiService.getImageUrl(image);

  if (imageUrl.isEmpty) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(
          borderRadius,
        ),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey,
      ),
    );
  }

  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(
        borderRadius,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
          ),
        );
      },
    ),
  );
}

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final visibleProducts =
        filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Produk',
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',

            onPressed: isLoading
                ? null
                : loadProducts,

            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          showProductForm();
        },

        icon: const Icon(
          Icons.add,
        ),

        label: const Text(
          'Tambah Produk',
        ),
      ),

      body: Column(
        children: [
          // ========================================================
          // SEARCH
          // ========================================================

          Padding(
            padding:
                const EdgeInsets.all(16),

            child: TextField(
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
                              setState(() {
                                searchQuery =
                                    '';
                              });
                            },

                            icon:
                                const Icon(
                              Icons.clear,
                            ),
                          )
                        : null,

                border:
                    const OutlineInputBorder(),

                filled: true,
              ),

              onChanged: (value) {
                setState(() {
                  searchQuery =
                      value;
                });
              },
            ),
          ),

          // ========================================================
          // PRODUCT LIST
          // ========================================================

          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : visibleProducts
                        .isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [
                            Icon(
                              Icons
                                  .inventory_2_outlined,
                              size: 70,
                              color: Colors
                                  .grey.shade400,
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            const Text(
                              'Produk tidak ditemukan.',
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh:
                            loadProducts,

                        child:
                            ListView.builder(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            16,
                            0,
                            16,
                            100,
                          ),

                          itemCount:
                              visibleProducts
                                  .length,

                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            final product =
                                visibleProducts[
                                    index];

                            return Card(
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 12,
                              ),

                              child:
                                  ListTile(
                                contentPadding:
                                    const EdgeInsets
                                        .all(
                                  12,
                                ),

                                // ==================================================
                                // PRODUCT IMAGE
                                // ==================================================

                                leading:
                                    buildProductImage(
                                  product.image,
                                ),

                                // ==================================================
                                // PRODUCT NAME
                                // ==================================================

                                title: Text(
                                  product.name,

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize: 16,
                                  ),
                                ),

                                // ==================================================
                                // PRODUCT INFO
                                // ==================================================

                                subtitle:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      formatPrice(
                                        product.price,
                                      ),

                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 2,
                                    ),

                                    Text(
                                      'Stok: ${product.stock}',
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Row(
                                      children: [
                                        Icon(
                                          product
                                                  .isActive
                                              ? Icons
                                                  .check_circle
                                              : Icons
                                                  .cancel,

                                          size: 16,

                                          color: product
                                                  .isActive
                                              ? Colors
                                                  .green
                                              : Colors
                                                  .red,
                                        ),

                                        const SizedBox(
                                          width: 5,
                                        ),

                                        Text(
                                          product
                                                  .isActive
                                              ? 'Aktif'
                                              : 'Nonaktif',

                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,

                                            color: product
                                                    .isActive
                                                ? Colors
                                                    .green
                                                : Colors
                                                    .red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // ==================================================
                                // MENU
                                // ==================================================

                                trailing:
                                    PopupMenuButton<
                                        String>(
                                  onSelected:
                                      (
                                    value,
                                  ) async {
                                    if (value ==
                                        'edit') {
                                      await showProductForm(
                                        product:
                                            product,
                                      );
                                    }

                                    if (value ==
                                        'deactivate') {
                                      await deactivateProduct(
                                        product,
                                      );
                                    }

                                    if (value ==
                                        'activate') {
                                      await activateProduct(
                                        product,
                                      );
                                    }
                                  },

                                  itemBuilder:
                                      (
                                    context,
                                  ) {
                                    return [
                                      const PopupMenuItem<
                                          String>(
                                        value:
                                            'edit',

                                        child:
                                            Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .edit_outlined,
                                            ),

                                            SizedBox(
                                              width:
                                                  8,
                                            ),

                                            Text(
                                              'Edit',
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (product
                                          .isActive)
                                        const PopupMenuItem<
                                            String>(
                                          value:
                                              'deactivate',

                                          child:
                                              Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .visibility_off_outlined,
                                              ),

                                              SizedBox(
                                                width:
                                                    8,
                                              ),

                                              Text(
                                                'Nonaktifkan',
                                              ),
                                            ],
                                          ),
                                        ),

                                      if (!product
                                          .isActive)
                                        const PopupMenuItem<
                                            String>(
                                          value:
                                              'activate',

                                          child:
                                              Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .visibility_outlined,
                                              ),

                                              SizedBox(
                                                width:
                                                    8,
                                              ),

                                              Text(
                                                'Aktifkan',
                                              ),
                                            ],
                                          ),
                                        ),
                                    ];
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}