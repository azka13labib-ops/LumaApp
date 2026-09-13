import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper that adds a distinct, tactile spring bounce down-and-rebound effect
/// when tapped or held, making cards, list rows, and buttons feel physical and alive.
class InteractiveScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool enableHaptic;
  final BorderRadius? borderRadius;

  const InteractiveScaleButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.92,
    this.enableHaptic = true,
    this.borderRadius,
  });

  @override
  State<InteractiveScaleButton> createState() => _InteractiveScaleButtonState();
}

class _InteractiveScaleButtonState extends State<InteractiveScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHeld = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant InteractiveScaleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pressedScale != oldWidget.pressedScale) {
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: widget.pressedScale,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeOutBack,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTapDown() async {
    _isHeld = true;
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    await _controller.forward();
  }

  Future<void> _handleTapUp() async {
    _isHeld = false;
    // Guarantee minimum dip duration so quick taps are unmistakably visible & felt
    await Future.delayed(const Duration(milliseconds: 65));
    if (mounted && !_isHeld) {
      await _controller.reverse();
    }
  }

  void _handleTapCancel() {
    _isHeld = false;
    if (mounted) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapCancel,
      onTap: () {
        if (widget.enableHaptic) {
          HapticFeedback.lightImpact();
        }
        widget.onTap?.call();
      },
      onLongPress: () {
        if (widget.enableHaptic) {
          HapticFeedback.mediumImpact();
        }
        widget.onLongPress?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.borderRadius != null
            ? ClipRRect(
                borderRadius: widget.borderRadius!,
                child: widget.child,
              )
            : widget.child,
      ),
    );
  }
}
