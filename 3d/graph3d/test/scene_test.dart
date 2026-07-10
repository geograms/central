import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph3d/data/models.dart';
import 'package:graph3d/scene/layouts.dart';
import 'package:graph3d/scene/orbit_camera.dart';
import 'package:graph3d/scene/pose.dart';
import 'package:graph3d/scene/projection.dart';
import 'package:vector_math/vector_math_64.dart';

/// Tickers created this way are still driven by `tester.pump`.
class _TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

/// Damping consumes a fixed fraction of the pending motion per *frame*, so a
/// single long pump is one step, not many. Run frames until the camera stops.
Future<void> _settle(WidgetTester tester, {int frames = 400}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

GraphNode _node(int id, {int column = 1, int row = 1}) => GraphNode(
  id: id,
  sourceId: id,
  symbol: 'n$id',
  name: 'file$id',
  license: '',
  column: column,
  row: row,
  tag: 'source',
  riskyLicense: false,
  hasCopyright: false,
);

/// The real dataset wraps at thirty columns; a single 426-column row would be
/// sixty thousand units wide and frame nothing like the app does.
const int _tableColumns = 30;

List<GraphNode> _nodes(int count) => List<GraphNode>.generate(
  count,
  (i) => _node(i + 1, column: i % _tableColumns + 1, row: i ~/ _tableColumns + 1),
);

void main() {
  group('layouts', () {
    test('table lays cards out on the z=0 plane, facing the camera', () {
      final geometry = buildLayout(GraphLayout.table, _nodes(3));
      for (final pose in geometry.poses) {
        expect(pose.position.z, 0);
        expect(pose.facing.z, closeTo(1, 1e-9));
      }
    });

    test('helix cards face outwards from the axis, without tilting', () {
      final geometry = buildLayout(GraphLayout.helix, _nodes(40));
      for (final pose in geometry.poses) {
        final radial = Vector3(pose.position.x, 0, pose.position.z)
          ..normalize();
        final facing = pose.facing;
        // Pointing away from the axis...
        expect(facing.dot(radial), closeTo(1, 1e-6));
        // ...and level with the horizon.
        expect(facing.y, closeTo(0, 1e-6));
      }
    });

    test('grid stacks 9x9 slabs a thousand units apart', () {
      final geometry = buildLayout(GraphLayout.grid, _nodes(83));
      expect(geometry.poses[0].position, Vector3(-800, 800, -2000));
      expect(geometry.poses[8].position, Vector3(2400, 800, -2000));
      expect(geometry.poses[9].position, Vector3(-800, 400, -2000));
      expect(geometry.poses[81].position, Vector3(-800, 800, -1000));
    });

    test('framing centre sits inside the layout it frames', () {
      for (final layout in GraphLayout.values) {
        final geometry = buildLayout(layout, _nodes(60));
        expect(geometry.radius, greaterThan(0));
        for (final pose in geometry.poses) {
          expect((pose.position - geometry.center).length,
              lessThanOrEqualTo(geometry.radius + 1e-6));
        }
      }
    });
  });

  group('projection', () {
    Projector projectorAt(Matrix4 view) =>
        Projector(view: view, perspective: perspectiveFor(800));

    test('a point at the camera target lands at the screen centre', () {
      final view = Matrix4.zero();
      setViewMatrix(view, Vector3(0, 0, 3000), Vector3.zero(), Vector3(0, 1, 0));
      final point = projectorAt(view).project(Vector3.zero())!;
      expect(point.screen.dx, closeTo(0, 1e-9));
      expect(point.screen.dy, closeTo(0, 1e-9));
    });

    test('the world is y-up and the screen is y-down', () {
      final view = Matrix4.zero();
      setViewMatrix(view, Vector3(0, 0, 3000), Vector3.zero(), Vector3(0, 1, 0));
      final above = projectorAt(view).project(Vector3(0, 500, 0))!;
      expect(above.screen.dy, lessThan(0));
    });

    test('a farther point projects smaller', () {
      final view = Matrix4.zero();
      setViewMatrix(view, Vector3(0, 0, 3000), Vector3.zero(), Vector3(0, 1, 0));
      final projector = projectorAt(view);
      final near = projector.project(Vector3(100, 0, 0))!;
      final far = projector.project(Vector3(100, 0, -3000))!;
      expect(far.screen.dx.abs(), lessThan(near.screen.dx.abs()));
      expect(far.scale, lessThan(near.scale));
    });

    test('points behind the eye are rejected, not mirrored into view', () {
      final view = Matrix4.zero();
      setViewMatrix(view, Vector3(0, 0, 3000), Vector3.zero(), Vector3(0, 1, 0));
      expect(projectorAt(view).project(Vector3(0, 0, 4000)), isNull);
    });

    test('the card matrix agrees with the point projection at its centre', () {
      final view = Matrix4.zero();
      setViewMatrix(view, Vector3(400, 0, 3000), Vector3.zero(), Vector3(0, 1, 0));
      final projector = projectorAt(view);
      final pose = Pose(Vector3(120, -260, 40), Quaternion.identity());

      // A line drawn to a card's centre must meet the card the renderer draws.
      // The Transform's perspective divide happens at rasterization, so undo it
      // here by hand: the card centre's w is the matrix's bottom-right entry.
      final matrix = projector.cardMatrix(pose.matrix);
      final centre = matrix.transform3(Vector3.zero());
      final w = matrix.entry(3, 3);
      final viaPoint = projector.project(pose.position)!;

      expect(centre.x / w, closeTo(viaPoint.screen.dx, 1e-6));
      expect(centre.y / w, closeTo(viaPoint.screen.dy, 1e-6));
    });
  });

  group('OrbitCamera', () {
    testWidgets('keeps the target centred through arbitrary rotation', (
      tester,
    ) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      camera.frame(Vector3(120, -40, 0), 2000, durationMs: 0);

      camera.rotate(140, -60, 800);
      await tester.pump(const Duration(milliseconds: 16));
      camera.rotate(-40, 90, 800);
      await _settle(tester);

      // Whatever the orbit has done, the camera still looks straight at the
      // point it orbits. Getting this wrong slides the scene off screen.
      final seen = camera.viewMatrix.transformed3(camera.target);
      expect(seen.x, closeTo(0, 1e-6));
      expect(seen.y, closeTo(0, 1e-6));
      expect(seen.z, closeTo(-camera.distance, 1e-6));
    });

    testWidgets('damping keeps turning after the drag, then settles', (
      tester,
    ) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      camera.frame(Vector3.zero(), 2000, durationMs: 0);

      final before = camera.eye.clone();
      camera.rotate(200, 0, 800);
      // A Ticker's first callback reports zero elapsed, so it moves nothing.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final firstStep = (camera.eye - before).length;

      await tester.pump(const Duration(milliseconds: 16));
      final secondStep = (camera.eye - before).length - firstStep;

      expect(firstStep, greaterThan(0));
      expect(secondStep, greaterThan(0), reason: 'motion continues after drag');
      expect(secondStep, lessThan(firstStep), reason: 'and it decays');

      await _settle(tester);
      final settled = camera.eye.clone();
      await tester.pump(const Duration(milliseconds: 16));
      expect((camera.eye - settled).length, closeTo(0, 1e-6));
    });

    testWidgets('never tips past the pole, so the horizon stays level', (
      tester,
    ) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      camera.frame(Vector3.zero(), 2000, durationMs: 0);

      for (var i = 0; i < 40; i++) {
        camera.rotate(0, 400, 800);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await _settle(tester);

      // The view matrix maps world up onto a screen-space vector; if the camera
      // had tipped over the pole, that vector would point down.
      final up = camera.viewMatrix.getRotation() * Vector3(0, 1, 0);
      expect(up.y, greaterThan(0), reason: 'the camera has not flipped over');
    });

    testWidgets('flying to a pose parks the eye off its face', (tester) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);

      final geometry = buildLayout(GraphLayout.helix, _nodes(40));
      final pose = geometry.poses[17];
      camera.flyToPose(pose, standoff: 990, durationMs: 300);
      await _settle(tester, frames: 30);

      expect(camera.isFlying, isFalse);
      expect((camera.target - pose.position).length, closeTo(0, 1e-6));
      final expectedEye = pose.position + pose.facing * 990.0;
      expect((camera.eye - expectedEye).length, lessThan(1e-3));
    });

    testWidgets('panning cannot push the graph off into empty space', (
      tester,
    ) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      final home = Vector3(100, 100, 0);
      camera.frame(home, 1500, durationMs: 0);

      for (var i = 0; i < 200; i++) {
        camera.pan(500, 500, 800);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await _settle(tester);

      expect((camera.target - home).length, lessThanOrEqualTo(1500 + 1e-6));
    });

    testWidgets('framing a layout puts every card on screen', (tester) async {
      const width = 1280.0;
      const height = 720.0;

      for (final layout in GraphLayout.values) {
        final camera = OrbitCamera(vsync: _TestVSync());
        camera.aspect = width / height;

        final geometry = buildLayout(layout, _nodes(426));
        camera.frame(
          geometry.center,
          geometry.radius,
          halfExtent: geometry.halfExtent,
          durationMs: 0,
        );

        final projector = Projector(
          view: camera.viewMatrix,
          perspective: perspectiveFor(height),
        );
        for (final pose in geometry.poses) {
          final point = projector.project(pose.position);
          expect(point, isNotNull, reason: '$layout card is behind the eye');
          expect(point!.screen.dx.abs(), lessThanOrEqualTo(width / 2),
              reason: '$layout card is off the side');
          expect(point.screen.dy.abs(), lessThanOrEqualTo(height / 2),
              reason: '$layout card is off the top or bottom');
        }
        camera.dispose();
      }
    });

    testWidgets('a narrow screen stops backing off rather than shrink to dust', (
      tester,
    ) async {
      final geometry = buildLayout(GraphLayout.table, _nodes(426));

      final desktop = OrbitCamera(vsync: _TestVSync())..aspect = 1280 / 720;
      addTearDown(desktop.dispose);
      final phone = OrbitCamera(vsync: _TestVSync())..aspect = 360 / 820;
      addTearDown(phone.dispose);

      // A wide window fits the whole table well inside the original's 8000.
      expect(desktop.fitDistance(geometry.halfExtent), lessThan(6000));
      // A portrait phone would need far more than 8000 to fit it, so framing
      // stops there and the user pans. Anything else is a wall of specks.
      expect(phone.fitDistance(geometry.halfExtent), 8000);
    });

    testWidgets('a gesture cancels a flight rather than fighting it', (
      tester,
    ) async {
      final camera = OrbitCamera(vsync: _TestVSync());
      addTearDown(camera.dispose);
      camera.frame(Vector3.zero(), 2000, durationMs: 3000);
      expect(camera.isFlying, isTrue);

      camera.rotate(10, 0, 800);
      expect(camera.isFlying, isFalse);
      await _settle(tester);
    });
  });

  group('exponentialInOut', () {
    test('pins both ends', () {
      expect(exponentialInOut(0), 0);
      expect(exponentialInOut(1), 1);
    });

    test('rises monotonically and is faster than linear through the middle', () {
      var previous = 0.0;
      for (var i = 1; i <= 100; i++) {
        final value = exponentialInOut(i / 100);
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
      expect(exponentialInOut(0.25), lessThan(0.25));
      expect(exponentialInOut(0.75), greaterThan(0.75));
    });
  });

  group('slerp', () {
    test('takes the short way round', () {
      final a = Quaternion.axisAngle(Vector3(0, 1, 0), 0.1);
      final b = Quaternion.axisAngle(Vector3(0, 1, 0), -0.1);
      final middle = slerp(a, b, 0.5);
      final axis = middle.asRotationMatrix() * Vector3(0, 0, 1);
      expect(axis.x, closeTo(0, 1e-9));
      expect(axis.z, closeTo(1, 1e-9));
    });
  });
}
