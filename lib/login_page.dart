import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api_exception.dart';
import 'auth_provider.dart';
import 'register_page.dart';
import 'sapaan_random.dart';

// ═══════════════════════════════════════════════════════════
//  WARNA TEMA BIRU
// ═══════════════════════════════════════════════════════════
const Color _kBluePrimary = Color(0xFF5071FE); 
const Color _kBlueDark = Color(0xFF1556CE);    
const Color _kBlueMid = Color(0xFF2060E8);     

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading       = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ─────────────── LOGIN LOGIC ───────────────
  Future<void> _login() async {
    if (isLoading) return;

    final email    = emailController.text.trim();
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

    final messenger = ScaffoldMessenger.of(context);
    final auth      = context.read<AuthProvider>();

    try {
      final data = await auth.login(email: email, password: password);
      TextInput.finishAutofillContext(shouldSave: true);

      final dynamic userData = data['user'];
      final userName =
          userData is Map ? userData['name']?.toString() ?? 'Pengguna' : 'Pengguna';

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Selamat datang, $userName!',
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _kBlueDark,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        e is ApiException ? e.message : 'Terjadi kesalahan. Coba lagi.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
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
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : _kBlueDark,
        ),
      );
  }

  void _openRegisterPage() {
    if (isLoading) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
  }

  // ══════════════════════════════════════════════════════════
  //  BUBBLE / CIRCLE DECORATIONS
  // ══════════════════════════════════════════════════════════
  Widget _bubbles() {
    return IgnorePointer(
      child: Stack(
        children: [
          _circle(size: 160, left: -55,  top: -55,  opacity: 0.12),
          _circle(size: 110, left: 60,   top: -20,  opacity: 0.10),
          _circle(size: 80,  left: -30,  top: 200,  opacity: 0.08),
          _circle(size: 200, right: -80, bottom: -80, opacity: 0.10),
          _circle(size: 60,  right: 10,  top: 60,   opacity: 0.14),
          _circle(size: 50,  right: 90,  top: 10,   opacity: 0.12),
          _circle(size: 70,  left: 20,   bottom: 80, opacity: 0.10),
          _circle(size: 40,  left: 110,  top: 80,   opacity: 0.14),
          _circle(size: 55,  right: 60,  bottom: 40, opacity: 0.10),
          _circle(size: 35,  left: 200,  bottom: 10, opacity: 0.12),
          _circle(size: 25,  right: 30,  bottom: 150, opacity: 0.14),
          _circle(size: 20,  left: 30,   top: 300,  opacity: 0.10),
        ],
      ),
    );
  }

  Widget _circle({
    required double size,
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  INPUT FIELD
  // ══════════════════════════════════════════════════════════
  Widget _inputField({
    required String label,
    required String hint,
    required TextEditingController controller,
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5, 
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF94A3B8), 
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    tooltip: obscurePassword
                        ? 'Tampilkan password'
                        : 'Sembunyikan password',
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() => obscurePassword = !obscurePassword);
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
              horizontal: 16,
              vertical: 16,
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
              borderSide: const BorderSide(color: _kBluePrimary, width: 1.6),
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

  // ══════════════════════════════════════════════════════════
  //  LOGIN CARD
  // ══════════════════════════════════════════════════════════
  Widget _loginCard({required bool compact}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 36,
        vertical:   compact ? 28 : 40,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Login to Your ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(
                    height: 34,
                    child: ClipRect(
                      child: Align(
                        alignment: const Alignment(0, -0.04),
                        heightFactor: 0.32,
                        child: Image.asset(
                          'assets/images/smart_logo.png',
                          height: 150,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              'SMART',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: _kBluePrimary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Text(
                    ' Account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: isLoading ? null : _openRegisterPage,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, size: 14, color: _kBluePrimary),
                      const SizedBox(width: 6),
                      Text(
                        'Register Page',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kBluePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _inputField(
              label: 'Email',
              hint: 'nama@example.com',
              controller: emailController,
              isPassword: false,
              keyboardType: TextInputType.emailAddress,
              action: TextInputAction.next,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
            ),
            const SizedBox(height: 16),

            _inputField(
              label: 'Password',
              hint: PasswordHintRandomAwoawkaoakw.generate(),
              controller: passwordController,
              isPassword: true,
              action: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: _login,
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlueMid,
                  disabledBackgroundColor: _kBlueMid.withValues(alpha: 0.55),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Login',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Belum punya akun?',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isLoading ? null : _openRegisterPage,
                  style: TextButton.styleFrom(
                    foregroundColor: _kBluePrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Daftar Sekarang',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, 
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  COPYRIGHT FOOTER — developer avatars + text (Stacked)
  // ══════════════════════════════════════════════════════════
  Widget _copyrightRow({bool alignRight = false}) {
    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tumpukan Avatar
        SizedBox(
          width: 56, // Lebar yang cukup untuk dua avatar yang bertumpuk
          height: 32,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: _avatar('assets/images/student1.jpg'),
              ),
              Positioned(
                left: 24, // Efek menumpuk pada avatar kedua
                child: _avatar('assets/images/student2.png'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Copyright - Hieskeno & Zakiak',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _avatar(String assetPath) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath, 
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.person, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBluePrimary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth >= 900;

            // ─────────────── DESKTOP ───────────────
            if (isDesktop) {
              return Row(
                children: [
                  Expanded(
                    flex: 48,
                    child: Container(
                      color: _kBluePrimary,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _bubbles(),
                          Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 32,
                              ),
                              child: _loginCard(compact: false),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 52,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: _kBlueDark),
                        Image.asset(
                          'assets/images/brand_left_panel.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                        Positioned(
                          bottom: 24,
                          right: 32,
                          child: _copyrightRow(alignRight: true),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // ─────────────── MOBILE / TABLET ───────────────
            return Stack(
              fit: StackFit.expand,
              children: [
                // Latar Belakang Biru dengan Gelembung
                Container(color: _kBluePrimary),
                _bubbles(),

                // ScrollView 
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: [
                      // ── HERO BANNER (Gambar Atas) ──
                      SizedBox(
                        height: constraints.maxWidth < 400 ? 220 : 260,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/brand_left_panel.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (context, error, stackTrace) => const SizedBox(),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    _kBluePrimary.withValues(alpha: 0.55),
                                    _kBluePrimary,
                                  ],
                                  stops: const [0.4, 0.78, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── KARTU LOGIN PUTIH (Tengah) ──
                      Transform.translate(
                        offset: const Offset(0, -40), 
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth < 400 ? 20 : 28,
                          ),
                          child: Center(child: _loginCard(compact: true)),
                        ),
                      ),

                      // ── FOTO & COPYRIGHT OWNER (Langsung di bawah kotak putih) ──
                      Transform.translate(
                        offset: const Offset(0, -16), // Memberi sedikit jarak tepat di bawah form login
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: _copyrightRow(alignRight: false), 
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}