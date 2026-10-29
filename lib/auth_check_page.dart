import 'package:flutter/material.dart';

/// Splash saat sesi login sedang diperiksa. Tidak punya logika navigasi:
/// pemilihan halaman (login / manager / student) hanya dilakukan oleh
/// `RoleCheckPage` di main.dart berdasarkan `AuthProvider`.
class AuthCheckPage extends StatelessWidget {
  const AuthCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_rounded, size: 80),
            SizedBox(height: 20),
            Text(
              'STUDENT MART',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 45,
              height: 45,
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
            SizedBox(height: 15),
            Text('Memeriksa sesi login...'),
          ],
        ),
      ),
    );
  }
}