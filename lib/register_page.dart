import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ===========================================================================
  // LOGIKA & STATE
  // ===========================================================================
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
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
          ),
          backgroundColor: isError
              ? Colors.red.shade700
              : const Color(0xFF1657D9),
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

  // ===========================================================================
  // UI/UX SESUAI MOCKUP FINAL
  // ===========================================================================

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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !isLoading,
          obscureText: isPassword && obscurePassword,
          keyboardType: keyboardType,
          textInputAction: action,
          autofillHints: autofillHints,
          onSubmitted: (_) => onSubmitted?.call(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF94A3B8),
              fontSize: 13.5,
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
                      size: 18,
                      color: const Color(0xFF94A3B8),
                    ),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF1657D9),
                width: 1.2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoodles() {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Transform.scale(
          scale: 1.0,
          child: SvgPicture.asset(
            'assets/images/doodles1.svg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            colorFilter: ColorFilter.mode(
              Colors.white.withValues(alpha: 0.15),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterCard({required bool compact}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 32,
        vertical: compact ? 28 : 36,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER MENGGUNAKAN LOGO SVG (RUANG KOSONG BAWAAN SVG DIPANGKAS)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Create Your ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF172B4D),
                    letterSpacing: -0.3,
                  ),
                ),

                // MENGGUNAKAN ALIGN HEIGHTFACTOR UNTUK MENGAKALI PADDING SVG
                Align(
                  heightFactor: 0.5, // Mengabaikan separuh ruang vertikal kosong dari file SVG
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Transform.translate(
                      offset: const Offset(
                        0,
                        4,
                      ), // Menyelaraskan posisi logo agar sejajar teks
                      child: SvgPicture.asset(
                        'assets/images/smart_logo.svg',
                        height: 130, // Ukuran logo dibesarkan tanpa memanjangkan jarak form ke bawah
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                Text(
                  ' Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF172B4D),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16), // Jarak dirapatkan agar lebih padat

          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: isLoading ? null : _backToLogin,
              borderRadius: BorderRadius.circular(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Color(0xFF1657D9),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Login Page',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1657D9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _inputField(
            label: 'Nama Lengkap',
            controller: nameController,
            isPassword: false,
            action: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 14),

          _inputField(
            label: 'Email',
            controller: emailController,
            isPassword: false,
            keyboardType: TextInputType.emailAddress,
            action: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 14),

          _inputField(
            label: 'Password',
            controller: passwordController,
            isPassword: true,
            action: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 14),

          _inputField(
            label: 'Kode Undangan',
            controller: kodeUndanganController,
            isPassword: false,
            action: TextInputAction.done,
            onSubmitted: _register,
          ),
          const SizedBox(height: 28),

          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF1657D9), Color(0xFF0F3D97)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Register Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/student1.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/student2.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Copyright - Hieskeno & Zakiak',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
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
            // BATAS BREAKPOINT DITURUNKAN KE 800
            // Agar walau layar laptop sedikit disempitkan, layout desktop tetap bertahan
            final bool desktop = constraints.maxWidth >= 800;

            if (desktop) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0xFF5071FE)),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * 0.5,
                    child: _buildDoodles(),
                  ),

                  // Area gambar lebar, memastikan ombak muncul sepenuhnya
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * 1,
                    child: Image.asset(
                      'assets/images/register_left_panel.png',
                      fit: BoxFit.cover, // Cover lebih responsif ditarik-tarik
                      alignment: Alignment.centerLeft,
                      filterQuality: FilterQuality.high,
                    ),
                  ),

                  // Form merapat ke kanan, menggunakan padding persentase agar dinamis
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: constraints.maxWidth * 0.08,
                        left: 16.0,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: _buildRegisterCard(compact: false),
                      ),
                    ),
                  ),
                ],
              );
            }

            // TAMPILAN MOBILE / HP (< 800px)
            return Container(
              color: const Color(
                0xFF5071FE,
              ), // Warna dasar biru dikembalikan untuk menyatu dengan gradien
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildDoodles(), // Doodles di belakang, agar tidak mengganggu interaksi form

                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // --- HEADER FULL-BLEED SECTION ---
                        SizedBox(
                          height:
                              MediaQuery.sizeOf(context).height *
                              0.45, // Diperlebar agar lebih imersif
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. Gambar Full Width membentang penuh
                              Image.asset(
                                'assets/images/school_front.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.high,
                              ),

                              // 2. Gradient Overlay Halus (Transisi dari foto ke warna biru aplikasi)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.3), // Menggelapkan area atas untuk status bar HP
                                      Colors.transparent,
                                      const Color(0xFF5071FE)
                                          .withValues(alpha: 0.8),
                                      const Color(0xFF5071FE),
                                    ],
                                    stops: const [0.0, 0.3, 0.8, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- FORM SECTION ---
                        Transform.translate(
                          // Ditarik ke atas agar menimpa gradien gambar dengan elegan
                          offset: const Offset(0, -40),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth < 400 ? 16 : 24,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white, // Memastikan form memiliki background putih solid
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _buildRegisterCard(compact: true),
                            ),
                          ),
                        ),

                        // --- FOOTER SECTION ---
                        Transform.translate(
                          offset: const Offset(0, -15),
                          child: _buildMobileFooter(),
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
