import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/luma_emblem.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildStaggered({required double start, required Widget child}) {
    final clampedStart = start.clamp(0.0, 0.7);
    final clampedEnd = (clampedStart + 0.3).clamp(0.0, 1.0);

    final itemFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(clampedStart, clampedEnd, curve: Curves.easeOutCubic),
      ),
    );

    final itemSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(clampedStart, clampedEnd, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: itemFade,
      child: SlideTransition(
        position: itemSlide,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryObsidian = Color(0xFF09090B);
    const primaryCharcoal = Color(0xFF27272A);
    final forcedTheme = AppTheme.light;

    return Theme(
      data: forcedTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 420 : double.infinity),
                child: Stack(
                  children: [
                    // 1. Background Gradient (Monochrome Charcoal to Pearl White)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF18181B), // Deep obsidian zinc at top
                              Color(0xFF27272A), // Charcoal zinc-800
                              Color(0xFF3F3F46), // Muted zinc-700
                              Color(0xFF52525B), // Softening transition
                              Color(0xFF8B8B94), // Silver-grey mist
                              Color(0xFFD4D4D8), // Feathering pearl pastel
                              Color(0xFFF4F4F5), // Subtle silver mist
                              Colors.white,      // Pure white start
                              Colors.white,      // Solid pure white bottom
                            ],
                            stops: [0.0, 0.20, 0.35, 0.46, 0.56, 0.66, 0.73, 0.80, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // 2. Concentric Ripple Rings & Ambient Glow behind logo
                    Positioned(
                      top: constraints.maxHeight * 0.12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ambient radial glow
                            Container(
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF71717A).withValues(alpha: 0.22),
                                    const Color(0xFF52525B).withValues(alpha: 0.08),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),

                            // Outer Ring 3
                            Container(
                              width: 290,
                              height: 290,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 1.2,
                                ),
                              ),
                            ),

                            // Middle Ring 2
                            Container(
                              width: 210,
                              height: 210,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.11),
                                  width: 1.2,
                                ),
                              ),
                            ),

                            // Inner Ring 1
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Foreground Content
                    SafeArea(
                      child: Column(
                        children: [
                          // Top Section: Logo & Title
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 24.0),
                              child: _buildStaggered(
                                start: 0.1,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // White Glowing Vector Emblem (Matches Argumind perfectly, zero asset errors)
                                    const LumaEmblem(size: 82, color: Colors.white),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Luma',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Bottom Section: Tagline & Buttons on Crisp White
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Tagline
                                  _buildStaggered(
                                    start: 0.35,
                                    child: const Text(
                                      'Your AI Assistant for Case Law and Legal Insight.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF374151),
                                        fontSize: 14,
                                        height: 1.45,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Button 1: Sign In (Obsidian Charcoal Gradient Pill)
                                  _buildStaggered(
                                    start: 0.48,
                                    child: _PillButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        );
                                      },
                                      isPrimary: true,
                                      colors: const [primaryCharcoal, primaryObsidian],
                                      label: 'Sign In',
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Button 2: Create Account (White with Charcoal Outline)
                                  _buildStaggered(
                                    start: 0.62,
                                    child: _PillButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                        );
                                      },
                                      isPrimary: false,
                                      label: 'Create Account',
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PillButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isPrimary;
  final List<Color>? colors;
  final String label;

  const _PillButton({
    required this.onPressed,
    required this.isPrimary,
    this.colors,
    required this.label,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryObsidian = Color(0xFF09090B);

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.isPrimary && widget.colors != null
                ? LinearGradient(
                    colors: widget.colors!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isPrimary ? null : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: widget.isPrimary
                ? null
                : Border.all(color: primaryObsidian, width: 1.5),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF09090B).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isPrimary ? Colors.white : primaryObsidian,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
