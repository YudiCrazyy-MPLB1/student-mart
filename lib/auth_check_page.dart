import 'dart:async';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'manager_dashboard_page.dart';

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  @override
  void initState() {
    super.initState();

    // Jalankan setelah halaman selesai dibuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLogin();
    });
  }

  Future<void> _checkLogin() async {
    try {
      final token = ApiService.authToken;

      debugPrint('AUTH CHECK: token = $token');

      // Tidak ada token → langsung Login
      if (token == null || token.isEmpty) {
        debugPrint('AUTH CHECK: tidak ada token');
        _openLogin();
        return;
      }

      debugPrint('AUTH CHECK: mengecek token ke /me');

      // Cek token ke Laravel
      await ApiService.getMe().timeout(
        const Duration(seconds: 5),
      );

      debugPrint('AUTH CHECK: token valid');

      if (!mounted) return;

      _routeUser();
    } on TimeoutException {
      debugPrint('AUTH CHECK: timeout');

      await ApiService.clearToken();

      if (!mounted) return;

      _openLogin();
    } catch (e) {
      debugPrint('AUTH CHECK: token tidak valid: $e');

      await ApiService.clearToken();

      if (!mounted) return;

      _openLogin();
    }
  }

  void _openLogin() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  void _routeUser() {
    if (!mounted) return;

    // Cek role dari ApiService
    if (ApiService.userRole == 'manager') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          // Ganti dengan halaman dashboard manager utama Anda
          builder: (_) => const ManagerDashboardPage(), 
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_rounded,
              size: 80,
            ),
            SizedBox(height: 20),
            Text(
              'STUDENT MART',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 45,
              height: 45,
              child: CircularProgressIndicator(
                strokeWidth: 4,
              ),
            ),
            SizedBox(height: 15),
            Text('Memeriksa sesi login...'),
          ],
        ),
      ),
    );
  }
}