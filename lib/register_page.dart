
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'home_page.dart';

const Color brandGreen = Color(0xFF1976D2); // Biru utama
const Color darkGreen = Color(0xFF0D47A1); // Biru gelap
const Color paleGreen = Color(0xFFE3F2FD); // Biru muda
const Color pageBackground = Color(0xFFF7FAFE);
const Color textDark = Color(0xFF20354A);
const Color textMuted = Color(0xFF7B8A9A);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // REGISTER
  Future<void> _register() async {
    if (isLoading) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmation = confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmation.isEmpty) {
      _showMessage(
        'Semua kolom wajib diisi.',
        isError: true,
      );
      return;
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showMessage(
        'Masukkan alamat email yang valid.',
        isError: true,
      );
      return;
    }

    if (password.length < 8) {
      _showMessage(
        'Password minimal 8 karakter.',
        isError: true,
      );
      return;
    }

    if (password != confirmation) {
      _showMessage(
        'Konfirmasi password tidak sama.',
        isError: true,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await ApiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: confirmation,
      );

      if (!mounted) return;

      final user = data['user'];
      final registeredName =
          user is Map ? user['name']?.toString() : null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Akun ${registeredName ?? name} berhasil dibuat.',
          ),
          backgroundColor: brandGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      final message = e
          .toString()
          .replaceFirst('Exception: ', '');

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : brandGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _backToLogin() {
    Navigator.pop(context);
  }

  // INPUT FIELD
  Widget _inputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: !isLoading,
          onSubmitted: (_) => onSubmitted?.call(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: textMuted,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: brandGreen,
              size: 20,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFDDE7E0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFDDE7E0),
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
                color: Color(0xFFE8EEE9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // BRAND PANEL - DESKTOP
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
          colors: [
            Color(0xFF1976D2),
            Color(0xFF0D47A1),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -100,
            top: -90,
            child: _circle(270, Colors.white.withOpacity(0.06)),
          ),
          Positioned(
            left: -100,
            bottom: -120,
            child: _circle(300, Colors.white.withOpacity(0.06)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: brandGreen,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Student Mart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Mulai Perjalananmu\nbersama Student Mart!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Buat akunmu dan nikmati pengalaman '
                'belanja kebutuhan sekolah yang lebih '
                'praktis, mudah, dan nyaman.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 32),
              _benefit(
                Icons.shopping_bag_outlined,
                'Pesan kebutuhan sekolah dengan mudah',
              ),
              const SizedBox(height: 17),
              _benefit(
                Icons.access_time_rounded,
                'Lebih praktis, hemat waktu saat istirahat',
              ),
              const SizedBox(height: 17),
              _benefit(
                Icons.school_outlined,
                'Dirancang untuk lingkungan sekolah',
              ),
              const Spacer(),
              Text(
                'Belanja cerdas, aktivitas lebih praktis.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _benefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // REGISTER FORM
  Widget _registerForm({required bool compact}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
            alignment: Alignment.centerLeft,
             child: IconButton(
             onPressed: isLoading ? null : _backToLogin,
             tooltip: 'Kembali ke Login',
             icon: const Icon(
              Icons.arrow_back_rounded,
              size: 25,
            ),
    style: IconButton.styleFrom(
      foregroundColor: brandGreen,
      backgroundColor: paleGreen,
    ),
  ),
),
const SizedBox(height: 8),
            if (compact) ...[
              Center(
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: paleGreen,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: brandGreen,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              'Buat Akun Baru',
              style: TextStyle(
                fontSize: 29,
                height: 1.25,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Isi data berikut untuk mulai menggunakan '
              'Student Mart.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 28),

            _inputField(
              label: 'Nama Lengkap',
              hint: 'Masukkan nama lengkap',
              icon: Icons.person_outline_rounded,
              controller: nameController,
            ),
            const SizedBox(height: 18),

            _inputField(
              label: 'Email',
              hint: 'nama@email.com',
              icon: Icons.mail_outline_rounded,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),

            _inputField(
              label: 'Password',
              hint: 'Minimal 8 karakter',
              icon: Icons.lock_outline_rounded,
              controller: passwordController,
              obscureText: obscurePassword,
              suffixIcon: IconButton(
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
                  color: textMuted,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 18),

            _inputField(
              label: 'Konfirmasi Password',
              hint: 'Masukkan ulang password',
              icon: Icons.verified_user_outlined,
              controller: confirmPasswordController,
              obscureText: obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: _register,
              suffixIcon: IconButton(
                tooltip: obscureConfirmPassword
                    ? 'Tampilkan password'
                    : 'Sembunyikan password',
                onPressed: isLoading
                    ? null
                    : () {
                        setState(() {
                          obscureConfirmPassword =
                              !obscureConfirmPassword;
                        });
                      },
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: textMuted,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: brandGreen,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Gunakan password yang aman dan jangan '
                    'bagikan kepada orang lain.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      brandGreen.withOpacity(0.6),
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
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Buat Akun',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 9),
                          Icon(Icons.arrow_forward_rounded, size: 19),
                        ],
                      ),
              ),
            ),
          ],
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
            final isDesktop = constraints.maxWidth >= 900;

            if (isDesktop) {
              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: double.infinity,
                      child: _brandPanel(),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: pageBackground,
                      height: double.infinity,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 44,
                          vertical: 35,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 70,
                          ),
                          child: _registerForm(compact: false),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth < 400 ? 22 : 32,
                vertical: 28,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: isLoading ? null : _backToLogin,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 19,
                      ),
                      label: const Text('Kembali ke Login'),
                      style: TextButton.styleFrom(
                        foregroundColor: brandGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _registerForm(compact: true),
                  const SizedBox(height: 20),
                  Text(
                    'Student Mart • Belanja lebih praktis',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}