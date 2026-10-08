import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';

class ManagerProductImportPage extends StatefulWidget {
  const ManagerProductImportPage({super.key});

  @override
  State<ManagerProductImportPage> createState() =>
      _ManagerProductImportPageState();
}

class _ManagerProductImportPageState
    extends State<ManagerProductImportPage> {
  bool isLoading = false;

  String? selectedFileName;

  List<dynamic> rows = [];
  List<dynamic> errors = [];

  int totalRows = 0;
  int totalErrors = 0;

  Future<void> pickExcel() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'Excel',
        extensions: [
          'xlsx',
          'xls',
          'csv',
        ],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: [typeGroup],
      );

      if (file == null) {
        return;
      }

      final Uint8List fileBytes = await file.readAsBytes();

      if (fileBytes.isEmpty) {
        throw Exception(
          'File tidak dapat dibaca atau kosong.',
        );
      }

      setState(() {
        isLoading = true;
        selectedFileName = file.name;
        rows = [];
        errors = [];
        totalRows = 0;
        totalErrors = 0;
      });

      final data = await ApiService.previewProductExcel(
        fileBytes,
        file.name,
      );

      if (!mounted) return;

      setState(() {
        rows = List<dynamic>.from(
          data['rows'] ?? [],
        );

        errors = List<dynamic>.from(
          data['errors'] ?? [],
        );

        totalRows = data['total_rows'] ?? 0;
        totalErrors = data['total_errors'] ?? 0;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membaca Excel: $e',
          ),
        ),
      );
    }
  }

  Future<void> confirmImport() async {
    if (rows.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Konfirmasi Import',
          ),
          content: Text(
            'Import $totalRows produk ke database?\n\n'
            'Produk baru akan dibuat dan produk '
            'yang barcode-nya sudah ada akan diperbarui.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final result = await ApiService.confirmProductExcel(
        rows,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      final created = result['created'] ?? 0;
      final updated = result['updated'] ?? 0;
      final stockChanged =
          result['stock_changed'] ?? 0;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Import Berhasil',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Produk baru: $created',
                ),
                Text(
                  'Produk diperbarui: $updated',
                ),
                Text(
                  'Stok berubah: $stockChanged',
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Import gagal: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Import Produk Excel',
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildFileButton(),

                  const SizedBox(height: 20),

                  if (selectedFileName != null)
                    Text(
                      'File: $selectedFileName',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 16),

                  if (rows.isNotEmpty)
                    _buildSummary(),

                  if (errors.isNotEmpty)
                    _buildErrors(),

                  const SizedBox(height: 16),

                  Expanded(
                    child: rows.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada file Excel yang dipilih.',
                            ),
                          )
                        : _buildPreview(),
                  ),

                  if (rows.isNotEmpty &&
                      errors.isEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: confirmImport,
                        icon: const Icon(
                          Icons.upload_file,
                        ),
                        label: const Text(
                          'IMPORT KE DATABASE',
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFileButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: pickExcel,
        icon: const Icon(
          Icons.folder_open,
        ),
        label: const Text(
          'Pilih File Excel',
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _summaryItem(
                'Produk',
                totalRows.toString(),
                Icons.inventory_2,
              ),
            ),
            Expanded(
              child: _summaryItem(
                'Error',
                totalErrors.toString(),
                Icons.error_outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
    String title,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title),
      ],
    );
  }

  Widget _buildErrors() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Terdapat kesalahan:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...errors.map(
              (error) {
                return Text(
                  'Baris ${error['row']}: '
                  '${error['message']}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row =
            Map<String, dynamic>.from(
          rows[index],
        );

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                '${index + 1}',
              ),
            ),
            title: Text(
              row['name']?.toString() ?? '-',
            ),
            subtitle: Text(
              'Barcode: ${row['barcode']}\n'
              'Kategori: ${row['category']}\n'
              'Harga: Rp${row['price']}\n'
              'Stok: ${row['stock']}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}