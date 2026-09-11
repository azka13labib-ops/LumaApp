import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading  = false;
  bool _obscure    = true;
  bool _obscureConfirm = true;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email   = _emailCtrl.text.trim().toLowerCase();
    final pass    = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Semua kolom wajib diisi.');
      return;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _error = 'Format email tidak valid.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Password dan konfirmasi tidak cocok.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter.');
      return;
    }
    if (pass.length > 128) {
      setState(() => _error = 'Password terlalu panjang (maksimal 128 karakter).');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await Supabase.instance.client.auth.signUp(email: email, password: pass);
      if (mounted) setState(() { _isLoading = false; _success = true; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
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
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }
    if (lower.contains('password should be at least')) {
      return 'Kata sandi minimal harus 6 karakter.';
    }
    if (lower.contains('invalid email')) {
      return 'Format email tidak valid.';
    }
    return 'Pendaftaran gagal: $msg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      appBar: AppBar(
        backgroundColor: LumaColors.darkBg,
        foregroundColor: LumaColors.darkTextPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Buat Akun', style: TextStyle(
                color: LumaColors.darkTextPrimary, fontSize: 32,
                fontWeight: FontWeight.w700, letterSpacing: -0.8,
              )),
              const SizedBox(height: 6),
              const Text('Simpan playlist dan lagu favoritmu.', style: TextStyle(
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
                    Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              if (_success) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1F0A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1A5C1A)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle_outline_rounded, color: Color(0xFF4CAF50), size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text('Akun berhasil dibuat! Mengarahkan ke halaman masuk...', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              const Text('Email', style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
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

              const Text('Password', style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
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
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: LumaColors.darkTextSecondary),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LumaColors.accent, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Ulangi Password', style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                style: const TextStyle(color: LumaColors.darkTextPrimary, fontSize: 15),
                cursorColor: LumaColors.accent,
                decoration: InputDecoration(
                  hintText: 'Ketik ulang password',
                  hintStyle: const TextStyle(color: LumaColors.darkTextSecondary),
                  filled: true, fillColor: LumaColors.darkSurface,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: LumaColors.darkTextSecondary),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LumaColors.accent, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading || _success ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LumaColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFF003399),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Buat Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                ),
              ),
              const SizedBox(height: 28),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Sudah punya akun?', style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 14)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Masuk', style: TextStyle(
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
