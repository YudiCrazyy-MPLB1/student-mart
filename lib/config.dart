class Config {
  /// Bisa diganti saat build tanpa mengubah kode:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
  /// Tanpa flag, dipakai alamat produksi di bawah.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://studentmart-smk4jember.my.id/api/v1',
  );
}