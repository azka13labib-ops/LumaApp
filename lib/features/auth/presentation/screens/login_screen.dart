import 'package:universal_io/io.dart' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/luma_emblem.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passFocusNode = FocusNode();
  
  bool _isLoading  = false;
  bool _obscure    = true;
  String? _error;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    
    final email = _emailCtrl.text.trim().toLowerCase();
    final pass  = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi.');
      HapticFeedback.heavyImpact();
      return;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _error = 'Format email tidak valid.');
      HapticFeedback.heavyImpact();
      return;
    }
    if (pass.length > 128) {
      setState(() => _error = 'Password terlalu panjang (maksimal 128 karakter).');
      HapticFeedback.heavyImpact();
      return;
    }
    
    setState(() { _isLoading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: email, password: pass);
    } on AuthException catch (e) {
      setState(() => _error = _translateAuthError(e.message));
      HapticFeedback.heavyImpact();
    } catch (_) {
      setState(() => _error = 'Terjadi kesalahan koneksi. Coba lagi.');
      HapticFeedback.heavyImpact();
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
    HapticFeedback.lightImpact();
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

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    HapticFeedback.lightImpact();
    setState(() { _isLoading = true; _error = null; });
    try {
      if (kIsWeb) {
        final origin = Uri.base.origin;
        final res = await Supabase.instance.client.auth.getOAuthSignInUrl(
          provider: provider,
          redirectTo: '$origin/',
        );
        await launchUrl(
          Uri.parse(res.url),
          webOnlyWindowName: '_blank',
        );
      } else {
        await Supabase.instance.client.auth.signInWithOAuth(
          provider,
          redirectTo: 'io.supabase.lumaapp://login-callback/',
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      }
      await Future.delayed(const Duration(seconds: 2));
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _translateAuthError(e.message));
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('[Auth] OAuth error ($provider): $e');
      if (mounted) {
        setState(() => _error =
          'Gagal masuk dengan ${_providerName(provider)}. '
          'Pastikan provider sudah diaktifkan di Supabase Dashboard.');
        HapticFeedback.heavyImpact();
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

  Widget _buildStaggeredItem({required int index, required Widget child}) {
    // Menghitung interval animasi untuk setiap index
    // Mengurangi interval agar index yang besar tidak melebihi 1.0
    final start = (index * 0.04).clamp(0.0, 0.9);
    final end = (start + 0.3).clamp(0.0, 1.0);
    
    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(start.toDouble(), end.toDouble(), curve: Curves.easeOutCubic),
      ),
    );
    
    final slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(start.toDouble(), end.toDouble(), curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showApple = !kIsWeb && Platform.isIOS;
    final forcedTheme = AppTheme.light;
    
    const bgColor = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF111111);
    const textSecondary = Color(0xFF6B7280);
    const dividerColor = Color(0xFFE5E7EB);
    const primaryObsidian = Color(0xFF09090B);
    const primaryCharcoal = Color(0xFF27272A);
    
    final items = <Widget>[
      // Error Message
      if (_error != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA), width: 1),
          ),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(_error!, style: const TextStyle(
              color: Color(0xFF991B1B), fontSize: 14, fontWeight: FontWeight.w500,
            ))),
          ]),
        ),
      ],

      // Email Label & Field
      const Text('Email / Username', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _PillTextField(
        controller: _emailCtrl,
        focusNode: _emailFocusNode,
        hintText: 'name@example.com',
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
      ),
      const SizedBox(height: 24),

      // Password Label & Field
      const Text('Password', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _PillTextField(
        controller: _passCtrl,
        focusNode: _passFocusNode,
        hintText: '••••••••',
        obscureText: _obscure,
        onToggleObscure: () {
          HapticFeedback.selectionClick();
          setState(() => _obscure = !_obscure);
        },
      ),
      const SizedBox(height: 32),

      // Sign In Button
      _AnimatedGradientButton(
        onPressed: _isLoading ? null : _login,
        colors: const [primaryCharcoal, primaryObsidian],
        textColor: Colors.white,
        child: _isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
      ),
      const SizedBox(height: 16),

      // Forgot password
      Center(
        child: InkWell(
          onTap: _forgotPassword,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.transparent,
          highlightColor: primaryObsidian.withValues(alpha: 0.06),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text('Forgot Password?', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: primaryObsidian,
            )),
          ),
        ),
      ),
      const SizedBox(height: 24),

      // Divider "Or"
      Row(children: [
        Expanded(child: Container(height: 1, color: dividerColor)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Or', style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Container(height: 1, color: dividerColor)),
      ]),
      const SizedBox(height: 24),

      // Google Button
      _SocialLoginButton(
        onPressed: _isLoading ? null : () => _signInWithOAuth(OAuthProvider.google),
        icon: Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
          width: 20, height: 20,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24, color: Colors.black),
        ),
        label: 'Continue with Google',
      ),
      const SizedBox(height: 12),

      // Facebook Button
      _SocialLoginButton(
        onPressed: _isLoading ? null : () => _signInWithOAuth(OAuthProvider.facebook),
        icon: const Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 22),
        label: 'Continue with Facebook',
      ),
      const SizedBox(height: 12),

      // Apple Button
      if (showApple) ...[
        _SocialLoginButton(
          onPressed: _isLoading ? null : () => _signInWithOAuth(OAuthProvider.apple),
          icon: const Icon(Icons.apple_rounded, color: Colors.black, size: 24),
          label: 'Continue with Apple',
        ),
        const SizedBox(height: 12),
      ],
      
      const SizedBox(height: 16),
      
      // Sign Up Link
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("Don't have an account?", style: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
          },
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Text('Sign up', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: primaryObsidian,
            )),
          ),
        ),
      ]),
      
      const SizedBox(height: 48),
      
      // Copyright
      const Center(
        child: Text('© 2026 Luma.Inc', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    ];

    return Theme(
      data: forcedTheme,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 420 : double.infinity),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header (Logo, Back Button, & Version)
                        _buildStaggeredItem(
                          index: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  if (Navigator.canPop(context)) ...[
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_rounded, color: textPrimary, size: 22),
                                      onPressed: () => Navigator.pop(context),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      splashRadius: 20,
                                    ),
                                    const SizedBox(width: 14),
                                  ],
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF4F4F5),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const LumaEmblem(
                                      size: 30,
                                      color: primaryObsidian,
                                    ),
                                  ),
                                ],
                              ),
                              const Text('2.45.6.34 Alpha', style: TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w500
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Animated List
                        ...List.generate(items.length, (index) {
                          return _buildStaggeredItem(
                            index: index + 1, // Offset by 1 for the header
                            child: items[index],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Pill-Shaped Text Field ──────────────────────────────────────────────────

class _PillTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Iterable<String>? autofillHints;
  final VoidCallback? onToggleObscure;

  const _PillTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
    this.onToggleObscure,
  });

  @override
  State<_PillTextField> createState() => _PillTextFieldState();
}

class _PillTextFieldState extends State<_PillTextField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(30), // Pill shape
        border: Border.all(
          color: _isFocused ? const Color(0xFF18181B) : Colors.transparent,
          width: _isFocused ? 1.5 : 0.0,
        ),
        boxShadow: _isFocused ? [
          BoxShadow(
            color: const Color(0xFF18181B).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        autofillHints: widget.autofillHints,
        style: const TextStyle(color: Color(0xFF111111), fontSize: 15, fontWeight: FontWeight.w500),
        cursorColor: const Color(0xFF18181B),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          suffixIcon: widget.onToggleObscure != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      widget.obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: const Color(0xFF6B7280),
                    ),
                    onPressed: widget.onToggleObscure,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ── Animated Gradient Button (Scale Effect) ────────────────────────────────

class _AnimatedGradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final List<Color> colors;
  final Color textColor;

  const _AnimatedGradientButton({
    required this.onPressed,
    required this.child,
    required this.colors,
    required this.textColor,
  });

  @override
  State<_AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      HapticFeedback.selectionClick();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            gradient: isDisabled 
                ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
                : LinearGradient(colors: widget.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(30),
            boxShadow: !isDisabled ? [
              BoxShadow(
                color: widget.colors.last.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Reusable Social Button ─────────────────────────────────────────────────

class _SocialLoginButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  State<_SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<_SocialLoginButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      HapticFeedback.selectionClick();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(30), // Pill shape
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.icon,
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
