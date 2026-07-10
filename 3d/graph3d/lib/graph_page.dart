import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/models.dart';
import 'graph_controller.dart';
import 'review/review_store.dart';
import 'scene/card_bakery.dart';
import 'scene/crowd_painter.dart';
import 'scene/layouts.dart';
import 'scene/projection.dart';
import 'widgets/info_panel.dart';
import 'widgets/link_layer.dart';
import 'widgets/node_card.dart';
import 'widgets/panel.dart';
import 'widgets/review_frame.dart';
import 'widgets/review_panel.dart';
import 'widgets/search_panel.dart';

/// Below this the right-hand column would crowd the graph off the screen, so
/// the panels move underneath it.
const double kWidePanelBreakpoint = 900;

class GraphPage extends StatefulWidget {
  const GraphPage({super.key, required this.data, required this.reviewStore});

  final GraphData data;
  final ReviewStore reviewStore;

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> with TickerProviderStateMixin {
  late final GraphController _controller;
  late final AnimationController _frameReveal;
  late final CardBakery _bakery;

  MatchFile? _reviewFile;
  double _viewportHeight = 1;
  double _lastScale = 1;
  Size _sceneSize = const Size(1, 1);
  int? _lastHoverId;

  /// The controller frames the graph before it knows the window's shape. Once
  /// the first layout pass has, re-frame so the whole table actually fits.
  bool _framed = false;

  @override
  void initState() {
    super.initState();
    _controller = GraphController(
      data: widget.data,
      reviewStore: widget.reviewStore,
      vsync: this,
    );
    _bakery = CardBakery.bake(
      widget.data.nodes,
      List<double>.generate(widget.data.nodeCount, _controller.alphaOf),
    );
    _frameReveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _frameReveal.dispose();
    _bakery.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openReviewFile(MatchFile file) {
    setState(() => _reviewFile = file);
    _frameReveal.forward(from: 0);
  }

  Future<void> _closeReviewFile() async {
    await _frameReveal.reverse();
    if (mounted) setState(() => _reviewFile = null);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _controller.camera.zoomBy(math.exp(event.scrollDelta.dy * 0.001));
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastScale = 1;
    _controller.dragging = true;
    _controller.camera.stop();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2) {
      final step = details.scale / _lastScale;
      _lastScale = details.scale;
      if (step > 0) _controller.camera.zoomBy(1 / step);
      _controller.camera.pan(
        details.focalPointDelta.dx,
        details.focalPointDelta.dy,
        _viewportHeight,
      );
    } else {
      _controller.camera.rotate(
        details.focalPointDelta.dx,
        details.focalPointDelta.dy,
        _viewportHeight,
      );
    }
  }

  void _onScaleEnd(ScaleEndDetails details) => _controller.dragging = false;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kWidePanelBreakpoint;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape):
            _controller.clearSelection,
      },
      child: Focus(autofocus: true, child: _buildScaffold(wide)),
    );
  }

  Widget _buildScaffold(bool wide) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: _buildScene()),
          if (wide) ...<Widget>[
            Positioned(
              top: 10,
              right: 20,
              width: 334,
              bottom: 90,
              child: _Panels(
                controller: _controller,
                onOpenReviewFile: _openReviewFile,
                bottomAnchored: false,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: SafeArea(
                  top: false,
                  child: _Menu(controller: _controller),
                ),
              ),
            ),
          ] else
            // On a phone the panels and the buttons share the bottom of the
            // screen, so they stack rather than overlap. The menu wraps to two
            // rows in portrait, and its height is not known in advance.
            Positioned(
              left: 8,
              right: 8,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                      ),
                      child: _Panels(
                        controller: _controller,
                        onOpenReviewFile: _openReviewFile,
                        bottomAnchored: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: _Menu(controller: _controller),
                    ),
                  ],
                ),
              ),
            ),
          if (_reviewFile != null)
            Positioned.fill(
              child: FadeTransition(
                opacity: _frameReveal,
                child: ScaleTransition(
                  // The original zooms a bordered box out from the centre.
                  scale: CurvedAnimation(
                    parent: _frameReveal,
                    curve: Curves.easeOutExpo,
                  ),
                  child: ReviewFrame(
                    file: _reviewFile!,
                    coders: widget.data.coders,
                    store: widget.reviewStore,
                    onClose: _closeReviewFile,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Projector get _projector => Projector(
    view: _controller.camera.viewMatrix,
    perspective: perspectiveFor(_sceneSize.height),
  );

  /// Ids rendered as live widgets above the baked crowd, back to front. They
  /// are also the ones a pick must test first.
  List<int> get _liveIds => <int>[
    if (_controller.hoveredId != null &&
        _controller.hoveredId != _controller.selectedId)
      _controller.hoveredId!,
    if (_controller.selectedId != null) _controller.selectedId!,
  ];

  int? _pickAt(Offset position) {
    _controller.advancePoses();
    return pickCard(
      poses: _controller.poses,
      projector: _projector,
      size: _sceneSize,
      position: position,
      onTop: _liveIds.reversed,
    );
  }

  void _onTapUp(TapUpDetails details) {
    final id = _pickAt(details.localPosition);
    if (id != null) _controller.tapNode(id);
  }

  void _updateHover(Offset? position) {
    final id = position == null ? null : _pickAt(position);
    if (id == _lastHoverId) return;
    if (_lastHoverId != null) _controller.hoverNode(_lastHoverId!, false);
    if (id != null) _controller.hoverNode(id, true);
    _lastHoverId = id;
  }

  Widget _buildScene() {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: MouseRegion(
        onHover: (event) => _updateHover(event.localPosition),
        onExit: (_) => _updateHover(null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          onTapUp: _onTapUp,
          onDoubleTap: _controller.clearSelection,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _sceneSize = Size(constraints.maxWidth, constraints.maxHeight);
              _viewportHeight = constraints.maxHeight;
              final perspective = perspectiveFor(constraints.maxHeight);
              _controller.camera.aspect =
                  constraints.maxWidth / constraints.maxHeight;

              if (!_framed) {
                _framed = true;
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _controller.reframe(immediate: true),
                );
              }

              final sceneListenable = Listenable.merge(<Listenable>[
                _controller,
                _controller.camera,
                _controller.transition,
              ]);

              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // Behind the cards, as the original's second renderer was.
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: Listenable.merge(<Listenable>[
                        sceneListenable,
                        _controller.clock,
                      ]),
                      builder: (context, _) {
                        _controller.advancePoses();
                        final visible = _controller.visibleLinks;
                        return CustomPaint(
                          painter: LinkPainter(
                            links: visible.links,
                            periods: visible.periods,
                            poses: _controller.poses,
                            projector: Projector(
                              view: _controller.camera.viewMatrix,
                              perspective: perspective,
                            ),
                            clockMs: _controller.clock.ms,
                            repaint: _controller.clock,
                          ),
                        );
                      },
                    ),
                  ),
                  // The crowd: every card as one baked, textured quad.
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: sceneListenable,
                      builder: (context, _) {
                        _controller.advancePoses();
                        return CustomPaint(
                          isComplex: true,
                          painter: CardCrowdPainter(
                            poses: _controller.poses,
                            images: _bakery.images,
                            projector: Projector(
                              view: _controller.camera.viewMatrix,
                              perspective: perspective,
                            ),
                            emphasisOf: _controller.emphasisOf,
                            skip: _liveIds.toSet(),
                          ),
                        );
                      },
                    ),
                  ),
                  // The one or two cards that matter render live: crisp at any
                  // zoom, and free to carry the glow.
                  AnimatedBuilder(
                    animation: sceneListenable,
                    builder: (context, _) {
                      _controller.advancePoses();
                      final projector = Projector(
                        view: _controller.camera.viewMatrix,
                        perspective: perspective,
                      );
                      return Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          for (final id in _liveIds)
                            if (projector.depthOf(
                                  _controller.poses[id - 1].position,
                                ) <=
                                -1)
                              Center(
                                key: ValueKey<int>(id),
                                child: Transform(
                                  transform: projector.cardMatrix(
                                    _controller.poses[id - 1].matrix,
                                  ),
                                  alignment: Alignment.center,
                                  child: IgnorePointer(
                                    child: NodeCard(
                                      node: widget.data.nodes[id - 1],
                                      alpha: _controller.alphaOf(id - 1),
                                      emphasis: _controller.emphasisOf(id),
                                      glow: _controller.glowFor(id),
                                      hovered: _controller.hoveredId == id,
                                      onTap: () {},
                                      onHover: (_) {},
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Panels extends StatelessWidget {
  const _Panels({
    required this.controller,
    required this.onOpenReviewFile,
    required this.bottomAnchored,
  });

  final GraphController controller;
  final ValueChanged<MatchFile> onOpenReviewFile;

  /// On a phone the panels sit above the button bar and grow upwards; on a
  /// desktop they hang from the top of the right-hand column.
  final bool bottomAnchored;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SingleChildScrollView(
        reverse: bottomAnchored,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (controller.showInfo)
              InfoPanel(controller: controller, onClose: controller.toggleInfo),
            if (controller.showSearch)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SearchPanel(
                  controller: controller,
                  onClose: controller.toggleSearch,
                ),
              ),
            if (controller.showReview)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ReviewPanel(
                  controller: controller,
                  onClose: controller.toggleReview,
                  onOpenFile: (_, file) => onOpenReviewFile(file),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.controller});

  final GraphController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final layout in GraphLayout.values)
            GraphButton(
              label: layout.label,
              active: controller.layout == layout,
              onPressed: () => controller.setLayout(layout),
            ),
          GraphButton(
            label: 'LINKS',
            active: controller.showLinks,
            tooltip: controller.layout == GraphLayout.table
                ? 'Links are hidden in table view'
                : null,
            onPressed: controller.toggleLinks,
          ),
          GraphButton(
            label: 'INFO',
            active: controller.showInfo,
            onPressed: controller.toggleInfo,
          ),
          GraphButton(
            label: 'FIND',
            active: controller.showSearch,
            onPressed: controller.toggleSearch,
          ),
          GraphButton(
            label: 'REVIEW',
            active: controller.showReview,
            onPressed: controller.toggleReview,
          ),
          GraphButton(label: 'RESET', onPressed: controller.camera.reset),
        ],
      ),
    );
  }
}
