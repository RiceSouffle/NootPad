import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate app icon PNG', () async {
    const double size = 1024;
    const double s = size;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, size, size));

    // Sandy background
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, size, size),
      ui.Paint()..color = const ui.Color(0xFFF2DFC3),
    );

    // Scale leaf to fit nicely in the icon (centered, 70% of size)
    const leafSize = size * 0.75;
    const offset = (size - leafSize) / 2;
    canvas.save();
    canvas.translate(offset, offset);

    // --- Leaf painting logic (from _AppLeafLogoPainter, scaled to leafSize) ---
    const ls = leafSize;

    // Shadow under the leaf
    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x1A000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
    canvas.drawCircle(const ui.Offset(ls * 0.5, ls * 0.55), ls * 0.34, shadowPaint);

    // Main leaf body
    final leafPaint = ui.Paint()
      ..color = const ui.Color(0xFF5EC5A8)
      ..style = ui.PaintingStyle.fill;

    final leafPath = ui.Path();
    leafPath.moveTo(ls * 0.5, ls * 0.08);
    leafPath.cubicTo(ls * 0.78, ls * 0.08, ls * 0.92, ls * 0.28, ls * 0.92, ls * 0.48);
    leafPath.cubicTo(ls * 0.92, ls * 0.68, ls * 0.75, ls * 0.88, ls * 0.55, ls * 0.88);
    leafPath.cubicTo(ls * 0.52, ls * 0.88, ls * 0.50, ls * 0.82, ls * 0.48, ls * 0.82);
    leafPath.cubicTo(ls * 0.46, ls * 0.82, ls * 0.44, ls * 0.88, ls * 0.40, ls * 0.88);
    leafPath.cubicTo(ls * 0.22, ls * 0.88, ls * 0.08, ls * 0.68, ls * 0.08, ls * 0.48);
    leafPath.cubicTo(ls * 0.08, ls * 0.28, ls * 0.22, ls * 0.08, ls * 0.5, ls * 0.08);
    leafPath.close();
    canvas.drawPath(leafPath, leafPaint);

    // Lighter inner highlight
    final highlightPaint = ui.Paint()
      ..color = const ui.Color(0xFF7DD4BC)
      ..style = ui.PaintingStyle.fill;
    final highlightPath = ui.Path();
    highlightPath.moveTo(ls * 0.5, ls * 0.16);
    highlightPath.cubicTo(ls * 0.68, ls * 0.16, ls * 0.78, ls * 0.30, ls * 0.78, ls * 0.44);
    highlightPath.cubicTo(ls * 0.78, ls * 0.56, ls * 0.68, ls * 0.66, ls * 0.54, ls * 0.66);
    highlightPath.cubicTo(ls * 0.40, ls * 0.66, ls * 0.22, ls * 0.56, ls * 0.22, ls * 0.44);
    highlightPath.cubicTo(ls * 0.22, ls * 0.30, ls * 0.34, ls * 0.16, ls * 0.5, ls * 0.16);
    highlightPath.close();
    canvas.drawPath(highlightPath, highlightPaint);

    // Center vein
    final veinPaint = ui.Paint()
      ..color = const ui.Color(0xFF3AAA8A)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = ls * 0.04
      ..strokeCap = ui.StrokeCap.round;
    canvas.drawLine(
      const ui.Offset(ls * 0.5, ls * 0.22),
      const ui.Offset(ls * 0.48, ls * 0.72),
      veinPaint,
    );

    // Left vein
    final leftVeinPath = ui.Path();
    leftVeinPath.moveTo(ls * 0.49, ls * 0.40);
    leftVeinPath.quadraticBezierTo(ls * 0.36, ls * 0.36, ls * 0.28, ls * 0.42);
    canvas.drawPath(leftVeinPath, veinPaint);

    // Right vein
    final rightVeinPath = ui.Path();
    rightVeinPath.moveTo(ls * 0.49, ls * 0.48);
    rightVeinPath.quadraticBezierTo(ls * 0.62, ls * 0.44, ls * 0.70, ls * 0.50);
    canvas.drawPath(rightVeinPath, veinPaint);

    // Small curled stem at top
    final stemPaint = ui.Paint()
      ..color = const ui.Color(0xFF8B6914)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = ls * 0.05
      ..strokeCap = ui.StrokeCap.round;
    final stemPath = ui.Path();
    stemPath.moveTo(ls * 0.50, ls * 0.12);
    stemPath.quadraticBezierTo(ls * 0.56, ls * 0.02, ls * 0.62, ls * 0.06);
    canvas.drawPath(stemPath, stemPaint);

    canvas.restore();
    // --- End leaf painting ---

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final file = File('assets/icon/app_icon.png');
    await file.create(recursive: true);
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    // ignore: avoid_print
    print('Icon generated: ${file.path}');
  });
}
