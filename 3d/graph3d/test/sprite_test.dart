import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:graph3d/graph3d.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  const size = Size(1200, 800);

  Projector projectorAt(Vector3 eye) {
    final view = Matrix4.zero();
    setViewMatrix(view, eye, Vector3.zero(), Vector3(0, 1, 0));
    return Projector(view: view, perspective: perspectiveFor(size.height));
  }

  Offset screenOf(Projector projector, Vector3 world) {
    final point = projector.project(world)!;
    return point.screen + Offset(size.width / 2, size.height / 2);
  }

  group('fogAlpha', () {
    test('near is clear, far sits on the floor, in between is monotonic', () {
      expect(fogAlpha(-1000, -1000, -5000, 0.25), 1);
      expect(fogAlpha(-5000, -1000, -5000, 0.25), closeTo(0.25, 1e-9));
      expect(fogAlpha(-9000, -1000, -5000, 0.25), closeTo(0.25, 1e-9));
      var previous = 1.1;
      for (var depth = -1000.0; depth >= -5000; depth -= 250) {
        final alpha = fogAlpha(depth, -1000, -5000, 0.25);
        expect(alpha, lessThanOrEqualTo(previous));
        previous = alpha;
      }
    });

    test('a degenerate band means no fog, not a division blowup', () {
      expect(fogAlpha(-2000, -1000, -1000, 0.25), 1);
      expect(fogAlpha(-2000, -1000, -500, 0.25), 1);
    });
  });

  group('pickSprite', () {
    final poses = <Pose>[
      Pose(Vector3(0, 0, 0), Quaternion.identity()),
      Pose(Vector3(400, 0, 0), Quaternion.identity()),
    ];
    double radiusOf(int index) => 22;

    test('hits the orb centre, misses beside it', () {
      final projector = projectorAt(Vector3(0, 0, 2000));
      expect(
        pickSprite(
          poses: poses,
          radiusOf: radiusOf,
          projector: projector,
          size: size,
          position: screenOf(projector, Vector3.zero()),
        ),
        1,
      );
      expect(
        pickSprite(
          poses: poses,
          radiusOf: radiusOf,
          projector: projector,
          size: size,
          position: screenOf(projector, Vector3(200, 0, 0)),
        ),
        isNull,
      );
    });

    test('a tiny far orb is still tappable within the finger floor', () {
      final projector = projectorAt(Vector3(0, 0, 30000));
      // Projected radius is ~1px; a tap 15px off centre must still land.
      expect(
        pickSprite(
          poses: poses,
          radiusOf: radiusOf,
          projector: projector,
          size: size,
          position:
              screenOf(projector, Vector3.zero()) + const Offset(15, 0),
        ),
        1,
      );
      // But not past the 24px floor.
      expect(
        pickSprite(
          poses: poses,
          radiusOf: radiusOf,
          projector: projector,
          size: size,
          position:
              screenOf(projector, Vector3.zero()) + const Offset(40, 0),
        ),
        isNull,
      );
    });

    test('the nearer of two overlapping orbs wins; onTop overrides', () {
      final stacked = <Pose>[
        Pose(Vector3(0, 0, 0), Quaternion.identity()),
        Pose(Vector3(0, 0, 500), Quaternion.identity()),
      ];
      final projector = projectorAt(Vector3(0, 0, 2000));
      final at = screenOf(projector, Vector3.zero());

      expect(
        pickSprite(
          poses: stacked,
          radiusOf: radiusOf,
          projector: projector,
          size: size,
          position: at,
        ),
        2,
      );
      expect(
        pickSprite(
          poses: stacked,
          radiusOf: radiusOf,
          projector: projector,
          size: size,
          position: at,
          onTop: const <int>[1],
        ),
        1,
      );
    });

    test('orbs behind the eye are unpickable', () {
      final projector = projectorAt(Vector3(0, 0, 2000));
      final behind = <Pose>[
        Pose(Vector3(0, 0, 3000), Quaternion.identity()),
      ];
      expect(
        pickSprite(
          poses: behind,
          radiusOf: radiusOf,
          projector: projector,
          size: size,
          position: Offset(size.width / 2, size.height / 2),
        ),
        isNull,
      );
    });
  });

  group('sectorShellPoses', () {
    test('stays inside its sector, on its shell, in its elevation band', () {
      const thetaStart = 0.5;
      const thetaSweep = 1.2;
      const phiSpread = math.pi / 3;
      final poses = sectorShellPoses(
        60,
        radius: 700,
        thetaStart: thetaStart,
        thetaSweep: thetaSweep,
        phiSpread: phiSpread,
      );
      expect(poses, hasLength(60));
      for (final pose in poses) {
        final p = pose.position;
        expect(p.length, closeTo(700, 1e-6));
        final theta = math.atan2(p.x, p.z);
        expect(theta, inInclusiveRange(thetaStart, thetaStart + thetaSweep));
        final phi = math.acos((p.y / 700).clamp(-1.0, 1.0));
        expect(
          phi,
          inInclusiveRange(
            math.pi / 2 - phiSpread / 2 - 1e-9,
            math.pi / 2 + phiSpread / 2 + 1e-9,
          ),
        );
      }
    });

    test('is deterministic', () {
      final a = sectorShellPoses(9, radius: 500, thetaStart: 1, thetaSweep: 2);
      final b = sectorShellPoses(9, radius: 500, thetaStart: 1, thetaSweep: 2);
      for (var i = 0; i < 9; i++) {
        expect((a[i].position - b[i].position).length, 0);
      }
    });
  });

  group('EdgeStyle', () {
    test('new fields default to the old rendering behaviour', () {
      const style = EdgeStyle();
      expect(style.glow, isFalse);
      expect(style.dashed, isFalse);
      expect(style.ticks, 0);
      expect(style.pulseCount, 1);
      expect(style.crawler, isTrue);
    });
  });
}
