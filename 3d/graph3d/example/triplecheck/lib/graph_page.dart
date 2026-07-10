import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graph3d/graph3d.dart';

import 'data/models.dart';
import 'graph_controller.dart';
import 'review/review_store.dart';
import 'widgets/card_paint.dart';
import 'widgets/info_panel.dart';
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
  late final CardBakery<GraphNode> _bakery;
  late final AnimationController _frameReveal;

  MatchFile? _reviewFile;

  @override
  void initState() {
    super.initState();
    _controller = GraphController(
      data: widget.data,
      reviewStore: widget.reviewStore,
      vsync: this,
    );
    _bakery = CardBakery<GraphNode>(paint: paintTcCard);
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

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kWidePanelBreakpoint;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape):
            _controller.scene.clearSelection,
      },
      child: Focus(autofocus: true, child: _buildScaffold(wide)),
    );
  }

  Widget _buildScaffold(bool wide) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Graph3DView<GraphNode>(
                controller: _controller.scene,
                bakery: _bakery,
                visibleEdgesOf: _controller.visibleEdges,
                liveCardBuilder: (context, node, state) => NodeCard(
                  node: node.data,
                  alpha: state.alpha,
                  emphasis: state.emphasis,
                  glow: state.glow,
                  hovered: state.hovered,
                  onTap: () {},
                  onHover: (_) {},
                ),
              ),
            ),
          ),
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
            // screen, so they stack rather than overlap.
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
}

class _Panels extends StatelessWidget {
  const _Panels({
    required this.controller,
    required this.onOpenReviewFile,
    required this.bottomAnchored,
  });

  final GraphController controller;
  final ValueChanged<MatchFile> onOpenReviewFile;
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
          for (final layout in TcLayout.values)
            GraphButton(
              label: layout.label,
              active: controller.layout == layout,
              onPressed: () => controller.setLayout(layout),
            ),
          GraphButton(
            label: 'LINKS',
            active: controller.showLinks,
            tooltip: controller.layout == TcLayout.table
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
          GraphButton(
            label: 'RESET',
            onPressed: () => controller.scene.reframe(),
          ),
        ],
      ),
    );
  }
}
