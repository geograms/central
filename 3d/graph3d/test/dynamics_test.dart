import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph3d/graph3d.dart';
import 'package:vector_math/vector_math_64.dart';

class _TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

SceneNode<String> _node(String key) => SceneNode<String>(key: key, data: key);

GraphScene<String> _scene(List<String> keys, [List<SceneEdge>? edges]) =>
    GraphScene<String>(
      nodes: <SceneNode<String>>[for (final k in keys) _node(k)],
      edges: edges ?? const <SceneEdge>[],
    );

/// A one-pose-per-node line along x, spaced 400 apart: easy to assert on.
LayoutGeometry _line(List<SceneNode<String>> nodes) =>
    LayoutGeometry.fromPoses(<Pose>[
      for (var i = 0; i < nodes.length; i++)
        Pose(Vector3(i * 400.0, 0, 0), Quaternion.identity()),
    ]);

/// The same line, shifted up, so persisted nodes visibly move.
LayoutGeometry _lineShifted(List<SceneNode<String>> nodes) =>
    LayoutGeometry.fromPoses(<Pose>[
      for (var i = 0; i < nodes.length; i++)
        Pose(Vector3(i * 400.0, 500, 0), Quaternion.identity()),
    ]);

void main() {
  late GraphSceneController<String> controller;

  GraphSceneController<String> build() =>
      GraphSceneController<String>(vsync: _TestVSync());

  tearDown(() => controller.dispose());

  Future<void> finish(WidgetTester tester) async {
    // Past kMaxTransition, then a settle frame, then the post-frame prune.
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    controller.advancePoses();
    await tester.pump();
    await tester.pump();
    controller.camera.stop();
    controller.clock.run(false);
    await tester.pump();
  }

  testWidgets('a persisting key keeps its pose and never fades', (
    tester,
  ) async {
    controller = build();
    controller.setScene(_scene(<String>['a', 'b']), layout: _line);
    await finish(tester);

    final poseOfA = controller.poses[0];
    expect(poseOfA.position.x, 0);

    controller.setScene(_scene(<String>['a', 'c']), layout: _lineShifted);
    controller.advancePoses();

    // Continuity: 'a' starts the new transition exactly where it stood.
    expect((controller.poses[0].position - poseOfA.position).length, 0);
    expect(controller.fadeOf(1), 1, reason: 'a persisted, never fades');
    // 'c' is new: enters faded out.
    expect(controller.fadeOf(2), 0);
    await finish(tester);

    expect(controller.poses[0].position.y, 500);
    expect(controller.fadeOf(2), 1);
  });

  testWidgets('vanished nodes exit at the tail, then are pruned', (
    tester,
  ) async {
    controller = build();
    controller.setScene(_scene(<String>['a', 'b', 'c']), layout: _line);
    await finish(tester);

    controller.setScene(_scene(<String>['a']), layout: _line);
    controller.advancePoses();

    // Mid-transition: b and c still render, after the live nodes.
    expect(controller.renderNodes.map((n) => n.key), <String>['a', 'b', 'c']);
    expect(controller.liveCount, 1);
    expect(controller.poses, hasLength(3));

    await finish(tester);

    // Pruned: only the live node remains, arrays truncated with it.
    expect(controller.renderNodes.map((n) => n.key), <String>['a']);
    expect(controller.poses, hasLength(1));
  });

  testWidgets('a retargeting setScene supersedes the pending prune', (
    tester,
  ) async {
    controller = build();
    controller.setScene(_scene(<String>['a', 'b']), layout: _line);
    await finish(tester);

    // b starts exiting...
    controller.setScene(_scene(<String>['a']), layout: _line);
    await tester.pump(const Duration(milliseconds: 300));
    controller.advancePoses();

    // ...but comes back before the exit finishes.
    controller.setScene(_scene(<String>['a', 'b']), layout: _line);
    await finish(tester);

    expect(controller.renderNodes.map((n) => n.key), <String>['a', 'b']);
    expect(controller.fadeOf(2), 1);
  });

  testWidgets('selection follows the key, and releases when it vanishes', (
    tester,
  ) async {
    controller = build();
    controller.setScene(_scene(<String>['a', 'b', 'c']), layout: _line);
    await finish(tester);

    controller.selectNode(2);
    expect(controller.selectedKey, 'b');

    // b moves to a different index: id changes, key does not.
    controller.setScene(_scene(<String>['b', 'a', 'c']), layout: _line);
    expect(controller.selectedKey, 'b');
    expect(controller.selectedId, 1);
    await finish(tester);

    // b vanishes: selection released.
    controller.setScene(_scene(<String>['a', 'c']), layout: _line);
    expect(controller.selectedKey, isNull);
    expect(controller.selectedId, isNull);
    await finish(tester);
  });

  testWidgets('taps on exiting nodes are ignored', (tester) async {
    controller = build();
    controller.setScene(_scene(<String>['a', 'b']), layout: _line);
    await finish(tester);

    controller.setScene(_scene(<String>['a']), layout: _line);
    // id 2 is the exiting 'b'.
    controller.tapNode(2);
    expect(controller.selectedKey, isNull);
    await finish(tester);
  });

  testWidgets('a hover timer survives a scene change without going stale', (
    tester,
  ) async {
    controller = build();
    controller.setScene(_scene(<String>['a', 'b']), layout: _line);
    await finish(tester);

    controller.hoverNode(2, true); // hover b; focus lands after 500ms
    // Scene reshuffles before the timer fires; b's id changes 2 -> 1.
    controller.setScene(_scene(<String>['b', 'a']), layout: _line);
    await tester.pump(const Duration(milliseconds: 600));

    expect(controller.focusKey, 'b', reason: 'focus resolved by key');
    expect(controller.focusId, 1, reason: 'and maps to the NEW index');
    await finish(tester);
  });

  testWidgets('emphasis lights the focus and its neighbours', (tester) async {
    controller = build();
    controller.setScene(
      _scene(<String>['a', 'b', 'c', 'd'], <SceneEdge>[
        const SceneEdge(1, 2),
        const SceneEdge(3, 1),
      ]),
      layout: _line,
    );
    await finish(tester);

    expect(controller.emphasisOf(1), CardEmphasis.normal);

    controller.selectNode(1);
    expect(controller.emphasisOf(1), CardEmphasis.selected);
    expect(controller.emphasisOf(2), CardEmphasis.highlighted);
    expect(controller.emphasisOf(3), CardEmphasis.highlighted);
    expect(controller.emphasisOf(4), CardEmphasis.inactive);
    expect(controller.glowFor(1), isTrue);
    expect(controller.glowFor(2), isFalse);

    final links = controller.linksOf(1);
    expect(links.outgoing, <int>[2]);
    expect(links.incoming, <int>[3]);
    await finish(tester);
  });

  testWidgets('highlightKeys light nodes without a selection', (tester) async {
    controller = build();
    controller.setScene(_scene(<String>['a', 'b', 'c']), layout: _line);
    await finish(tester);

    controller.highlightKeys = <String>{'a', 'c'};
    expect(controller.emphasisOf(1), CardEmphasis.highlighted);
    expect(controller.emphasisOf(2), CardEmphasis.inactive);
    expect(controller.emphasisOf(3), CardEmphasis.highlighted);

    controller.highlightKeys = const <String>{};
    expect(controller.emphasisOf(2), CardEmphasis.normal);
    await finish(tester);
  });

  testWidgets('alphaOf is stable for a key across scene rebuilds', (
    tester,
  ) async {
    controller = build();
    controller.setScene(_scene(<String>['a', 'b']), layout: _line);
    final alphaOfA = controller.alphaOf(0);
    final alphaOfB = controller.alphaOf(1);
    await finish(tester);

    // 'b' moves to index 0: its alpha travels with the key, and the slot's
    // new occupant gets its own.
    controller.setScene(_scene(<String>['b', 'c']), layout: _line);
    expect(controller.alphaOf(0), alphaOfB);
    expect(controller.alphaOf(0), GraphSceneController.alphaForKey('b'));
    expect(controller.alphaOf(1), isNot(alphaOfA));
    await finish(tester);
  });
}
