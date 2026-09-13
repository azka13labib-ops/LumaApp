import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A delightfully bouncy heart like button that scales up and springs back
/// upon toggling, providing immediate tactile and visual satisfaction.
class AnimatedHeartButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const AnimatedHeartButton({
    super.key,
    required this.isLiked,
    required this.onTap,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<AnimatedHeartButton> createState() => _AnimatedHeartButtonState();
}

class _AnimatedHeartButtonState extends State<AnimatedHeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.44).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.44, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked && widget.isLiked) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    if (!widget.isLiked) {
      _controller.forward(from: 0.0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final active = widget.activeColor ?? const Color(0xFFEF4444); // Red-500
    final inactive = widget.inactiveColor ??
        (isDark ? Colors.white54 : Colors.black45);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: SizedBox(
              width: widget.size + 16,
              height: widget.size + 16,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey<bool>(widget.isLiked),
                    color: widget.isLiked ? active : inactive,
                    size: widget.size,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
