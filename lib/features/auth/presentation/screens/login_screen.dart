import 'package:universal_io/io.dart' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _isLoading  = false;
  bool _obscure    = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final pass  = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi.');
      return;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _error = 'Format email tidak valid.');
      return;
    }
    if (pass.length > 128) {
      setState(() => _error = 'Password terlalu panjang (maksimal 128 karakter).');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: email, password: pass);
    } on AuthException catch (e) {
      setState(() => _error = _translateAuthError(e.message));
    } catch (_) {
      setState(() => _error = 'Terjadi kesalahan koneksi. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateAuthError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('invalid login credentials') || lower.contains('invalid credentials')) {
      return 'Email atau kata sandi salah. Silakan coba lagi.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email kamu belum dikonfirmasi. Periksa kotak masuk emailmu.';
    }
    if (lower.contains('user not found')) {
      return 'Akun dengan email ini tidak ditemukan.';
    }
    if (lower.contains('rate limit')) {
      return 'Terlalu banyak percobaan masuk. Harap tunggu beberapa saat.';
    }
    return 'Gagal masuk: $msg';
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Masukkan email dulu untuk reset password.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link reset password telah dikirim ke email kamu.')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal mengirim email reset.');
    }
  }

  // ── Social Login via Supabase OAuth (Custom Tab) ─────────────────────────
  // Uses Supabase's built-in OAuth flow which opens a browser/Custom Tab.
  // No native SDK required — works on Android and iOS out of the box.
  // The deep link io.supabase.lumaapp://login-callback/ in AndroidManifest
  // returns the user back to the app after successful authentication.

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.lumaapp://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // The auth state change in main.dart handles navigation automatically.
      // We set _isLoading to false after a short delay since the OAuth flow
      // moves to an external browser/Custom Tab.
      await Future.delayed(const Duration(seconds: 2));
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _translateAuthError(e.message));
    } catch (e) {
      debugPrint('[Auth] OAuth error ($provider): $e');
      if (mounted) {
        setState(() => _error =
          'Gagal masuk dengan ${_providerName(provider)}. '
          'Pastikan provider sudah diaktifkan di Supabase Dashboard.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _providerName(OAuthProvider p) {
    switch (p) {
      case OAuthProvider.google: return 'Google';
      case OAuthProvider.facebook: return 'Facebook';
      case OAuthProvider.apple: return 'Apple';
      default: return p.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showApple = !kIsWeb && Platform.isIOS;
    // Paksakan menggunakan tema terang
    final forcedTheme = AppTheme.light;
    
    final bgColor = forcedTheme.scaffoldBackgroundColor;
    final surfaceColor = forcedTheme.colorScheme.surface;
    final textPrimary = forcedTheme.textTheme.headlineMedium?.color ?? Colors.black;
    final textSecondary = forcedTheme.textTheme.bodyMedium?.color ?? Colors.grey;
    final dividerColor = forcedTheme.dividerColor;

    return Theme(
      data: forcedTheme,
      child: Scaffold(
        backgroundColor: bgColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Illustration bleeding to top
                    Container(
                      height: constraints.maxHeight * 0.25, // Reduced slightly
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: bgColor,
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Center(
                          child: Image.asset(
                            'assets/images/login_illustration.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported_outlined, size: 48, color: dividerColor),
                                const SizedBox(height: 8),
                                Text('assets/images/login_illustration.png', 
                                  style: TextStyle(color: textSecondary, fontSize: 12)
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Form Content
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? constraints.maxWidth * 0.2 : 32.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8), // Reduced from 16
                            // Title
                            Text('Welcome back.', 
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: textPrimary, 
                                fontSize: 32,
                                fontWeight: FontWeight.w800, 
                                letterSpacing: -1.0,
                                height: 1.1,
                              )
                            ),
                            const SizedBox(height: 4),
                            Text('Log in to continue listening.', 
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: textSecondary, 
                                fontSize: 15,
                                fontWeight: FontWeight.w500, 
                                letterSpacing: -0.3,
                              )
                            ),
                            const SizedBox(height: 20), // Reduced from 24

                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F0),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFFD6D6)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE53E3E), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(_error!, style: const TextStyle(
                                    color: Color(0xFFC53030), fontSize: 13, fontWeight: FontWeight.w500,
                                  ))),
                                ]),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email Field
                            TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                              cursorColor: LumaColors.accent,
                              decoration: InputDecoration(
                                hintText: 'Email address',
                                hintStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w400),
                                filled: true, fillColor: surfaceColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Password Field
                            TextField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                              cursorColor: LumaColors.accent,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w400),
                                filled: true, fillColor: surfaceColor,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20, color: textSecondary,
                                  ),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: _forgotPassword,
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4), // Reduced vertical
                                  child: Text('Forgot password?', style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary,
                                  )),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16), // Reduced from 20

                            // Primary CTA
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LumaColors.accent,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  disabledBackgroundColor: LumaColors.accent.withValues(alpha: 0.3),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                                    : const Text('Log in', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                              ),
                            ),
                            const SizedBox(height: 20), // Reduced from 24

                            // ── Social Login Section ───────────────────────────────────────
                            Row(children: [
                              Expanded(child: Container(height: 1, color: dividerColor)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12, fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(child: Container(height: 1, color: dividerColor)),
                            ]),
                            const SizedBox(height: 16), // Reduced from 24

                            // Social buttons row
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialLoginButton(
                                    onPressed: _isLoading ? null : () => _signInWithOAuth(OAuthProvider.google),
                                    icon: const _GoogleIcon(),
                                    label: 'Google',
                                    backgroundColor: surfaceColor,
                                    borderColor: Colors.transparent,
                                    textColor: textPrimary,
                                  ),
                                ),
                                if (showApple) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SocialLoginButton(
                                      onPressed: _isLoading ? null : () => _signInWithOAuth(OAuthProvider.apple),
                                      icon: const Icon(Icons.apple_rounded, color: Colors.white, size: 20),
                                      label: 'Apple',
                                      backgroundColor: Colors.black,
                                      borderColor: Colors.transparent,
                                      textColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 8), // Reduced from 12
                            // Guest
                            _SocialLoginButton(
                              onPressed: _isLoading ? null : () async {
                                try {
                                  setState(() { _isLoading = true; _error = null; });
                                  await Supabase.instance.client.auth.signInAnonymously();
                                } catch (e) {
                                  if (mounted) setState(() => _error = 'Gagal masuk sebagai tamu. Pastikan Anonymous login aktif di Supabase.');
                                } finally {
                                  if (mounted) setState(() => _isLoading = false);
                                }
                              },
                              icon: Icon(Icons.person_outline_rounded, color: textSecondary, size: 20),
                              label: 'Continue as Guest',
                              backgroundColor: Colors.transparent,
                              borderColor: dividerColor,
                              textColor: textSecondary,
                            ),

                            const Spacer(),
                            const SizedBox(height: 8),

                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text("Don't have an account?", style: TextStyle(color: textSecondary, fontSize: 13)),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text('Sign up', style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary
                                  )),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  }
}

// ── Reusable Social Button ─────────────────────────────────────────────────

class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: borderColor == Colors.transparent ? BorderSide.none : BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Google "G" Icon (drawn via CustomPaint, no assets needed) ─────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // White background circle
    canvas.drawCircle(c, r, Paint()..color = Colors.white);

    final rect = Rect.fromCircle(center: c, radius: r * 0.72);
    final sw = size.width * 0.19;

    void arc(double start, double sweep, Color color) {
      canvas.drawArc(rect, start, sweep, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.butt,
      );
    }

    arc(-0.55, 1.25, const Color(0xFFEA4335)); // Red
    arc( 0.70, 0.85, const Color(0xFFFBBC05)); // Yellow
    arc( 1.55, 0.80, const Color(0xFF34A853)); // Green
    arc( 2.35, 1.50, const Color(0xFF4285F4)); // Blue

    // Horizontal bar of "G"
    canvas.drawLine(
      Offset(c.dx, c.dy - size.height * 0.01),
      Offset(c.dx + r * 0.70, c.dy - size.height * 0.01),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = size.height * 0.19
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
