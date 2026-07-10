import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../graph_controller.dart' show kProfileScene;
import '../scene/pose.dart';
import '../scene/projection.dart';
import '../theme.dart';

/// Ball radius in world units, as in the original's `SphereGeometry(5, 5, 5)`.
const double _kBallRadius = 5;

/// Draws the dependency lines behind the cards, with a ball crawling from
/// source to target along each one — the original's second WebGL scene, which
/// sat at `zIndex: -200`.
///
/// Endpoints are projected through the same matrix chain as the cards, so a
/// line meets the card it points at.
class LinkPainter extends CustomPainter {
  LinkPainter({
    required this.links,
    required this.poses,
    required this.projector,
    required this.clockMs,
    required this.periods,
    required super.repaint,
  });

  final List<GraphLink> links;
  final List<Pose> poses;
  final Projector projector;
  final double clockMs;

  /// One crawl period per link, in milliseconds, so the balls do not march in
  /// lockstep.
  final List<double> periods;

  static final Stopwatch _paintWatch = Stopwatch();
  static int _paintCalls = 0;

  @override
  void paint(Canvas canvas, Size size) {
    if (links.isEmpty) return;
    _paintWatch.start();
    _paintLinks(canvas, size);
    _paintWatch.stop();
    if (kProfileScene && ++_paintCalls % 60 == 0) {
      debugPrint(
        'LINKPAINT avg=${(_paintWatch.elapsedMicroseconds / 60 / 1000).toStringAsFixed(2)}ms/frame '
        '(${links.length} links)',
      );
      _paintWatch.reset();
    }
  }

  void _paintLinks(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final line = Paint()
      ..color = GraphColors.link
      ..strokeWidth = 1
      ..isAntiAlias = true;
    final ball = Paint()..color = GraphColors.link;

    for (var i = 0; i < links.length; i++) {
      final link = links[i];
      if (link.isSelfLink) continue;

      final from = poses[link.from - 1].position;
      final to = poses[link.to - 1].position;

      final a = projector.project(from);
      final b = projector.project(to);
      // Any endpoint behind the eye would project to a mirrored point, drawing
      // a line across the screen that does not exist.
      if (a == null || b == null) continue;

      canvas.drawLine(centre + a.screen, centre + b.screen, line);

      final period = periods[i];
      final phase = (clockMs % period) / period;
      final crawler = projector.project(from + (to - from) * phase);
      if (crawler == null) continue;

      canvas.drawCircle(
        centre + crawler.screen,
        (_kBallRadius * crawler.scale).clamp(1.0, 10.0),
        ball,
      );
    }
  }

  @override
  bool shouldRepaint(LinkPainter oldDelegate) => true;
}

/// Assigns each link the 9-to-11 second crawl the original tweened.
List<double> buildCrawlPeriods(int count, math.Random random) =>
    List<double>.generate(count, (_) => random.nextDouble() * 2000 + 9000);
