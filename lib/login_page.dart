import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'api_exception.dart';
import 'auth_provider.dart';
import 'register_page.dart';
import 'sapaan_random.dart';

// ═══════════════════════════════════════════════════════════
//  WARNA TEMA BIRU — PERSIS MOCKUP HIESKENO & ZAKIAK
// ═══════════════════════════════════════════════════════════
const Color _kBluePrimary = Color(0xFF5071FE); // biru utama
const Color _kBlueDark = Color(0xFF1556CE);    // biru gelap (kiri panel desktop)
const Color _kBlueMid = Color(0xFF2060E8);     // tombol login

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
            content: Text('Selamat datang, $userName!'),
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
          content: Text(message),
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
  //  BUBBLE / CIRCLE DECORATIONS  — floating white circles
  // ══════════════════════════════════════════════════════════
  Widget _bubbles() {
    return IgnorePointer(
      child: Stack(
        children: [
          // Large faint circles
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
  //  INPUT FIELD — persis gaya mockup (tanpa prefix icon)
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
              horizontal: 14,
              vertical: 14,
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
  //  LOGIN CARD — white card floating on blue background
  // ══════════════════════════════════════════════════════════
  Widget _loginCard({required bool compact}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 22 : 32,
        vertical:   compact ? 26 : 36,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
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

            // ── HEADER: "Login to Your SMart Account" ──
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Login to Your ',
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
            const SizedBox(height: 10),

            // ── REGISTER LINK (← Register Page) ──
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: isLoading ? null : _openRegisterPage,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 13, color: _kBluePrimary),
                      SizedBox(width: 4),
                      Text(
                        'Register Page',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _kBluePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── EMAIL ──
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

            // ── PASSWORD ──
            _inputField(
              label: 'Password',
              hint: PasswordHintRandomAwoawkaoakw.generate(),
              controller: passwordController,
              isPassword: true,
              action: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: _login,
            ),
            const SizedBox(height: 26),

            // ── TOMBOL LOGIN ──
            SizedBox(
              height: 48,
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
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),

            // ── DAFTAR LINK ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: Text(
                    'Belum punya akun?',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12.5,
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
                  child: const Text(
                    'Daftar Sekarang',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
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
  //  COPYRIGHT FOOTER — developer avatars + text
  // ══════════════════════════════════════════════════════════
  Widget _copyrightRow({bool alignRight = false}) {
    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _avatar('assets/images/student1.jpg'),
        const SizedBox(width: 6),
        _avatar('assets/images/student2.png'),
        const SizedBox(width: 10),
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
    );
  }

  Widget _avatar(String assetPath) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(assetPath, fit: BoxFit.cover),
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
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Full blue background
                  Container(color: _kBlueDark),

                  // Right-side artwork fills the right half
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * 0.52,
                    child: Image.asset(
                      'assets/images/brand_left_panel.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),

                  // Floating circles on left side
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * 0.52,
                    child: _bubbles(),
                  ),

                  // Left side: login card centered
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * 0.48,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 28,
                        ),
                        child: _loginCard(compact: false),
                      ),
                    ),
                  ),

                  // Copyright footer — bottom right
                  Positioned(
                    bottom: 20,
                    right: 24,
                    child: _copyrightRow(alignRight: true),
                  ),
                ],
              );
            }

            // ─────────────── MOBILE / TABLET ───────────────
            return Stack(
              fit: StackFit.expand,
              children: [
                // Blue background with bubbles
                Container(color: _kBluePrimary),
                _bubbles(),

                // Scrollable content column
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      // ── HERO BANNER (school image on top) ──
                      SizedBox(
                        height: constraints.maxWidth < 400 ? 200 : 240,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/brand_left_panel.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                            // Gradient fade to blue at the bottom
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

                      // ── FLOATING LOGIN CARD ──
                      Transform.translate(
                        offset: const Offset(0, -28),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth < 400 ? 18 : 24,
                          ),
                          child: Center(child: _loginCard(compact: true)),
                        ),
                      ),

                      // ── COPYRIGHT FOOTER ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        child: Transform.translate(
                          offset: const Offset(0, -20),
                          child: _copyrightRow(),
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
