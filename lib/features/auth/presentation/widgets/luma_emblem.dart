import 'dart:math' as math;
import 'package:flutter/material.dart';

class LumaEmblem extends StatelessWidget {
  final double size;
  final Color color;

  const LumaEmblem({
    super.key,
    this.size = 76,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LumaEmblemPainter(color: color),
      ),
    );
  }
}

class _LumaEmblemPainter extends CustomPainter {
  final Color color;

  const _LumaEmblemPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // 1. Center diamond star
    final d = r * 0.28;
    final diamondPath = Path()
      ..moveTo(cx, cy - d)
      ..lineTo(cx + d, cy)
      ..lineTo(cx, cy + d)
      ..lineTo(cx - d, cy)
      ..close();
    canvas.drawPath(diamondPath, paint);

    // 2. Four quadrant petals
    final gap = r * 0.10;
    final cornerR = r * 0.16;

    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(i * math.pi / 2);

      final path = Path();
      // Start near the inner gap corner
      path.moveTo(gap + cornerR, gap);
      // Top line
      path.lineTo(r * 0.72, gap);
      // Outer arc
      path.arcToPoint(
        Offset(gap, r * 0.72),
        radius: Radius.circular(r * 0.78),
        clockwise: true,
      );
      // Vertical left line
      path.lineTo(gap, gap + cornerR);
      // Inner subtle curve
      path.arcToPoint(
        Offset(gap + cornerR, gap),
        radius: Radius.circular(cornerR),
        clockwise: false,
      );
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LumaEmblemPainter oldDelegate) => oldDelegate.color != color;
}
