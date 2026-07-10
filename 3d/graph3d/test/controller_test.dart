import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph3d/data/models.dart';
import 'package:graph3d/graph_controller.dart';
import 'package:graph3d/review/review_store.dart';
import 'package:graph3d/scene/layouts.dart';
import 'package:graph3d/widgets/node_card.dart';

class _TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

/// Four files: 1 -> 2, 3 -> 1, and 4 linked to nothing. Node 4 also carries a
/// self-link, which the original draws nothing for.
GraphData _graph() => GraphData(
  project: const ProjectInfo(
    name: 'T',
    licence: '',
    conflicts: '',
    licences: <String>[],
    complete: '',
    files: 4,
    linesOfCode: 0,
    summary: '',
  ),
  nodes: <GraphNode>[
    for (var i = 1; i <= 4; i++)
      GraphNode(
        id: i,
        sourceId: i,
        symbol: 'n$i',
        name: 'file$i',
        license: i == 2 ? 'MIT' : 'GPL-3.0',
        column: i,
        row: 1,
        tag: 'source',
        riskyLicense: false,
        hasCopyright: false,
      ),
  ],
  links: const <GraphLink>[GraphLink(1, 2), GraphLink(3, 1), GraphLink(4, 4)],
  details: <FileDetail>[
    for (var i = 1; i <= 4; i++)
      FileDetail(
        id: i,
        sourceId: i,
        sha1: 'sha$i',
        size: 100,
        linesOfCode: 10,
        license: i == 2 ? 'MIT' : 'GPL-3.0',
        copyright: '',
        path: './src/file$i.java',
      ),
  ],
  coders: const <Coder>[],
  matches: const <MatchGroup>[],
  defaultReviews: const <String, String>{},
);

void main() {
  late GraphController controller;

  GraphController build() => GraphController(
    data: _graph(),
    reviewStore: ReviewStore.inMemory(const <String, String>{}),
    vsync: _TestVSync(),
  );

  tearDown(() => controller.dispose());

  /// The layout transition, the camera and the link clock all drive tickers.
  /// Leaving one scheduled fails the test binding's end-of-test check.
  Future<void> quiesce(WidgetTester tester) async {
    controller.transition.stop();
    controller.camera.stop();
    controller.clock.run(false);
    await tester.pump();
  }

  testWidgets('nothing is selected, so nothing is dimmed', (tester) async {
    controller = build();
    for (var id = 1; id <= 4; id++) {
      expect(controller.emphasisOf(id), CardEmphasis.normal);
      expect(controller.glowFor(id), isFalse);
    }
    expect(controller.focusId, isNull);
    await quiesce(tester);
  });

  testWidgets('selecting a node lights it and its neighbours', (tester) async {
    controller = build();
    controller.selectNode(1);

    expect(controller.focusId, 1);
    expect(controller.emphasisOf(1), CardEmphasis.selected);
    expect(controller.emphasisOf(2), CardEmphasis.highlighted);
    expect(controller.emphasisOf(3), CardEmphasis.highlighted);
    expect(controller.emphasisOf(4), CardEmphasis.inactive);

    // The glow is a per-frame blur, so only the picked card gets one; the
    // cards it links to make do with a brighter border.
    expect(controller.glowFor(1), isTrue);
    expect(controller.glowFor(2), isFalse);
    expect(controller.glowFor(4), isFalse);

    final links = controller.focusLinks;
    expect(links.outgoing, <int>[2]);
    expect(links.incoming, <int>[3]);
    await quiesce(tester);
  });

  testWidgets('tapping the current node lets go of it', (tester) async {
    controller = build();
    controller.tapNode(2);
    expect(controller.selectedId, 2);
    controller.tapNode(2);
    expect(controller.selectedId, isNull);
    expect(controller.emphasisOf(4), CardEmphasis.normal);
    await quiesce(tester);
  });

  testWidgets('links are hidden in table view and pruned to the selection', (
    tester,
  ) async {
    controller = build();
    expect(controller.layout, GraphLayout.table);
    expect(controller.visibleLinks.links, isEmpty, reason: 'table hides links');

    controller.setLayout(GraphLayout.grid);
    // The self-link on node 4 is never drawn.
    expect(controller.visibleLinks.links, hasLength(2));
    expect(controller.visibleLinks.periods, hasLength(2));

    controller.selectNode(2);
    final visible = controller.visibleLinks.links;
    expect(visible, hasLength(1));
    expect(visible.single.from, 1);
    expect(visible.single.to, 2);

    controller.toggleLinks();
    expect(controller.visibleLinks.links, isEmpty);
    await quiesce(tester);
  });

  testWidgets('a search with one hit flies straight to it', (tester) async {
    controller = build();
    controller.search('license:MIT');

    expect(controller.searchResults, hasLength(1));
    expect(controller.selectedId, 2);
    expect(controller.searchSummary, contains('Found 1 file'));
    await quiesce(tester);
  });

  testWidgets('a search with many hits lights them all and selects none', (
    tester,
  ) async {
    controller = build();
    controller.search('license:GPL');

    expect(controller.searchResults, hasLength(3));
    expect(controller.selectedId, isNull);
    expect(controller.emphasisOf(1), CardEmphasis.highlighted);
    expect(controller.emphasisOf(2), CardEmphasis.inactive);
    expect(controller.searchSummary, contains('Found 3 files'));

    // Picking one of the hits keeps the others lit, so the result set stays
    // visible in the graph.
    controller.selectNode(1);
    expect(controller.emphasisOf(3), CardEmphasis.highlighted);
    expect(controller.emphasisOf(4), CardEmphasis.highlighted);
    await quiesce(tester);
  });

  testWidgets('an empty query puts the graph back the way it was', (
    tester,
  ) async {
    controller = build();
    controller.search('license:GPL');
    controller.search('   ');

    expect(controller.searchResults, isEmpty);
    expect(controller.searchSummary, isEmpty);
    for (var id = 1; id <= 4; id++) {
      expect(controller.emphasisOf(id), CardEmphasis.normal);
    }
    await quiesce(tester);
  });
}
