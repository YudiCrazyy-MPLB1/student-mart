import 'package:flutter/material.dart';

import 'api_service.dart';
import 'manager_dashboard_page.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // =====================================================
  // LOGIN
  // =====================================================

  Future<void> _login() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    // Validasi email
    if (email.isEmpty) {
      _showMessage(
        'Email wajib diisi.',
        isError: true,
      );
      return;
    }

    // Validasi password
    if (password.isEmpty) {
      _showMessage(
        'Password wajib diisi.',
        isError: true,
      );
      return;
    }

    // Hilangkan keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      // =================================================
      // REQUEST LOGIN
      // =================================================

      final data = await ApiService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // =================================================
      // AMBIL DATA USER
      // =================================================

      final dynamic userData = data['user'];

      String userName = 'Pengguna';
      String role = 'student';

      if (userData is Map<String, dynamic>) {
        userName =
            userData['name']?.toString() ?? 'Pengguna';

        role =
            userData['role']?.toString().toLowerCase() ??
                'student';
      }

      // =================================================
      // LOGIN BERHASIL
      // =================================================

      _showMessage(
        'Selamat datang, $userName!',
      );

      // Beri sedikit waktu agar SnackBar muncul
      await Future<void>.delayed(
        const Duration(milliseconds: 150),
      );

      if (!mounted) return;

      // =================================================
      // CEK ROLE
      // =================================================

      if (role == 'manager') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ManagerDashboardPage(),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      String message = e.toString();

      if (message.startsWith('Exception: ')) {
        message =
            message.substring('Exception: '.length);
      }

      _showMessage(
        message,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? Colors.red : null,
        ),
      );
  }

  // =====================================================
  // REGISTER PAGE
  // =====================================================

  void _openRegisterPage() {
    if (isLoading) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              // =================================================
              // ICON
              // =================================================

              const Center(
                child: Icon(
                  Icons.account_circle_rounded,
                  size: 90,
                ),
              ),

              const SizedBox(height: 24),

              // =================================================
              // TITLE
              // =================================================

              const Center(
                child: Text(
                  'Selamat Datang',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'Login untuk mulai berbelanja',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // =================================================
              // EMAIL
              // =================================================

              const Text(
                'Email',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: emailController,
                enabled: !isLoading,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                decoration:
                    const InputDecoration(
                  hintText: 'Masukkan email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // PASSWORD
              // =================================================

              const Text(
                'Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: passwordController,
                enabled: !isLoading,
                obscureText: obscurePassword,
                textInputAction:
                    TextInputAction.done,
                autofillHints: const [
                  AutofillHints.password,
                ],
                onSubmitted: (_) {
                  if (!isLoading) {
                    _login();
                  }
                },
                decoration:
                    InputDecoration(
                  hintText:
                      'Masukkan password',
                  prefixIcon:
                      const Icon(
                    Icons.lock_outline,
                  ),
                  border:
                      const OutlineInputBorder(),
                  suffixIcon:
                      IconButton(
                    tooltip:
                        obscurePassword
                            ? 'Tampilkan password'
                            : 'Sembunyikan password',
                    icon: Icon(
                      obscurePassword
                          ? Icons
                              .visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              obscurePassword =
                                  !obscurePassword;
                            });
                          },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // LOGIN BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : _login,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // REGISTER
              // =================================================

              Center(
                child: TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : _openRegisterPage,
                  child: const Text(
                    'Belum punya akun? Daftar',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}