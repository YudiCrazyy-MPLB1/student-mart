import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading yang dipakai bersama. Hanya untuk tempat yang memuat
/// daftar / konten utama halaman; spinner kecil di tombol tetap spinner.
///
/// Warna dan efek shimmer sama dengan [SkeletonProductCard].

class SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: child,
    );
  }
}

/// Kotak abu-abu penanda satu elemen (teks, gambar, tombol).
class SkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBlock({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Daftar kartu (pesanan, produk, riwayat stok, dll.).
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _SkeletonListCard(),
      ),
    );
  }
}

class _SkeletonListCard extends StatelessWidget {
  const _SkeletonListCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          SkeletonBlock(width: 56, height: 56, radius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(height: 14),
                SizedBox(height: 8),
                SkeletonBlock(width: 120, height: 12),
                SizedBox(height: 8),
                SkeletonBlock(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Halaman detail produk: gambar besar, judul, harga, deskripsi, tombol.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: double.infinity, height: 260, radius: 16),
            SizedBox(height: 20),
            SkeletonBlock(width: 220, height: 22),
            SizedBox(height: 12),
            SkeletonBlock(width: 110, height: 20),
            SizedBox(height: 24),
            SkeletonBlock(height: 12),
            SizedBox(height: 8),
            SkeletonBlock(height: 12),
            SizedBox(height: 8),
            SkeletonBlock(width: 180, height: 12),
            SizedBox(height: 28),
            SkeletonBlock(width: double.infinity, height: 48, radius: 12),
          ],
        ),
      ),
    );
  }
}

/// Banner / carousel iklan di beranda.
class SkeletonBanner extends StatelessWidget {
  final double height;

  const SkeletonBanner({super.key, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SkeletonBlock(
        width: double.infinity,
        height: height,
        radius: 16,
      ),
    );
  }
}

/// Deretan kategori horizontal di beranda.
class SkeletonCategories extends StatelessWidget {
  const SkeletonCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const Column(
          children: [
            SkeletonBlock(width: 64, height: 64, radius: 18),
            SizedBox(height: 8),
            SkeletonBlock(width: 48, height: 10),
          ],
        ),
      ),
    );
  }
}