import 'dart:async';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_cached_image.dart';
import 'manager_ads_page.dart';
import 'utils.dart';

/// Kelola iklan: aktif, selesai, ditolak, diturunkan. Antrean verifikasi
/// tetap di [ManagerAdsPage] (tab "Menunggu" membukanya).
class ManagerAdsManagementPage extends StatefulWidget {
  const ManagerAdsManagementPage({super.key});

  @override
  State<ManagerAdsManagementPage> createState() =>
      _ManagerAdsManagementPageState();
}

class _ManagerAdsManagementPageState extends State<ManagerAdsManagementPage>
    with SingleTickerProviderStateMixin {
  static const _views = <(String, String)>[
    ('active', 'Aktif'),
    ('ended', 'Selesai'),
    ('rejected', 'Ditolak'),
    ('taken_down', 'Diturunkan'),
  ];

  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<dynamic> _ads = [];
  Map<String, dynamic> _counts = {};
  bool _loading = true;
  String? _error;
  int _requestId = 0; // abaikan respons lama kalau filter berubah cepat

  int? _endingWithin; // hanya tab Aktif
  String? _packageType;

  String get _view => _views[_tabs.index].$1;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _views.length, vsync: this)
      ..addListener(() {
        if (!_tabs.indexIsChanging) {
          if (_view != 'active') _endingWithin = null;
          _load();
        }
      });
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _load() async {
    final id = ++_requestId;
    _safeSetState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getManagedAds(
        view: _view,
        query: _searchCtrl.text,
        endingWithin: _endingWithin,
        packageType: _packageType,
      );
      if (id != _requestId) return;
      _safeSetState(() {
        _ads = res.ads;
        _counts = res.counts;
      });
    } catch (e) {
      if (id != _requestId) return;
      _safeSetState(() => _error = e.toString());
    } finally {
      if (id == _requestId) _safeSetState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null),
    );
  }

  Future<void> _run(Future<void> Function() action, String okMsg) async {
    try {
      await action();
      _toast(okMsg);
      await _load();
    } catch (e) {
      _toast(e.toString(), error: true);
    }
  }

  // ---------------- aksi ----------------

  Future<void> _takeDown(Map ad) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turunkan iklan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${ad['title']}" langsung berhenti tayang.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLength: 255,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Alasan (wajib)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.length >= 3) Navigator.pop(ctx, t);
            },
            child: const Text('Turunkan'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (reason == null) return;
    await _run(() => ApiService.takeDownAd(adId: ad['id'], reason: reason),
        'Iklan diturunkan.');
  }

  Future<void> _extend(Map ad) async {
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Perpanjang masa tayang'),
        children: [
          for (final d in const [7, 14, 30, 60])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, d),
              child: Text('+ $d hari'),
            ),
        ],
      ),
    );
    if (days == null) return;
    await _run(() => ApiService.extendAd(adId: ad['id'], days: days),
        'Diperpanjang $days hari.');
  }

  Future<void> _delete(Map ad) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus iklan?'),
        content: Text(
            '"${ad['title']}" dan gambarnya dihapus permanen. Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => ApiService.deleteAd(ad['id']), 'Iklan dihapus.');
  }

  // ---------------- UI ----------------

  String _packageLabel(String? p) => switch (p) {
        '1_month_promo' => '1 Bulan (Promo)',
        '2_month_promo' => '2 Bulan (Promo)',
        '1_month_normal' => '1 Bulan (Normal)',
        '2_month_normal' => '2 Bulan (Normal)',
        _ => p ?? '-',
      };

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari judul, nama, atau email pemasang',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _load();
                        setState(() {});
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_view == 'active')
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Berakhir ≤ 7 hari'),
                      selected: _endingWithin == 7,
                      onSelected: (v) {
                        _endingWithin = v ? 7 : null;
                        _load();
                      },
                    ),
                  ),
                for (final p in const [
                  ('1_month_promo', 'Promo 1 bln'),
                  ('2_month_promo', 'Promo 2 bln'),
                  ('1_month_normal', 'Normal 1 bln'),
                  ('2_month_normal', 'Normal 2 bln'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(p.$2),
                      selected: _packageType == p.$1,
                      onSelected: (v) {
                        _packageType = v ? p.$1 : null;
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(Map ad) {
    final (label, color) = switch (_view) {
      'active' => (
          (ad['days_left'] ?? 0) <= 0
              ? 'Berakhir hari ini'
              : '${ad['days_left']} hari lagi',
          (ad['days_left'] ?? 99) <= 7 ? Colors.orange : Colors.green
        ),
      'ended' => ('Selesai', Colors.blueGrey),
      'rejected' => ('Ditolak', Colors.red),
      _ => ('Diturunkan', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _card(Map ad) {
    final user = (ad['user'] as Map?) ?? const {};
    final isActive = _view == 'active';
    final isEnded = _view == 'ended';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad['title']?.toString() ?? 'Tanpa judul',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '${user['name'] ?? 'Pemasang'} · ${user['email'] ?? ''}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _statusChip(ad),
              ],
            ),
            if (ad['image'] != null) ...[
              const SizedBox(height: 10),
              AppCachedNetworkImage(
                imageUrl: ad['image'].toString(),
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
                fallbackIcon:
                    const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 10),
            Text('Paket: ${_packageLabel(ad['package_type']?.toString())}  ·  '
                '${AppUtils.formatRupiah(ad['total_price'])}'),
            if (ad['start_date'] != null)
              Text('Tayang: ${ad['start_date']} s/d ${ad['end_date']}',
                  style: const TextStyle(color: Colors.black54)),
            if (_view == 'taken_down' && ad['take_down_reason'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Alasan: ${ad['take_down_reason']}',
                    style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (isActive)
                  OutlinedButton.icon(
                    onPressed: () => _takeDown(ad),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Turunkan'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red),
                  ),
                if (isActive || isEnded)
                  OutlinedButton.icon(
                    onPressed: () => _extend(ad),
                    icon: const Icon(Icons.update, size: 18),
                    label: const Text('Perpanjang'),
                  ),
                TextButton.icon(
                  onPressed: () => _delete(ad),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _counts['pending'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Kelola Iklan',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Badge(
            isLabelVisible: pending > 0,
            label: Text('$pending'),
            alignment: Alignment.topRight,
            offset: const Offset(-6, 6),
            child: IconButton(
              tooltip: 'Antrean verifikasi',
              icon: const Icon(Icons.fact_check_outlined),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManagerAdsPage()),
                );
                _load(); // antrean mungkin sudah diproses
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            for (final v in _views)
              Tab(text: '${v.$2} (${_counts[v.$1] ?? 0})'),
          ],
        ),
      ),
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            ElevatedButton(
                                onPressed: _load,
                                child: const Text('Coba lagi')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _ads.isEmpty
                            ? ListView(children: const [
                                SizedBox(height: 120),
                                Icon(Icons.campaign,
                                    size: 72, color: Colors.grey),
                                SizedBox(height: 12),
                                Center(
                                    child: Text('Tidak ada iklan.',
                                        style:
                                            TextStyle(color: Colors.grey))),
                              ])
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _ads.length,
                                itemBuilder: (_, i) => _card(_ads[i] as Map),
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}