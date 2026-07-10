import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Quaternion, Vector3;

import 'data/models.dart';
import 'review/review_store.dart';
import 'scene/layouts.dart';
import 'scene/orbit_camera.dart';
import 'scene/pose.dart';
import 'search/query.dart';
import 'widgets/link_layer.dart';
import 'widgets/node_card.dart';

/// Each card takes between one and two times this to reach its new layout.
const Duration kBaseTransition = Duration(milliseconds: 1200);
const Duration kMaxTransition = Duration(milliseconds: 2400);

/// How long the pointer must rest on a card before its details are shown.
const Duration kHoverDelay = Duration(milliseconds: 500);

/// A free-running millisecond clock, so the crawling balls advance without
/// forcing the 426-card stack to rebuild.
class LinkClock extends ChangeNotifier {
  LinkClock(TickerProvider vsync) {
    _ticker = vsync.createTicker((elapsed) {
      ms = elapsed.inMicroseconds / 1000;
      notifyListeners();
    });
  }

  late final Ticker _ticker;
  double ms = 0;

  void run(bool active) {
    if (active == _ticker.isActive) return;
    if (active) {
      _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// Everything the graph view needs to know: what is laid out where, what is
/// selected, what is highlighted, and what the panels are showing.
class GraphController extends ChangeNotifier {
  GraphController({
    required this.data,
    required this.reviewStore,
    required TickerProvider vsync,
  }) {
    camera = OrbitCamera(vsync: vsync);
    clock = LinkClock(vsync);

    final random = math.Random(7);
    _alphas = List<double>.generate(
      data.nodeCount,
      (_) => random.nextDouble() * 0.5 + 0.25,
    );
    _crawlPeriods = buildCrawlPeriods(data.links.length, random);
    _durationsMs = List<double>.filled(data.nodeCount, 0);

    _geometry = buildLayout(_layout, data.nodes);
    // Cards fly in from nowhere in particular, as the original's do.
    _start = List<Pose>.generate(
      data.nodeCount,
      (_) => Pose(
        Vector3(
          random.nextDouble() * 4000 - 2000,
          random.nextDouble() * 4000 - 2000,
          random.nextDouble() * 4000 - 2000,
        ),
        Quaternion.identity(),
      ),
    );
    _current = List<Pose>.of(_start);

    transition = AnimationController(vsync: vsync, duration: kMaxTransition);
    _randomizeDurations(random);
    transition.forward(from: 0);

    // Frame the table before the first frame is drawn, not over 1.5 seconds.
    reframe(immediate: true);
    _updateClock();
  }

  final GraphData data;
  final ReviewStore reviewStore;

  late final OrbitCamera camera;
  late final LinkClock clock;
  late final AnimationController transition;

  final math.Random _durationRandom = math.Random(11);

  late final List<double> _alphas;
  late final List<double> _crawlPeriods;
  late final List<double> _durationsMs;

  GraphLayout _layout = GraphLayout.table;
  late LayoutGeometry _geometry;
  late List<Pose> _start;
  late List<Pose> _current;

  int? _selectedId;
  int? _hoveredId;
  int? _hoverInfoId;
  Timer? _hoverTimer;
  bool _dragging = false;

  Set<int> _foundIds = const <int>{};
  List<SearchHit> _searchResults = const <SearchHit>[];
  String _searchSummary = '';

  bool _showLinks = true;
  bool _showInfo = true;
  bool _showSearch = false;
  bool _showReview = false;

  GraphLayout get layout => _layout;
  List<Pose> get poses => _current;
  double alphaOf(int index) => _alphas[index];

  int? get selectedId => _selectedId;
  int? get hoveredId => _hoveredId;

  /// The node whose details the panel shows: whatever the pointer is resting
  /// on, else whatever was last clicked.
  int? get focusId => _hoverInfoId ?? _selectedId;

  bool get showLinks => _showLinks;
  bool get showInfo => _showInfo;
  bool get showSearch => _showSearch;
  bool get showReview => _showReview;

  List<SearchHit> get searchResults => _searchResults;
  String get searchSummary => _searchSummary;

  /// Ids linked to [focusId], separated by direction, for the details panel.
  ({List<int> incoming, List<int> outgoing}) get focusLinks {
    final id = focusId;
    if (id == null) return (incoming: const <int>[], outgoing: const <int>[]);
    final incoming = <int>[];
    final outgoing = <int>[];
    for (final link in data.links) {
      if (link.isSelfLink) continue;
      if (link.from == id) outgoing.add(link.to);
      if (link.to == id) incoming.add(link.from);
    }
    return (incoming: incoming, outgoing: outgoing);
  }

  /// Ids drawn normally. Everything else is dimmed. With nothing selected and
  /// nothing found, that is the whole graph.
  ///
  /// Search hits stay lit even once a node is picked, so you can still see
  /// where the rest of the result set sits.
  Set<int> get _activeIds {
    final id = focusId;
    if (id != null) {
      final links = focusLinks;
      return <int>{id, ...links.incoming, ...links.outgoing, ..._foundIds};
    }
    return _foundIds;
  }

  /// Links drawn as lines. Suppressed in table mode, where the original hides
  /// them: the flat grid would be a cat's cradle.
  ({List<GraphLink> links, List<double> periods}) get visibleLinks {
    if (!_showLinks || _layout == GraphLayout.table) {
      return (links: const <GraphLink>[], periods: const <double>[]);
    }
    final id = focusId;
    final links = <GraphLink>[];
    final periods = <double>[];
    for (var i = 0; i < data.links.length; i++) {
      final link = data.links[i];
      if (link.isSelfLink) continue;
      if (id != null && !link.touches(id)) continue;
      links.add(link);
      periods.add(_crawlPeriods[i]);
    }
    return (links: links, periods: periods);
  }

  CardEmphasis emphasisOf(int id) {
    if (id == _selectedId) return CardEmphasis.selected;
    final active = _activeIds;
    if (active.isEmpty) return CardEmphasis.normal;
    return active.contains(id) ? CardEmphasis.highlighted : CardEmphasis.inactive;
  }

  /// Whether this card carries the cyan glow.
  ///
  /// The glow is a blur, and Flutter cannot cache blurs under a perspective
  /// transform: measured on a low-end phone, each glowing card costs about
  /// 0.74ms of raster time, every frame. So it marks the one card the user
  /// picked — the hovered card gets one too, from the card itself. Everything
  /// else that is merely related settles for a brighter border.
  bool glowFor(int id) => id == _selectedId;

  // --- layout ---------------------------------------------------------------

  void _randomizeDurations(math.Random random) {
    final base = kBaseTransition.inMilliseconds.toDouble();
    for (var i = 0; i < _durationsMs.length; i++) {
      _durationsMs[i] = base + random.nextDouble() * base;
    }
  }

  void setLayout(GraphLayout layout) {
    if (layout == _layout) return;
    _layout = layout;
    _start = List<Pose>.of(_current);
    _geometry = buildLayout(layout, data.nodes);
    _randomizeDurations(_durationRandom);
    transition.forward(from: 0);
    reframe();
    _updateClock();
    notifyListeners();
  }

  /// Backs the camera off until the whole layout fits the current viewport.
  /// The page calls this once the first layout pass has told the camera its
  /// aspect ratio, and again whenever the layout changes.
  void reframe({bool immediate = false}) {
    camera.frame(
      _geometry.center,
      _geometry.radius,
      halfExtent: _geometry.halfExtent,
      durationMs: immediate ? 0 : 1500,
    );
  }

  /// Advances every card towards its target at its own pace. Called once per
  /// frame from the render layer, before the poses are read.
  void advancePoses() {
    if (transition.isCompleted) return;
    final elapsedMs = transition.value * kMaxTransition.inMilliseconds;
    for (var i = 0; i < _current.length; i++) {
      final t = (elapsedMs / _durationsMs[i]).clamp(0.0, 1.0);
      _current[i] = lerpPose(
        _start[i],
        _geometry.poses[i],
        exponentialInOut(t),
      );
    }
  }

  // --- selection ------------------------------------------------------------

  void selectNode(int id) {
    _hoverTimer?.cancel();
    _hoverInfoId = null;
    _selectedId = id;
    // Fly to the card's final resting place, not to wherever it is mid-flight.
    camera.flyToPose(_geometry.poses[id - 1]);
    _updateClock();
    notifyListeners();
  }

  /// What a tap on a card does: pick it, or let go of it if it was already the
  /// current one. Double-tapping the background clears the selection too, but
  /// on a crowded graph there may be no background left to hit.
  void tapNode(int id) {
    if (_selectedId == id) {
      clearSelection();
    } else {
      selectNode(id);
    }
  }

  /// Double-clicking the background: back to the project overview.
  void clearSelection() {
    _hoverTimer?.cancel();
    _hoverInfoId = null;
    _selectedId = null;
    _updateClock();
    notifyListeners();
  }

  void hoverNode(int id, bool entered) {
    if (_dragging) return;
    _hoverTimer?.cancel();

    if (entered) {
      if (_hoveredId == id && _hoverInfoId == id) return;
      _hoveredId = id;
      notifyListeners();
      _hoverTimer = Timer(kHoverDelay, () {
        _hoverInfoId = id;
        _updateClock();
        notifyListeners();
      });
    } else {
      if (_hoveredId != id) return;
      _hoveredId = null;
      notifyListeners();
      _hoverTimer = Timer(kHoverDelay, () {
        _hoverInfoId = null;
        _updateClock();
        notifyListeners();
      });
    }
  }

  /// A drag suppresses hover, so the details panel does not flicker through
  /// every card the pointer sweeps across.
  set dragging(bool value) {
    if (_dragging == value) return;
    _dragging = value;
    if (value) {
      _hoverTimer?.cancel();
      if (_hoveredId != null || _hoverInfoId != null) {
        _hoveredId = null;
        _hoverInfoId = null;
        notifyListeners();
      }
    }
  }

  // --- panels ---------------------------------------------------------------

  void toggleLinks() {
    _showLinks = !_showLinks;
    _updateClock();
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

  void _updateClock() {
    clock.run(visibleLinks.links.isNotEmpty);
  }

  // --- search ---------------------------------------------------------------

  void search(String text) {
    final query = text.trim();
    if (query.isEmpty) {
      _searchResults = const <SearchHit>[];
      _searchSummary = '';
      _foundIds = const <int>{};
      notifyListeners();
      return;
    }

    final hits = query.contains('review')
        ? findReviewedFiles(data, reviewStore.reviewedPaths)
        : runSearch(data, parseSearchText(query));

    _searchResults = hits;
    _foundIds = hits.map((hit) => hit.id).toSet();
    _searchSummary = _summarize(hits);

    if (hits.length == 1) {
      selectNode(hits.single.id);
      return;
    }

    _selectedId = null;
    _hoverInfoId = null;
    reframe();
    _updateClock();
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
    _hoverTimer?.cancel();
    transition.dispose();
    clock.dispose();
    camera.dispose();
    super.dispose();
  }
}
