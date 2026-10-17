import 'package:flutter/material.dart';

import 'api_service.dart';

class ManagerAdsPage extends StatefulWidget {
  const ManagerAdsPage({super.key});

  @override
  State<ManagerAdsPage> createState() => _ManagerAdsPageState();
}

class _ManagerAdsPageState extends State<ManagerAdsPage> {
  List<dynamic> _pendingAds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingAds();
  }

  Future<void> _fetchPendingAds() async {
    setState(() => _isLoading = true);
    try {
      final ads = await ApiService.getPendingAds();
      setState(() {
        _pendingAds = ads;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerify(int adId, String action) async {
    // Konfirmasi dialog sebelum aksi
    bool isApprove = action == 'approve';
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApprove ? 'Setujui Iklan?' : 'Tolak Iklan?'),
        content: Text(
          isApprove
              ? 'Pastikan pembayaran sudah diterima (baik tunai di koperasi atau e-wallet). Iklan akan langsung tayang setelah disetujui.'
              : 'Apakah Anda yakin ingin menolak pengajuan iklan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isApprove ? 'Ya, Setujui' : 'Ya, Tolak',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.verifyAd(adId: adId, action: action);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApprove
                ? 'Iklan berhasil disetujui dan sedang tayang!'
                : 'Iklan ditolak.',
          ),
          backgroundColor: isApprove ? Colors.green : Colors.red,
        ),
      );
      _fetchPendingAds(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  // Format ke Rupiah
  String formatRupiah(int price) {
    return 'Rp${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  // Format penamaan paket
  String formatPackageName(String package) {
    switch (package) {
      case '1_month_promo':
        return '1 Bulan (Promo)';
      case '2_month_promo':
        return '2 Bulan (Promo + Unggulan)';
      case '1_month_normal':
        return '1 Bulan (Normal)';
      case '2_month_normal':
        return '2 Bulan (Normal + Unggulan)';
      default:
        return package;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verifikasi Iklan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingAds.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada pengajuan iklan baru.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingAds.length,
              itemBuilder: (context, index) {
                final ad = _pendingAds[index];
                final user = ad['user'] ?? {};

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER INFO MITRA
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? 'Pemasok',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    user['email'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ad['payment_method'] == 'cash_koperasi'
                                    ? Colors.orange.shade100
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ad['payment_method'] == 'cash_koperasi'
                                    ? 'Tunai Koperasi'
                                    : 'Transfer/Digital',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: ad['payment_method'] == 'cash_koperasi'
                                      ? Colors.orange.shade800
                                      : Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // INFO IKLAN
                        Text(
                          ad['title'] ?? 'Tanpa Judul',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // BANNER IKLAN
                        if (ad['image'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              ApiService.getImageUrl(ad['image']),
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),

                        // DETAIL PAKET & HARGA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Paket: ${formatPackageName(ad['package_type'])}',
                            ),
                            Text(
                              formatRupiah(ad['total_price']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // TOMBOL AKSI
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _handleVerify(ad['id'], 'reject'),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Tolak',
                                  style: TextStyle(color: Colors.red),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _handleVerify(ad['id'], 'approve'),
                                icon: const Icon(Icons.check),
                                label: const Text('Setujui & Tayangkan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
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
