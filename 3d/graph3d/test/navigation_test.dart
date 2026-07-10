import 'dart:ui' show Offset, Size;

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph3d/graph3d.dart';
import 'package:vector_math/vector_math_64.dart';

class _TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void main() {
  const size = Size(1200, 800);

  Offset projectOf(OrbitCamera camera, Vector3 world) {
    final projector = Projector(
      view: camera.viewMatrix,
      perspective: perspectiveFor(size.height),
    );
    return projector.project(world)!.screen;
  }

  group('worldAtScreen', () {
    testWidgets('round-trips through projection', (tester) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      camera.frame(Vector3(120, -60, 40), 2000, distance: 3000, durationMs: 0);
      camera.rotate(80, -30, size.height);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      camera.stop();

      for (final probe in const <Offset>[
        Offset.zero,
        Offset(210, -140),
        Offset(-320, 95),
      ]) {
        final world = camera.worldAtScreen(probe.dx, probe.dy, size.height);
        final screen = projectOf(camera, world);
        expect(screen.dx, closeTo(probe.dx, 1e-6));
        expect(screen.dy, closeTo(probe.dy, 1e-6));
      }
    });
  });

  group('zoomAbout', () {
    testWidgets('keeps the anchor point fixed on screen', (tester) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      camera.frame(Vector3.zero(), 2000, distance: 4000, durationMs: 0);
      camera.rotate(60, 40, size.height);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      camera.stop();

      // The world point under a pinch focal, before...
      const focal = Offset(180, -120);
      final anchor = camera.worldAtScreen(focal.dx, focal.dy, size.height);
      expect(projectOf(camera, anchor).dx, closeTo(focal.dx, 1e-6));

      // ...zoom in about it, twice...
      camera.zoomAbout(0.6, anchor);
      camera.zoomAbout(0.7, anchor);

      // ...and it has not moved on screen, while the camera got closer.
      final after = projectOf(camera, anchor);
      expect(after.dx, closeTo(focal.dx, 1e-6));
      expect(after.dy, closeTo(focal.dy, 1e-6));
      expect(camera.distance, closeTo(4000 * 0.6 * 0.7, 1e-6));
    });

    testWidgets('respects the distance clamp without drifting the anchor', (
      tester,
    ) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      camera.frame(Vector3.zero(), 2000, distance: 300, durationMs: 0);

      final anchor = camera.worldAtScreen(100, 50, size.height);
      camera.zoomAbout(0.1, anchor); // would go below minDistance
      expect(camera.distance, OrbitCamera.minDistance);
      final after = projectOf(camera, anchor);
      expect(after.dx, closeTo(100, 1e-6));
      expect(after.dy, closeTo(50, 1e-6));
      await tester.pump();
    });
  });

  group('fling', () {
    testWidgets('coasts after release and decays to a stop', (tester) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      camera.frame(Vector3.zero(), 2000, distance: 3000, durationMs: 0);

      final before = camera.eye.clone();
      camera.fling(1200, 0, size.height);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final early = (camera.eye - before).length;
      expect(early, greaterThan(0), reason: 'the world keeps turning');

      await tester.pump(const Duration(milliseconds: 400));
      final mid = camera.eye.clone();
      await tester.pump(const Duration(milliseconds: 100));
      final lateStep = (camera.eye - mid).length;
      expect(lateStep, lessThan(early), reason: 'and it slows down');

      // Long after, it has stopped entirely and the ticker sleeps.
      for (var i = 0; i < 400; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final settled = camera.eye.clone();
      await tester.pump(const Duration(milliseconds: 50));
      expect((camera.eye - settled).length, 0);
    });

    testWidgets('a tiny end-of-drag twitch does not coast', (tester) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      camera.frame(Vector3.zero(), 2000, distance: 3000, durationMs: 0);

      final before = camera.eye.clone();
      camera.fling(30, 20, size.height); // far below the threshold
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect((camera.eye - before).length, 0);
    });
  });

  group('swoop', () {
    testWidgets('a cross-scene flight climbs mid-way, then lands exactly', (
      tester,
    ) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      camera.frame(Vector3.zero(), 2000, distance: 2000, durationMs: 0);

      camera.flyToPoint(Vector3(6000, 0, 0), distance: 2000, durationMs: 1000);
      await tester.pump();

      var peak = 0.0;
      for (var i = 0; i < 70; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (camera.distance > peak) peak = camera.distance;
      }
      expect(
        peak,
        greaterThan(2500),
        reason: 'the flight gains altitude over a long hop',
      );
      expect(camera.distance, closeTo(2000, 1e-6), reason: 'and lands on spec');
      expect((camera.target - Vector3(6000, 0, 0)).length, closeTo(0, 1e-6));
    });

    testWidgets('a short hop does not bounce', (tester) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      camera.frame(Vector3.zero(), 2000, distance: 3000, durationMs: 0);

      camera.flyToPoint(Vector3(400, 0, 0), distance: 3000, durationMs: 600);
      await tester.pump();
      var peak = 0.0;
      for (var i = 0; i < 45; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (camera.distance > peak) peak = camera.distance;
      }
      expect(peak, closeTo(3000, 1e-6));
    });
  });

  group('tilt and twist', () {
    testWidgets('twist turns azimuth; tilt raises the eye', (tester) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      camera.frame(Vector3.zero(), 2000, distance: 3000, durationMs: 0);

      final eyeBefore = camera.eye.clone();
      camera.twist(0.5);
      final turned = camera.eye;
      expect((turned - eyeBefore).length, greaterThan(1),
          reason: 'twist moved the eye');
      expect(turned.y, closeTo(eyeBefore.y, 1e-6),
          reason: 'twist does not change elevation');

      // Google-Earth convention: fingers up tilts toward the horizon (the
      // eye descends); fingers down returns overhead.
      camera.tilt(-120, size.height);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      camera.stop();
      expect(camera.eye.y, lessThan(eyeBefore.y));

      camera.tilt(300, size.height);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      camera.stop();
      expect(camera.eye.y, greaterThan(eyeBefore.y));
      await tester.pump();
    });
  });
}
