
class AppUtils {
  /// Mengubah berbagai tipe data angka menjadi int yang aman
  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Memformat angka menjadi Rupiah (opsi spasi bisa diatur)
  static String formatRupiah(dynamic value, {bool withSpace = false}) {
    final price = toInt(value);
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return withSpace ? 'Rp $formatted' : 'Rp$formatted';
  }

  static List<dynamic> insertNativeAds<T>(List<T> items, List<dynamic> ads, {int insertEvery = 4}) {
    if (ads.isEmpty) return items; // Jika tidak ada iklan, kembalikan daftar asli
    if (items.isEmpty) return [];

    List<dynamic> mixedList = [];
    int adIndex = 0;

    for (int i = 0; i < items.length; i++) {
      mixedList.add(items[i]);

      // Sisipkan iklan setiap X item (default: 4)
      if ((i + 1) % insertEvery == 0) {
        mixedList.add({
          'is_ad': true,
          'ad_data': ads[adIndex % ads.length]
        });
        adIndex++;
      }
    }

    // Jika produk sangat sedikit (< insertEvery), paksa 1 iklan muncul di akhir
    if (items.length < insertEvery) {
      mixedList.add({
        'is_ad': true,
        'ad_data': ads[0]
      });
    }

    return mixedList;
  }
}