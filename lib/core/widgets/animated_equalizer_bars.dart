import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A lightweight 3-bar jumping equalizer animation that indicates an actively
/// playing audio track, similar to Spotify and Apple Music.
class AnimatedEqualizerBars extends StatefulWidget {
  final Color color;
  final double size;
  final bool isPlaying;

  const AnimatedEqualizerBars({
    super.key,
    this.color = Colors.white,
    this.size = 16.0,
    this.isPlaying = true,
  });

  @override
  State<AnimatedEqualizerBars> createState() => _AnimatedEqualizerBarsState();
}

class _AnimatedEqualizerBarsState extends State<AnimatedEqualizerBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedEqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = (widget.size / 4.5).clamp(2.0, 4.0);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          // Calculate heights with phase shifts for natural wave pattern
          final h1 = widget.isPlaying
              ? (0.25 + 0.70 * (0.5 + 0.5 * math.sin(t * 2 * math.pi)))
              : 0.35;
          final h2 = widget.isPlaying
              ? (0.20 + 0.75 * (0.5 + 0.5 * math.sin((t + 0.33) * 2 * math.pi)))
              : 0.65;
          final h3 = widget.isPlaying
              ? (0.30 + 0.65 * (0.5 + 0.5 * math.sin((t + 0.66) * 2 * math.pi)))
              : 0.25;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(barWidth, widget.size * h1),
              _buildBar(barWidth, widget.size * h2),
              _buildBar(barWidth, widget.size * h3),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBar(double width, double height) {
    return Container(
      width: width,
      height: height.clamp(3.0, widget.size),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(width / 2),
      ),
    );
  }
}
