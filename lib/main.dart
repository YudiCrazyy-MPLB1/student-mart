import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'app_navigator.dart';
import 'auth_check_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'manager_dashboard_page.dart';
import 'cart_controller.dart';
import 'product_provider.dart';
import 'auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hanya membaca token + role dari penyimpanan lokal.
  // Tidak melakukan request ke Laravel.
  await ApiService.loadToken();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProductProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()..checkLoginStatus()),
        ChangeNotifierProvider(create: (context) => CartController()),
      ],
      child: const StudentMartApp(),
    )
  );
}

class StudentMartApp extends StatelessWidget {
  const StudentMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Student Mart',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: const RoleCheckPage(),
    );
  }
}

class RoleCheckPage extends StatelessWidget {
  const RoleCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Sesi sedang diperiksa (startup).
    if (auth.isChecking) {
      return const AuthCheckPage();
    }

    // Tidak ada sesi.
    if (!auth.isAuthenticated) {
      return const LoginPage();
    }

    // Routing berdasarkan role.
    switch (auth.role) {
      case 'manager':
        return const ManagerDashboardPage();
      default:
        // Default: student / role tidak dikenal → halaman utama.
        return const HomePage();
    }
  }
}