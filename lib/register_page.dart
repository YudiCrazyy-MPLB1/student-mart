import 'package:flutter/material.dart';

import 'api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController kodeUndanganController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    kodeUndanganController.dispose();
    super.dispose();
  }

  // PROSES REGISTRASI
  Future<void> _register() async {
    if (isLoading) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final kodeUndangan = kodeUndanganController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        kodeUndangan.isEmpty) {
      _showMessage('Semua kolom wajib diisi.', isError: true);
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      _showMessage('Masukkan alamat email yang valid.', isError: true);
      return;
    }

    if (password.length < 8) {
      _showMessage('Password minimal 8 karakter.', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    try {
      await ApiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: password,
        kodeUndangan: kodeUndangan,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pendaftaran berhasil! Silakan cek inbox/spam email kamu untuk verifikasi sebelum login.',
          ),
          backgroundColor: Color(0xFF1657D9),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );

      _backToLogin();
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');
      _showMessage(message, isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red.shade700 : const Color(0xFF1657D9),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _backToLogin() {
    if (isLoading) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // INPUT FIELD KUSTOM SESUAI DESAIN MOCKUP
  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required bool isPassword,
    required TextInputAction action,
    String? hint,
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
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          enabled: !isLoading,
          obscureText: isPassword && obscurePassword,
          keyboardType: keyboardType,
          textInputAction: action,
          autofillHints: autofillHints,
          onSubmitted: (_) => onSubmitted?.call(),
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
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
                      size: 19,
                      color: const Color(0xFF94A3B8),
                    ),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF1657D9), width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  // FLOATING DOODLES / E-COMMERCE ICONS PADA BACKGROUND BIRU
  Widget _buildDoodles() {
    return IgnorePointer(
      child: Stack(
        children: [
          // Top row doodles
          Positioned(
            top: 26,
            right: 175,
            child: Icon(
              Icons.star_outline_rounded,
              color: Colors.white.withValues(alpha: 0.85),
              size: 36,
            ),
          ),
          Positioned(
            top: 36,
            right: 100,
            child: Icon(
              Icons.local_offer_outlined,
              color: Colors.white.withValues(alpha: 0.85),
              size: 32,
            ),
          ),
          Positioned(
            top: 24,
            right: 28,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 4,
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 16,
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white.withValues(alpha: 0.85),
              size: 30,
            ),
          ),
          // Left of card
          Positioned(
            top: 130,
            left: 20,
            child: Icon(
              Icons.local_shipping_outlined,
              color: Colors.white.withValues(alpha: 0.85),
              size: 36,
            ),
          ),
          Positioned(
            top: 230,
            left: 36,
            child: Icon(
              Icons.change_history_rounded,
              color: Colors.white.withValues(alpha: 0.85),
              size: 32,
            ),
          ),
          // Right of card
          Positioned(
            top: 240,
            right: 18,
            child: Icon(
              Icons.groups_outlined,
              color: Colors.white.withValues(alpha: 0.85),
              size: 30,
            ),
          ),
          Positioned(
            bottom: 155,
            right: 20,
            child: Icon(
              Icons.star_rounded,
              color: Colors.white.withValues(alpha: 0.85),
              size: 32,
            ),
          ),
          // Bottom area
          Positioned(
            bottom: 120,
            left: 24,
            child: Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white.withValues(alpha: 0.85),
              size: 32,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 80,
            child: Icon(
              Icons.local_offer_outlined,
              color: Colors.white.withValues(alpha: 0.85),
              size: 32,
            ),
          ),
          Positioned(
            bottom: 30,
            left: 170,
            child: Icon(
              Icons.change_history_rounded,
              color: Colors.white.withValues(alpha: 0.85),
              size: 28,
            ),
          ),
          Positioned(
            bottom: 24,
            right: 70,
            child: Icon(
              Icons.local_shipping_outlined,
              color: Colors.white.withValues(alpha: 0.85),
              size: 34,
            ),
          ),
          Positioned(
            bottom: 20,
            right: 14,
            child: Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white.withValues(alpha: 0.85),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // KARTU REGISTER (PERSIS DENGAN MOCKUP)
  Widget _buildRegisterCard({required bool compact}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 395),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 22 : 30,
        vertical: compact ? 24 : 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER: Create Your [SMArt] Account
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Create Your ',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                Image.asset(
                  'assets/images/smart_logo.png',
                  height: 34,
                  fit: BoxFit.contain,
                ),
                const Text(
                  ' Account',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // NAVIGASI KEMBALI KE LOGIN: ← Login Page
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: isLoading ? null : _backToLogin,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 14,
                      color: Color(0xFF1657D9),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Login Page',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1657D9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // FIELD NAMA LENGKAP
          _inputField(
            label: 'Nama Lengkap',
            controller: nameController,
            isPassword: false,
            action: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 14),

          // FIELD EMAIL
          _inputField(
            label: 'Email',
            controller: emailController,
            isPassword: false,
            keyboardType: TextInputType.emailAddress,
            action: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 14),

          // FIELD PASSWORD
          _inputField(
            label: 'Password',
            controller: passwordController,
            isPassword: true,
            action: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 14),

          // FIELD KODE UNDANGAN
          _inputField(
            label: 'Kode Undangan',
            controller: kodeUndanganController,
            isPassword: false,
            action: TextInputAction.done,
            onSubmitted: _register,
          ),
          const SizedBox(height: 24),

          // TOMBOL DAFTAR AKUN
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1657D9),
                disabledBackgroundColor:
                    const Color(0xFF1657D9).withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Register Account',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // LINK LOGIN DI BAWAH TOMBOL
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sudah punya akun?',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                ),
              ),
              TextButton(
                onPressed: isLoading ? null : _backToLogin,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1657D9),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Login di sini',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5071FE),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool desktop = constraints.maxWidth >= 900;

            if (desktop) {
              return Row(
                children: [
                  // SISI KIRI: ARTWORK RESMI HIESKENO & ZAKIAK (SMKN 4 JEMBER)
                  Expanded(
                    flex: 11,
                    child: Container(
                      color: const Color(0xFF1556CE),
                      child: Image.asset(
                        'assets/images/brand_left_panel.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),

                  // SISI KANAN: BACKGROUND BIRU, DOODLE IKON, DAN KARTU REGISTER
                  Expanded(
                    flex: 10,
                    child: Container(
                      color: const Color(0xFF5071FE),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildDoodles(),
                          Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 24,
                              ),
                              child: _buildRegisterCard(compact: false),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // TAMPILAN MOBILE / HP (< 900px)
            return Container(
              color: const Color(0xFF5071FE),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background doodles
                  _buildDoodles(),

                  // Scrollable body agar aman di semua ukuran layar & saat keyboard terbuka
                  SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        // HERO BANNER SMKN 4 JEMBER UNTUK HP
                        SizedBox(
                          height: constraints.maxWidth < 400 ? 190 : 220,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/brand_left_panel.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.topLeft,
                                filterQuality: FilterQuality.high,
                              ),
                              // Gradient fade lembut ke bawah agar menyatu dengan background biru
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFF5071FE)
                                          .withValues(alpha: 0.6),
                                      const Color(0xFF5071FE),
                                    ],
                                    stops: const [0.35, 0.8, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // KARTU REGISTER (MELAYANG DAN TUMPANG TINDIH ELEGAN KE HERO BANNER)
                        Transform.translate(
                          offset: const Offset(0, -22),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth < 400 ? 16 : 22,
                            ),
                            child: _buildRegisterCard(compact: true),
                          ),
                        ),

                        // FOOTER COPYRIGHT & AVATAR PENGEMBANG UNTUK HP
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/student1.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/student2.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),
                              const Text(
                                'Copyright - Hieskeno & Zakiak',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
