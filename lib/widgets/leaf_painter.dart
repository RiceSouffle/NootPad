import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LeafDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.warmBrown.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    // Top-right leaf
    _drawLeaf(canvas, Offset(size.width - 30, 20), 40, -0.3, paint);

    // Bottom-left leaf
    _drawLeaf(canvas, Offset(20, size.height - 40), 35, 0.5, paint);

    // Small leaf near top-left
    paint.color = AppColors.teal.withValues(alpha: 0.04);
    _drawLeaf(canvas, Offset(40, 60), 25, 0.8, paint);
  }

  void _drawLeaf(
      Canvas canvas, Offset center, double size, double rotation, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path();
    path.moveTo(0, -size);
    path.quadraticBezierTo(size * 0.6, -size * 0.3, 0, size * 0.4);
    path.quadraticBezierTo(-size * 0.6, -size * 0.3, 0, -size);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cute leaf logo with a rounded leaf shape,
/// visible veins, and a small curled stem.
class AppLeafLogo extends StatelessWidget {
  final double size;

  const AppLeafLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _AppLeafLogoPainter(),
      ),
    );
  }
}

class _AppLeafLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Shadow under the leaf
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(s * 0.5, s * 0.55), s * 0.34, shadowPaint);

    // Main leaf body - AC green
    final leafPaint = Paint()
      ..color = const Color(0xFF5EC5A8)
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    // Rounded leaf shape with a notch at the bottom
    leafPath.moveTo(s * 0.5, s * 0.08);
    leafPath.cubicTo(s * 0.78, s * 0.08, s * 0.92, s * 0.28, s * 0.92, s * 0.48);
    leafPath.cubicTo(s * 0.92, s * 0.68, s * 0.75, s * 0.88, s * 0.55, s * 0.88);
    leafPath.cubicTo(s * 0.52, s * 0.88, s * 0.50, s * 0.82, s * 0.48, s * 0.82);
    leafPath.cubicTo(s * 0.46, s * 0.82, s * 0.44, s * 0.88, s * 0.40, s * 0.88);
    leafPath.cubicTo(s * 0.22, s * 0.88, s * 0.08, s * 0.68, s * 0.08, s * 0.48);
    leafPath.cubicTo(s * 0.08, s * 0.28, s * 0.22, s * 0.08, s * 0.5, s * 0.08);
    leafPath.close();
    canvas.drawPath(leafPath, leafPaint);

    // Lighter inner highlight
    final highlightPaint = Paint()
      ..color = const Color(0xFF7DD4BC)
      ..style = PaintingStyle.fill;
    final highlightPath = Path();
    highlightPath.moveTo(s * 0.5, s * 0.16);
    highlightPath.cubicTo(s * 0.68, s * 0.16, s * 0.78, s * 0.30, s * 0.78, s * 0.44);
    highlightPath.cubicTo(s * 0.78, s * 0.56, s * 0.68, s * 0.66, s * 0.54, s * 0.66);
    highlightPath.cubicTo(s * 0.40, s * 0.66, s * 0.22, s * 0.56, s * 0.22, s * 0.44);
    highlightPath.cubicTo(s * 0.22, s * 0.30, s * 0.34, s * 0.16, s * 0.5, s * 0.16);
    highlightPath.close();
    canvas.drawPath(highlightPath, highlightPaint);

    // Center vein
    final veinPaint = Paint()
      ..color = const Color(0xFF3AAA8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(s * 0.5, s * 0.22),
      Offset(s * 0.48, s * 0.72),
      veinPaint,
    );

    // Left vein
    final leftVeinPath = Path();
    leftVeinPath.moveTo(s * 0.49, s * 0.40);
    leftVeinPath.quadraticBezierTo(s * 0.36, s * 0.36, s * 0.28, s * 0.42);
    canvas.drawPath(leftVeinPath, veinPaint);

    // Right vein
    final rightVeinPath = Path();
    rightVeinPath.moveTo(s * 0.49, s * 0.48);
    rightVeinPath.quadraticBezierTo(s * 0.62, s * 0.44, s * 0.70, s * 0.50);
    canvas.drawPath(rightVeinPath, veinPaint);

    // Small curled stem at top
    final stemPaint = Paint()
      ..color = const Color(0xFF8B6914)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round;
    final stemPath = Path();
    stemPath.moveTo(s * 0.50, s * 0.12);
    stemPath.quadraticBezierTo(s * 0.56, s * 0.02, s * 0.62, s * 0.06);
    canvas.drawPath(stemPath, stemPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Keep the simple LeafIcon for other uses (empty states, etc.)
class LeafIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const LeafIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LeafIconPainter(color ?? AppColors.leafGreen),
    );
  }
}

class _LeafIconPainter extends CustomPainter {
  final Color color;

  _LeafIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final s = size.width;
    final path = Path();

    path.moveTo(s * 0.5, s * 0.05);
    path.cubicTo(s * 0.8, s * 0.05, s * 0.95, s * 0.3, s * 0.95, s * 0.5);
    path.cubicTo(s * 0.95, s * 0.75, s * 0.7, s * 0.95, s * 0.5, s * 0.95);
    path.cubicTo(s * 0.3, s * 0.95, s * 0.05, s * 0.75, s * 0.05, s * 0.5);
    path.cubicTo(s * 0.05, s * 0.3, s * 0.2, s * 0.05, s * 0.5, s * 0.05);
    path.close();

    canvas.drawPath(path, paint);

    final stemPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(s * 0.5, s * 0.3),
      Offset(s * 0.5, s * 0.75),
      stemPaint,
    );
    canvas.drawLine(
      Offset(s * 0.5, s * 0.5),
      Offset(s * 0.35, s * 0.38),
      stemPaint,
    );
    canvas.drawLine(
      Offset(s * 0.5, s * 0.55),
      Offset(s * 0.65, s * 0.43),
      stemPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
