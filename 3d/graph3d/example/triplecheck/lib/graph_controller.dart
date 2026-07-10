import 'package:flutter/widgets.dart';
import 'package:graph3d/graph3d.dart';

import 'data/models.dart';
import 'review/review_store.dart';
import 'search/query.dart';

/// The layouts the menu offers, mapped onto the engine's strategies.
enum TcLayout {
  table,
  helix,
  grid;

  String get label => name.toUpperCase();

  LayoutStrategy<GraphNode> get strategy => switch (this) {
    TcLayout.table => tableLayout(cell: (n) => (n.data.column, n.data.row)),
    TcLayout.helix => helixLayout(),
    TcLayout.grid => gridLayout(),
  };
}

/// The TripleCheck app around the engine: search, review, layout menu, and
/// which links are worth drawing.
class GraphController extends ChangeNotifier {
  GraphController({
    required this.data,
    required this.reviewStore,
    required TickerProvider vsync,
  }) : scene = GraphSceneController<GraphNode>(vsync: vsync) {
    scene.setScene(
      GraphScene<GraphNode>(
        nodes: <SceneNode<GraphNode>>[
          for (final node in data.nodes)
            SceneNode<GraphNode>(key: 'tc:${node.id}', data: node),
        ],
        edges: <SceneEdge>[
          for (final link in data.links) SceneEdge(link.from, link.to),
        ],
      ),
      layout: _layout.strategy,
    );
    // Panels listen to this controller; selection and hover live in the
    // scene, so relay its notifications.
    scene.addListener(notifyListeners);
  }

  final GraphData data;
  final ReviewStore reviewStore;
  final GraphSceneController<GraphNode> scene;

  TcLayout _layout = TcLayout.table;
  bool _showLinks = true;
  bool _showInfo = true;
  bool _showSearch = false;
  bool _showReview = false;

  List<SearchHit> _searchResults = const <SearchHit>[];
  String _searchSummary = '';

  TcLayout get layout => _layout;
  bool get showLinks => _showLinks;
  bool get showInfo => _showInfo;
  bool get showSearch => _showSearch;
  bool get showReview => _showReview;

  List<SearchHit> get searchResults => _searchResults;
  String get searchSummary => _searchSummary;

  /// The node the panels describe. Node ids equal scene ids: the scene is
  /// built in dataset order and never changes membership.
  int? get focusId => scene.focusId;

  /// Ids linked to the focus, for the details panel.
  ({List<int> incoming, List<int> outgoing}) get focusLinks {
    final focus = scene.focusId;
    if (focus == null) return (incoming: const <int>[], outgoing: const <int>[]);
    return scene.linksOf(focus);
  }

  void selectNode(int id) => scene.selectNode(id);

  void setLayout(TcLayout layout) {
    if (layout == _layout) return;
    _layout = layout;
    scene.setLayout(layout.strategy);
    notifyListeners();
  }

  /// Links drawn as lines. Suppressed in table mode, where the original hides
  /// them: the flat grid would be a cat's cradle. With a node in focus, only
  /// its own links draw.
  ({List<SceneEdge> edges, List<double> periods}) visibleEdges() {
    if (!_showLinks || _layout == TcLayout.table) {
      return (edges: const <SceneEdge>[], periods: const <double>[]);
    }
    final focus = scene.focusId;
    if (focus == null) {
      return (edges: scene.edges, periods: scene.crawlPeriods);
    }
    final edges = <SceneEdge>[];
    final periods = <double>[];
    for (var i = 0; i < scene.edges.length; i++) {
      final edge = scene.edges[i];
      if (edge.isSelfEdge || !edge.touches(focus)) continue;
      edges.add(edge);
      periods.add(scene.crawlPeriods[i]);
    }
    return (edges: edges, periods: periods);
  }

  void toggleLinks() {
    _showLinks = !_showLinks;
    notifyListeners();
  }

  void toggleInfo() {
    _showInfo = !_showInfo;
    notifyListeners();
  }

  void toggleSearch() {
    _showSearch = !_showSearch;
    notifyListeners();
  }

  void toggleReview() {
    _showReview = !_showReview;
    notifyListeners();
  }

  void search(String text) {
    final query = text.trim();
    if (query.isEmpty) {
      _searchResults = const <SearchHit>[];
      _searchSummary = '';
      scene.highlightKeys = const <String>{};
      notifyListeners();
      return;
    }

    final hits = query.contains('review')
        ? findReviewedFiles(data, reviewStore.reviewedPaths)
        : runSearch(data, parseSearchText(query));

    _searchResults = hits;
    _searchSummary = _summarize(hits);
    scene.highlightKeys = <String>{for (final hit in hits) 'tc:${hit.id}'};

    if (hits.length == 1) {
      scene.selectNode(hits.single.id);
    } else {
      scene.clearSelection();
      scene.reframe();
    }
    notifyListeners();
  }

  String _summarize(List<SearchHit> hits) {
    if (hits.isEmpty) return 'No matches found';
    var bytes = 0;
    var loc = 0;
    for (final hit in hits) {
      final detail = data.detailById(hit.id);
      bytes += detail.size;
      loc += detail.linesOfCode;
    }
    final buffer = StringBuffer(
      'Found ${hits.length} ${hits.length == 1 ? 'file' : 'files'}',
    );
    if (bytes > 0) {
      buffer.write(' (sized in ${formatBytes(bytes)}');
      if (loc > 0) buffer.write(' with $loc LOC');
      buffer.write(')');
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    scene.dispose();
    super.dispose();
  }
}
