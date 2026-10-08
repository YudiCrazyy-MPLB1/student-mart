import 'dart:math';

class SapaanRandom {
  static final List<String> greetings = [
    'Selamat datang 👋',
    'Halo! 👋',
    'Selamat datang kembali! 😊',
    'Hai! Senang melihatmu lagi! 😄',
    'Jaga toko dengan baik hari ini! 🛒',
    'Semoga harimu menyenangkan! 🌞',
  ];

  static String generate() {
    final random = Random();
    return greetings[random.nextInt(greetings.length)];
  }
}

class SapaanCustRandom {
  static final List<String> custgreetings = [
    'Selamat datang di StudentMarts! 👋',
    'Halo! Selamat berbelanja! 🛍️',
    'Hai! Senang melihatmu di sini! 😄',
    'Selamat datang! Nikmati belanja kamu! 🎉',
  ];

  static String generate() {
    final random = Random();
    return custgreetings[random.nextInt(custgreetings.length)];
  }
}
