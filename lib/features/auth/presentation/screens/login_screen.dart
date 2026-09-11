import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),
              // Logo — focal point, accent used only on icon box
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: LumaColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Luma', style: TextStyle(
                  color: LumaColors.darkTextPrimary, fontSize: 26,
                  fontWeight: FontWeight.w700, letterSpacing: -0.6,
                )),
              ]),
              const SizedBox(height: 48),
              const Text('Masuk', style: TextStyle(
                color: LumaColors.darkTextPrimary, fontSize: 32,
                fontWeight: FontWeight.w700, letterSpacing: -0.8,
              )),
              const SizedBox(height: 6),
              const Text('Putar musik favoritmu kapan saja.', style: TextStyle(
                color: LumaColors.darkTextSecondary, fontSize: 15,
              )),
              const SizedBox(height: 36),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1212),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF5C2020)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(
                      color: Color(0xFFFF6B6B), fontSize: 13,
                    ))),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              const Text('Email', style: TextStyle(
                color: LumaColors.darkTextSecondary, fontSize: 13,
                fontWeight: FontWeight.w500,
              )),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                style: const TextStyle(color: LumaColors.darkTextPrimary, fontSize: 15),
                cursorColor: LumaColors.accent,
                decoration: InputDecoration(
                  hintText: 'kamu@email.com',
                  hintStyle: const TextStyle(color: LumaColors.darkTextSecondary),
                  filled: true, fillColor: LumaColors.darkSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LumaColors.accent, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Password', style: TextStyle(
                color: LumaColors.darkTextSecondary, fontSize: 13,
                fontWeight: FontWeight.w500,
              )),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: LumaColors.darkTextPrimary, fontSize: 15),
                cursorColor: LumaColors.accent,
                decoration: InputDecoration(
                  hintText: 'Minimal 6 karakter',
                  hintStyle: const TextStyle(color: LumaColors.darkTextSecondary),
                  filled: true, fillColor: LumaColors.darkSurface,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20, color: LumaColors.darkTextSecondary,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LumaColors.accent, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 8),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _forgotPassword,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Lupa password?', style: TextStyle(
                      color: LumaColors.accent, fontSize: 13, fontWeight: FontWeight.w500,
                    )),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // CTA — accent used only here as the primary action
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LumaColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFF003399),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                ),
              ),
              const SizedBox(height: 28),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Belum punya akun?', style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 14)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Daftar', style: TextStyle(
                    color: LumaColors.accent, fontSize: 14, fontWeight: FontWeight.w600,
                  )),
                ),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
