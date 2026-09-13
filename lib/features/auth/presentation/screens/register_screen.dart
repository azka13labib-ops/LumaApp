import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confirmCtrl = TextEditingController();
  
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _isLoading  = false;
  bool _obscure    = true;
  bool _obscureConfirm = true;
  String? _error;
  bool _success = false;
  bool _agreedToTerms = false;

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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _confirmFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    final name    = _nameCtrl.text.trim();
    final email   = _emailCtrl.text.trim().toLowerCase();
    final pass    = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Semua kolom wajib diisi.');
      HapticFeedback.heavyImpact();
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _error = 'Anda harus menyetujui Syarat & Ketentuan.');
      HapticFeedback.heavyImpact();
      return;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _error = 'Format email tidak valid.');
      HapticFeedback.heavyImpact();
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Password dan konfirmasi tidak cocok.');
      HapticFeedback.heavyImpact();
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter.');
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await Supabase.instance.client.auth.signUp(
        email: email, 
        password: pass,
        data: {'full_name': name},
      );
      if (mounted) setState(() { _isLoading = false; _success = true; });
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      setState(() => _error = _translateAuthError(e.message));
      HapticFeedback.heavyImpact();
    } catch (_) {
      setState(() => _error = 'Terjadi kesalahan koneksi. Coba lagi.');
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted && !_success) setState(() => _isLoading = false);
    }
  }

  String _translateAuthError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }
    return 'Pendaftaran gagal: $msg';
  }

  Widget _buildStaggeredItem({required int index, required Widget child}) {
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
    const bgColor = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF111111);
    const primaryObsidian = Color(0xFF09090B);
    const primaryCharcoal = Color(0xFF27272A);
    final forcedTheme = AppTheme.light;

    final items = <Widget>[
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

      if (_success) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
          ),
          child: const Row(children: [
            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 20),
            SizedBox(width: 12),
            Expanded(child: Text('Akun berhasil dibuat! Mengarahkan ke halaman masuk...', style: TextStyle(
              color: Color(0xFF166534), fontSize: 14, fontWeight: FontWeight.w500,
            ))),
          ]),
        ),
      ],

      const Text('Full Name', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _PillTextField(
        controller: _nameCtrl,
        focusNode: _nameFocusNode,
        hintText: 'John Doe',
        autofillHints: const [AutofillHints.name],
      ),
      const SizedBox(height: 20),

      const Text('Work Email', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _PillTextField(
        controller: _emailCtrl,
        focusNode: _emailFocusNode,
        hintText: 'name@example.com',
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
      ),
      const SizedBox(height: 6),
      const Text(' Please use your professional email address', style: TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 20),

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
      const SizedBox(height: 20),

      const Text('Confirm Password', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _PillTextField(
        controller: _confirmCtrl,
        focusNode: _confirmFocusNode,
        hintText: '••••••••',
        obscureText: _obscureConfirm,
        onToggleObscure: () {
          HapticFeedback.selectionClick();
          setState(() => _obscureConfirm = !_obscureConfirm);
        },
      ),
      const SizedBox(height: 24),

      // Checkbox terms
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24, height: 24,
            child: Checkbox(
              value: _agreedToTerms,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _agreedToTerms = val ?? false);
              },
              activeColor: primaryObsidian,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w400),
                children: [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(text: 'Terms & Conditions', style: TextStyle(color: primaryObsidian, fontWeight: FontWeight.w600)),
                  TextSpan(text: ' and '),
                  TextSpan(text: 'Privacy Policy', style: TextStyle(color: primaryObsidian, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),

      _AnimatedGradientButton(
        onPressed: (_isLoading || _success) ? null : _register,
        colors: const [primaryCharcoal, primaryObsidian],
        textColor: Colors.white,
        child: _isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
      ),
      const SizedBox(height: 24),
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
                        _buildStaggeredItem(
                          index: 0,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: textPrimary, size: 24),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                splashRadius: 24,
                              ),
                              const SizedBox(width: 16),
                              const Text('Create Account', style: TextStyle(
                                color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.5
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        ...List.generate(items.length, (index) {
                          return _buildStaggeredItem(
                            index: index + 1,
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
        borderRadius: BorderRadius.circular(30),
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
