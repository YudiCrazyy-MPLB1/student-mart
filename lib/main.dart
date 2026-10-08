import 'package:flutter/material.dart';

import 'api_service.dart';
import 'auth_check_page.dart';
import 'home_page.dart';
import 'manager_dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hanya membaca token + role dari penyimpanan lokal.
  // Tidak melakukan request ke Laravel.
  await ApiService.loadToken();

  runApp(const StudentMartApp());
}

class StudentMartApp extends StatelessWidget {
  const StudentMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Mart',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const RoleCheckPage(),
    );
  }
}

class RoleCheckPage extends StatelessWidget {
  const RoleCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Tidak ada token.
    if (ApiService.authToken == null ||
        ApiService.authToken!.isEmpty) {
      return const AuthCheckPage();
    }

    // Role manager
    if (ApiService.userRole == 'manager') {
      return const ManagerDashboardPage();
    }

    // Default: student
    return const HomePage();
  }
}