import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph3d/graph3d.dart';
import 'package:triplecheck3d/data/models.dart';
import 'package:triplecheck3d/graph_controller.dart';
import 'package:triplecheck3d/review/review_store.dart';

class _TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

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

  Future<void> quiesce(WidgetTester tester) async {
    controller.scene.transition.stop();
    controller.scene.camera.stop();
    controller.scene.clock.run(false);
    await tester.pump();
  }

  testWidgets('links are hidden in table view and pruned to the selection', (
    tester,
  ) async {
    controller = build();
    expect(controller.layout, TcLayout.table);
    expect(controller.visibleEdges().edges, isEmpty,
        reason: 'table hides links');

    controller.setLayout(TcLayout.grid);
    // The self-link is included in the scene but filters out on focus; the
    // full set draws when nothing is focused.
    expect(controller.visibleEdges().edges, hasLength(3));

    controller.scene.selectNode(2);
    final visible = controller.visibleEdges().edges;
    expect(visible, hasLength(1));
    expect(visible.single.from, 1);
    expect(visible.single.to, 2);

    controller.toggleLinks();
    expect(controller.visibleEdges().edges, isEmpty);
    await quiesce(tester);
  });

  testWidgets('a search with one hit flies straight to it', (tester) async {
    controller = build();
    controller.search('license:MIT');
    expect(controller.searchResults, hasLength(1));
    expect(controller.scene.selectedId, 2);
    expect(controller.searchSummary, contains('Found 1 file'));
    await quiesce(tester);
  });

  testWidgets('a search with many hits highlights them all', (tester) async {
    controller = build();
    controller.search('license:GPL');
    expect(controller.searchResults, hasLength(3));
    expect(controller.scene.selectedId, isNull);
    expect(controller.scene.emphasisOf(1), CardEmphasis.highlighted);
    expect(controller.scene.emphasisOf(2), CardEmphasis.inactive);

    controller.search('   ');
    expect(controller.scene.emphasisOf(2), CardEmphasis.normal);
    await quiesce(tester);
  });

  testWidgets('the details panel data follows the focus', (tester) async {
    controller = build();
    controller.selectNode(1);
    expect(controller.focusId, 1);
    expect(controller.focusLinks.outgoing, <int>[2]);
    expect(controller.focusLinks.incoming, <int>[3]);
    await quiesce(tester);
  });
}
