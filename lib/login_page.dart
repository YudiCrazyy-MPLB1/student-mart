
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'manager_dashboard_page.dart';
import 'home_page.dart';
import 'register_page.dart';

const Color brandGreen = Color.fromARGB(255, 27, 177, 164);
const Color darkGreen = Color.fromARGB(255, 16, 80, 91);
const Color pageBackground = Color(0xFFF6F8F6);

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

  // LOGIN - tetap menggunakan backend Laravel
  Future<void> _login() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      _showMessage('Email wajib diisi.', isError: true);
      return;
    }

    if (password.isEmpty) {
      _showMessage('Password wajib diisi.', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => isLoading = true);

    try {
      final data = await ApiService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      TextInput.finishAutofillContext(shouldSave: true);

      final dynamic userData = data['user'];

      String userName = 'Pengguna';
      String role = 'student';

      if (userData is Map) {
        userName = userData['name']?.toString() ?? 'Pengguna';
        role = userData['role']?.toString().toLowerCase() ??
            'student';
      }

      _showMessage('Selamat datang, $userName!');

      await Future<void>.delayed(
        const Duration(milliseconds: 150),
      );

      if (!mounted) return;

      if (role == 'manager') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const ManagerDashboardPage(),
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
        message = message.substring('Exception: '.length);
      }

      _showMessage(message, isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

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
          backgroundColor: isError ? Colors.red.shade700 : brandGreen,
        ),
      );
  }

  void _openRegisterPage() {
    if (isLoading) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ),
    );
  }

  // LOGO STUDENT MART
  Widget _brandLogo({bool large = false}) {
    final double iconSize = large ? 54 : 36;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(large ? 16 : 11),
          ),
          child: Icon(
            Icons.shopping_bag_rounded,
            size: iconSize * 0.58,
            color: brandGreen,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Mart',
              style: TextStyle(
                fontSize: large ? 25 : 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: large ? Colors.white : darkGreen,
              ),
            ),
            if (large)
              const Text(
                'Digital School Marketplace',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // PANEL BRANDING UNTUK DESKTOP
  Widget _brandPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 48,
        vertical: 42,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandGreen, darkGreen],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -80,
            child: _decorationCircle(260),
          ),
          Positioned(
            bottom: -100,
            left: -90,
            child: _decorationCircle(300),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _brandLogo(large: true),
              const Spacer(),
              Container(
                width: 76,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD166),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Belanja mudah,\nsekolah lebih nyaman.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pesan kebutuhanmu dengan praktis '
                'melalui Student Mart.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 34),
              _featureRow(
                Icons.shopping_basket_outlined,
                'Kebutuhan sekolah dalam satu tempat',
              ),
              const SizedBox(height: 17),
              _featureRow(
                Icons.schedule_rounded,
                'Pemesanan lebih praktis',
              ),
              const SizedBox(height: 17),
              _featureRow(
                Icons.verified_user_outlined,
                'Akses akun yang aman',
              ),
              const Spacer(),
              const Text(
                'STUDENT MART • SMK NEGERI 4 JEMBER',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decorationCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 35,
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFD166), size: 23),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // FIELD EMAIL DAN PASSWORD
  Widget _inputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isPassword,
    required TextInputAction action,
    TextInputType keyboardType = TextInputType.text,
    Iterable<String>? autofillHints,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF27352E),
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          enabled: !isLoading,
          obscureText: isPassword && obscurePassword,
          keyboardType: keyboardType,
          textInputAction: action,
          autofillHints: autofillHints,
          onSubmitted: (_) => onSubmitted?.call(),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF26352D),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9AA69F),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: const Color(0xFF829188),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    tooltip: obscurePassword
                        ? 'Tampilkan password'
                        : 'Sembunyikan password',
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: const Color(0xFF829188),
                    ),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFFAFCFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFE1E8E2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFE1E8E2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: brandGreen,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFE1E8E2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // FORM LOGIN
  Widget _loginForm({required bool compact}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (compact) ...[
                Center(child: _brandLogo()),
                const SizedBox(height: 42),
              ],
              const Text(
                'Selamat Datang di\nStudent Mart',
                style: TextStyle(
                  fontSize: 31,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  color: Color(0xFF1E3026),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Masuk untuk melanjutkan belanja '
                'kebutuhan sekolahmu.',
                style: TextStyle(
                  color: Color(0xFF78857C),
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 32),

              _inputField(
                label: 'Email',
                hint: 'emailanda@example.com',
                controller: emailController,
                icon: Icons.email_outlined,
                isPassword: false,
                keyboardType: TextInputType.emailAddress,
                action: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
              ),
              const SizedBox(height: 22),

              _inputField(
                label: 'Password',
                hint: 'Passwordexample123',
                controller: passwordController,
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                action: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: _login,
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 28, 159, 177),
                    disabledBackgroundColor:
                        brandGreen.withOpacity(0.6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 23),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text(
                      'Belum punya akun?',
                      style: TextStyle(
                        color: Color(0xFF78857C),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        isLoading ? null : _openRegisterPage,
                    style: TextButton.styleFrom(
                      foregroundColor: brandGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                      ),
                    ),
                    child: const Text(
                      'Daftar',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'STUDENT MART • BELANJA JADI PRAKTIS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9AA69F),
                    fontSize: 9,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool desktop = constraints.maxWidth >= 900;

            if (desktop) {
              return Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: _brandPanel(),
                  ),
                  Expanded(
                    flex: 10,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 35,
                      ),
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 70,
                          ),
                          child: _loginForm(compact: false),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 400 ? 24 : 36,
                  vertical: 35,
                ),
                child: _loginForm(compact: true),
              ),
            );
          },
        ),
      ),
    );
  }
}