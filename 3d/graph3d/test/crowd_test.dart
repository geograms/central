import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:graph3d/graph3d.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  const size = Size(1200, 800);

  Projector projectorAt(Vector3 eye, [Vector3? target]) {
    final view = Matrix4.zero();
    setViewMatrix(view, eye, target ?? Vector3.zero(), Vector3(0, 1, 0));
    return Projector(view: view, perspective: perspectiveFor(size.height));
  }

  /// Where a world point lands in scene-local (top-left origin) coordinates.
  Offset screenOf(Projector projector, Vector3 world) {
    final point = projector.project(world)!;
    return point.screen + Offset(size.width / 2, size.height / 2);
  }

  group('pickCard', () {
    test('finds the card under the pointer, and misses beside it', () {
      final poses = <Pose>[
        Pose(Vector3(0, 0, 0), Quaternion.identity()),
        Pose(Vector3(400, 0, 0), Quaternion.identity()),
      ];
      final projector = projectorAt(Vector3(0, 0, 2000));

      expect(
        pickCard(
          poses: poses,
          projector: projector,
          size: size,
          position: screenOf(projector, Vector3.zero()),
        ),
        1,
      );
      expect(
        pickCard(
          poses: poses,
          projector: projector,
          size: size,
          position: screenOf(projector, Vector3(400, 0, 0)),
        ),
        2,
      );
      // Between the two cards: empty space.
      expect(
        pickCard(
          poses: poses,
          projector: projector,
          size: size,
          position: screenOf(projector, Vector3(200, 0, 0)),
        ),
        isNull,
      );
    });

    test('the nearer of two overlapping cards wins', () {
      final poses = <Pose>[
        Pose(Vector3(0, 0, 0), Quaternion.identity()),
        Pose(Vector3(0, 0, 500), Quaternion.identity()), // nearer the eye
      ];
      final projector = projectorAt(Vector3(0, 0, 2000));

      expect(
        pickCard(
          poses: poses,
          projector: projector,
          size: size,
          position: screenOf(projector, Vector3.zero()),
        ),
        2,
      );
    });

    test('a card in onTop wins the pick even from behind', () {
      final poses = <Pose>[
        Pose(Vector3(0, 0, 0), Quaternion.identity()),
        Pose(Vector3(0, 0, -500), Quaternion.identity()), // farther away
      ];
      final projector = projectorAt(Vector3(0, 0, 2000));

      // Drawn on top (the selected card), so picked despite the depth.
      expect(
        pickCard(
          poses: poses,
          projector: projector,
          size: size,
          position: screenOf(projector, Vector3.zero()),
          onTop: const <int>[2],
        ),
        2,
      );
    });

    test('a rotated card is picked through its projected footprint', () {
      // Face 60 degrees away from the camera: the on-screen footprint is a
      // narrow trapezoid. The pick must respect it, not the unrotated bounds.
      final rotated = Pose(
        Vector3.zero(),
        Quaternion.axisAngle(Vector3(0, 1, 0), 60 * 3.14159265 / 180),
      );
      final projector = projectorAt(Vector3(0, 0, 1000));

      expect(
        pickCard(
          poses: <Pose>[rotated],
          projector: projector,
          size: size,
          position: screenOf(projector, Vector3.zero()),
        ),
        1,
      );
      // 70px to the side: outside the foreshortened footprint (a flat card
      // 120 wide at 60 degrees spans about +-30px at this distance), even
      // though an unrotated card here would span +-66px and be hit.
      expect(
        pickCard(
          poses: <Pose>[rotated],
          projector: projector,
          size: size,
          position:
              screenOf(projector, Vector3.zero()) + const Offset(70, 0),
        ),
        isNull,
      );
    });

    test('cards behind the eye are never picked', () {
      final poses = <Pose>[
        Pose(Vector3(0, 0, 3000), Quaternion.identity()),
      ];
      final projector = projectorAt(Vector3(0, 0, 2000));

      expect(
        pickCard(
          poses: poses,
          projector: projector,
          size: size,
          position: Offset(size.width / 2, size.height / 2),
        ),
        isNull,
      );
    });

    test('agrees with the corner of the card, not just its centre', () {
      final poses = <Pose>[Pose(Vector3.zero(), Quaternion.identity())];
      final projector = projectorAt(Vector3(0, 0, 2000));

      // Just inside and just outside the top-left corner.
      final inside = screenOf(projector, Vector3(-58, 78, 0));
      final outside = screenOf(projector, Vector3(-64, 84, 0));
      expect(
        pickCard(
          poses: poses,
          projector: projector,
          size: size,
          position: inside,
        ),
        1,
      );
      expect(
        pickCard(
          poses: poses,
          projector: projector,
          size: size,
          position: outside,
        ),
        isNull,
      );
    });
  });
}
