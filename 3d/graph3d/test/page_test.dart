import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph3d/data/models.dart';
import 'package:graph3d/graph_page.dart';
import 'package:graph3d/review/review_store.dart';
import 'package:graph3d/scene/layouts.dart';
import 'package:graph3d/scene/orbit_camera.dart';
import 'package:graph3d/scene/projection.dart';
import 'package:graph3d/widgets/node_card.dart';

class _TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

GraphData _tinyGraph() => GraphData(
  project: const ProjectInfo(
    name: 'T',
    licence: '',
    conflicts: '',
    licences: <String>[],
    complete: '',
    files: 2,
    linesOfCode: 0,
    summary: 'PROJECT SUMMARY',
  ),
  nodes: <GraphNode>[
    for (var i = 1; i <= 2; i++)
      GraphNode(
        id: i,
        sourceId: i,
        symbol: 'n$i',
        name: 'file$i.java',
        license: 'MIT',
        column: i * 3, // three columns apart: no overlap on screen
        row: 1,
        tag: 'source',
        riskyLicense: false,
        hasCopyright: false,
      ),
  ],
  links: const <GraphLink>[GraphLink(1, 2)],
  details: <FileDetail>[
    for (var i = 1; i <= 2; i++)
      FileDetail(
        id: i,
        sourceId: i,
        sha1: 'sha$i',
        size: 10,
        linesOfCode: 5,
        license: 'MIT',
        copyright: '',
        path: './src/file$i.java',
      ),
  ],
  coders: const <Coder>[],
  matches: const <MatchGroup>[],
  defaultReviews: const <String, String>{},
);

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: GraphPage(
          data: _tinyGraph(),
          reviewStore: ReviewStore.inMemory(const <String, String>{}),
        ),
      ),
    );
    // Fly-in transition plus the initial camera framing.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 4));
  }

  /// The live overlay renders the selected and hovered cards as NodeCard
  /// widgets; the crowd is a painter. So NodeCard presence tracks selection.
  Finder liveCards() => find.byType(NodeCard);

  /// Where node 1 lands on screen, computed with the same scene code the page
  /// uses: build the layout, frame the camera the same way, project.
  Offset node1OnScreen() {
    const size = Size(1200, 800);
    final geometry = buildLayout(GraphLayout.table, _tinyGraph().nodes);
    final camera = OrbitCamera(vsync: _TestVSync())
      ..aspect = size.width / size.height
      ..frame(
        geometry.center,
        geometry.radius,
        halfExtent: geometry.halfExtent,
        durationMs: 0,
      );
    final projector = Projector(
      view: camera.viewMatrix,
      perspective: perspectiveFor(size.height),
    );
    final projected = projector.project(geometry.poses.first.position)!;
    camera.dispose();
    return projected.screen + Offset(size.width / 2, size.height / 2);
  }

  testWidgets('tapping a card through the crowd painter selects it', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(liveCards(), findsNothing);
    expect(find.text('Details'), findsOneWidget);

    await tester.tapAt(node1OnScreen());
    // The tap recognizer waits out the double-tap window before firing.
    await tester.pump(const Duration(milliseconds: 400));
    expect(liveCards(), findsOneWidget, reason: 'the tap picked the card');

    // The details panel now shows the picked file, not the project.
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Details'), findsNothing);

    // Tapping the same card again (now under the live overlay) lets go.
    final cardCentre = tester.getCenter(liveCards().first);
    await tester.tapAt(cardCentre);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Details'), findsOneWidget);
    expect(liveCards(), findsNothing);
  });

  testWidgets('hovering a card raises it live, leaving lowers it', (
    tester,
  ) async {
    await pumpPage(tester);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await gesture.moveTo(node1OnScreen());
    await tester.pump();
    expect(
      liveCards(),
      findsOneWidget,
      reason: 'hover raises the card into the overlay',
    );

    // Off to a corner: the hover ends and the overlay empties.
    await gesture.moveTo(const Offset(2, 2));
    await tester.pump(const Duration(seconds: 1));
    expect(liveCards(), findsNothing);
  });
}
