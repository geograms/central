import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:periodic3d/main.dart';
import 'package:periodic3d/scene.dart';
import 'package:vector_math/vector_math_64.dart';

/// The rotation angle a basis represents, in radians.
double angleOf(Matrix3 rotation) {
  final trace = rotation.entry(0, 0) + rotation.entry(1, 1) + rotation.entry(2, 2);
  return math.acos(((trace - 1) / 2).clamp(-1.0, 1.0));
}

Matrix3 basisOf(OrbitCamera camera) =>
    Matrix4.inverted(camera.viewMatrix).getRotation();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OrbitCamera framing', () {
    // The camera must orbit the very point it is pointed at. Getting this wrong
    // lets the scene slide off screen as the user rotates.
    test('keeps the target centred through arbitrary rotation', () {
      final camera = OrbitCamera(vsync: const TestVSync());
      addTearDown(camera.dispose);

      camera.rotate(120, -75, 900);
      camera.rotate(-40, 200, 900);
      camera.rotate(310, 55, 900);

      final centred = camera.viewMatrix.transformed3(camera.target);
      expect(centred.x, closeTo(0, 1e-9));
      expect(centred.y, closeTo(0, 1e-9));
      expect(centred.z, closeTo(-camera.distance, 1e-9));
    });

    test('keeps the target centred after panning and rotating', () {
      final camera = OrbitCamera(vsync: const TestVSync());
      addTearDown(camera.dispose);

      camera.rotate(80, 30, 900);
      camera.pan(60, -25, 0.4);
      camera.rotate(-140, 90, 900);

      final centred = camera.viewMatrix.transformed3(camera.target);
      expect(centred.x, closeTo(0, 1e-9));
      expect(centred.y, closeTo(0, 1e-9));
      expect(centred.z, closeTo(-camera.distance, 1e-9));
    });

    test('dragging right spins the scene right, following the finger', () {
      final camera = OrbitCamera(vsync: const TestVSync());
      addTearDown(camera.dispose);

      // A point on the near face of the scene, between camera and target.
      final near = Vector3(0, 0, 500);
      final before = camera.viewMatrix.transformed3(near);
      camera.rotate(120, 0, 900);
      final after = camera.viewMatrix.transformed3(near);

      expect(after.x, greaterThan(before.x));
    });
  });

  group('OrbitCamera.pan', () {
    test('tethers the target so the scene cannot leave the screen', () {
      final camera = OrbitCamera(vsync: const TestVSync());
      addTearDown(camera.dispose);

      for (var i = 0; i < 100; i++) {
        camera.pan(500, 500, 1);
      }

      expect(
        camera.target.length,
        lessThanOrEqualTo(OrbitCamera.maxTargetRadius + 1e-9),
      );
    });

    test('small pans move the target freely inside the tether', () {
      final camera = OrbitCamera(vsync: const TestVSync());
      addTearDown(camera.dispose);

      camera.pan(100, 0, 1);
      expect(camera.target.length, closeTo(100, 1e-9));
    });
  });

  group('OrbitCamera.rotate', () {
    test('rotation scales with the viewport, not raw pixels', () {
      final small = OrbitCamera(vsync: const TestVSync())..rotate(10, 0, 400);
      final large = OrbitCamera(vsync: const TestVSync())..rotate(20, 0, 800);
      addTearDown(small.dispose);
      addTearDown(large.dispose);

      expect(angleOf(basisOf(small)), closeTo(angleOf(basisOf(large)), 1e-9));
    });

    test('touch speed keeps a phone drag near desktop feel', () {
      // 50 logical px on a 360-wide phone vs a 900-tall desktop window.
      final phone = OrbitCamera(
        vsync: const TestVSync(),
        rotateSpeed: OrbitCamera.touchRotateSpeed,
      )..rotate(50, 0, 360);
      final desktop = OrbitCamera(
        vsync: const TestVSync(),
        rotateSpeed: OrbitCamera.mouseRotateSpeed,
      )..rotate(50, 0, 900);
      addTearDown(phone.dispose);
      addTearDown(desktop.dispose);

      final phoneAngle = angleOf(basisOf(phone));
      final desktopAngle = angleOf(basisOf(desktop));
      // Within 15% of each other, rather than the old 2.5x runaway.
      expect(phoneAngle, closeTo(desktopAngle, desktopAngle * 0.15));
    });
  });

  group('OrbitCamera.flingRotate', () {
    test('ignores a flick too slow to notice', () {
      final camera = OrbitCamera(vsync: const TestVSync());
      addTearDown(camera.dispose);

      camera.flingRotate(0.5, 0, 900);
      expect(camera.isSpinning, isFalse);
    });

    test('a real flick starts the scene coasting, and reset stops it', () {
      final camera = OrbitCamera(vsync: const TestVSync());
      addTearDown(camera.dispose);

      camera.flingRotate(600, 0, 900);
      expect(camera.isSpinning, isTrue);

      camera.reset();
      expect(camera.isSpinning, isFalse);
      expect(camera.target.length, 0);
    });
  });

  group('ExponentialInOut', () {
    const curve = ExponentialInOut();

    test('is pinned at both ends and symmetric about its midpoint', () {
      expect(curve.transform(0), 0);
      expect(curve.transform(1), 1);
      expect(curve.transform(0.5), closeTo(0.5, 1e-9));
    });

    test('rises monotonically', () {
      var previous = 0.0;
      for (var i = 1; i <= 100; i++) {
        final value = curve.transform(i / 100);
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
    });
  });

  group('layouts', () {
    /// The direction a card faces, taken from the matrix the renderer uses.
    Vector3 facingOf(Pose pose) => pose.matrix.getRotation() * Vector3(0, 0, 1);

    test('every layout places all 118 elements', () {
      for (final layout in Layout.values) {
        expect(buildLayout(layout).length, 118, reason: layout.name);
      }
    });

    test('sphere cards sit on the sphere and face outwards', () {
      for (final pose in buildLayout(Layout.sphere)) {
        expect(pose.position.length, closeTo(800, 1e-9));
        expect(facingOf(pose).dot(pose.position.normalized()), closeTo(1, 1e-6));
      }
    });

    test('helix cards face out from the axis, without tilting', () {
      for (final pose in buildLayout(Layout.helix)) {
        final radial = Vector3(pose.position.x, 0, pose.position.z).normalized();
        final facing = facingOf(pose);
        expect(facing.dot(radial), closeTo(1, 1e-6));
        expect(facing.y, closeTo(0, 1e-6));
      }
    });

    test('table puts hydrogen top-left and helium top-right', () {
      final table = buildLayout(Layout.table);
      expect(table[0].position.x, lessThan(0)); // H, column 1
      expect(table[1].position.x, greaterThan(0)); // He, column 18
      expect(table[0].position.y, equals(table[1].position.y)); // same row
    });
  });
}
