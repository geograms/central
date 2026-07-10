import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The space behind the mesh: a static starfield and a faint polar grid.
/// Painted once into a picture and replayed — zero per-frame cost.
class Backdrop extends StatelessWidget {
  const Backdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(painter: _BackdropPainter(), size: Size.infinite),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  static ui.Picture? _picture;
  static Size _pictureSize = Size.zero;

  static ui.Picture _record(Size size) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Deep-space wash: barely-blue at the top fading to black.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          const <Color>[Color(0xFF06141B), Color(0xFF020408)],
        ),
    );

    // Stars: three brightness tiers, deterministic.
    var state = 0x9E3779B9;
    double next() {
      state ^= state << 13;
      state ^= state >>> 17;
      state ^= state << 5;
      return (state & 0xFFFFFF) / 0xFFFFFF;
    }

    final star = Paint();
    for (var i = 0; i < 260; i++) {
      final x = next() * size.width;
      final y = next() * size.height;
      final tier = next();
      if (tier > 0.92) {
        star.color = const Color(0xB0CFF6FF);
        canvas.drawCircle(Offset(x, y), 1.4, star);
      } else if (tier > 0.7) {
        star.color = const Color(0x66A9D8E6);
        canvas.drawCircle(Offset(x, y), 1.0, star);
      } else {
        star.color = const Color(0x3370A5B8);
        canvas.drawCircle(Offset(x, y), 0.7, star);
      }
    }

    // A faint polar grid low in the frame: the "floor" of the scene.
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x1230C8D8);
    final centre = Offset(size.width / 2, size.height * 0.58);
    for (var ring = 1; ring <= 6; ring++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: centre,
          width: size.width * 0.28 * ring,
          height: size.width * 0.1 * ring,
        ),
        grid,
      );
    }
    for (var spoke = 0; spoke < 12; spoke++) {
      final angle = spoke * math.pi / 6;
      canvas.drawLine(
        centre,
        centre +
            Offset(
              math.cos(angle) * size.width * 0.9,
              math.sin(angle) * size.width * 0.32,
            ),
        grid,
      );
    }

    return recorder.endRecording();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_picture == null || _pictureSize != size) {
      _picture = _record(size);
      _pictureSize = size;
    }
    canvas.drawPicture(_picture!);
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => false;
}
