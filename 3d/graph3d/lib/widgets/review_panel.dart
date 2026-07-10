import 'package:flutter/material.dart';

import '../data/models.dart';
import '../graph_controller.dart';
import '../review/review_store.dart';
import '../search/query.dart';
import '../theme.dart';
import 'panel.dart';

/// The match bins, grouped by file type, each file carrying its five-way
/// verdict buttons and a per-type tally of what still needs attention.
class ReviewPanel extends StatefulWidget {
  const ReviewPanel({
    super.key,
    required this.controller,
    required this.onOpenFile,
    this.onClose,
  });

  final GraphController controller;
  final void Function(MatchGroup group, MatchFile file) onOpenFile;
  final VoidCallback? onClose;

  @override
  State<ReviewPanel> createState() => _ReviewPanelState();
}

class _ReviewPanelState extends State<ReviewPanel> {
  bool _collapsed = false;
  final Set<String> _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final groups = widget.controller.data.matches
        .where((group) => group.files.isNotEmpty)
        .toList();

    return GraphPanel(
      title: const Text('Review'),
      collapsed: _collapsed,
      onMinimize: () => setState(() => _collapsed = !_collapsed),
      onClose: widget.onClose,
      maxBodyHeight: 420,
      child: AnimatedBuilder(
        animation: widget.controller.reviewStore,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (groups.isEmpty)
              const Text('No matches to review', style: kMonospace),
            for (final group in groups)
              _MatchGroupTile(
                group: group,
                store: widget.controller.reviewStore,
                expanded: _expanded.contains(group.type),
                onToggle: () => setState(() {
                  if (!_expanded.remove(group.type)) _expanded.add(group.type);
                }),
                onOpenFile: (file) => widget.onOpenFile(group, file),
                onLocate: (file) => _locate(file),
              ),
          ],
        ),
      ),
    );
  }

  /// Flies the graph to the node holding this match, if the file is in it.
  void _locate(MatchFile file) {
    final data = widget.controller.data;
    for (final detail in data.details) {
      if (detail.path == file.cleanName) {
        widget.controller.selectNode(detail.id);
        return;
      }
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('${file.shortName} is not in the graph')),
    );
  }
}

class _MatchGroupTile extends StatelessWidget {
  const _MatchGroupTile({
    required this.group,
    required this.store,
    required this.expanded,
    required this.onToggle,
    required this.onOpenFile,
    required this.onLocate,
  });

  final MatchGroup group;
  final ReviewStore store;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<MatchFile> onOpenFile;
  final ValueChanged<MatchFile> onLocate;

  @override
  Widget build(BuildContext context) {
    final counts = <ReviewState, int>{};
    for (final file in group.files) {
      final state = store.stateOrDefault(file.filename);
      counts[state] = (counts[state] ?? 0) + 1;
    }

    final sorted = <MatchFile>[
      for (final state in kReviewSortOrder)
        ...group.files.where(
          (file) => store.stateOrDefault(file.filename) == state,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: onToggle,
          child: Container(
            color: GraphColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: <Widget>[
                Text(
                  expanded ? '▼' : '►',
                  style: const TextStyle(color: Colors.black, fontSize: 11),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${group.type} (${group.files.length})',
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ),
                for (final state in kCountedStates)
                  if ((counts[state] ?? 0) > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: state.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '${counts[state]}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
        if (expanded)
          for (final file in sorted)
            _ReviewFileRow(
              file: file,
              store: store,
              onOpen: () => onOpenFile(file),
              onLocate: () => onLocate(file),
            ),
        const SizedBox(height: 2),
      ],
    );
  }
}

class _ReviewFileRow extends StatelessWidget {
  const _ReviewFileRow({
    required this.file,
    required this.store,
    required this.onOpen,
    required this.onLocate,
  });

  final MatchFile file;
  final ReviewStore store;
  final VoidCallback onOpen;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final current = store.stateOrDefault(file.filename);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          for (final state in ReviewState.values)
            _StateButton(
              state: state,
              active: state == current,
              onPressed: () => store.setState(file.filename, state),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Tooltip(
              message: file.filename,
              child: GraphLinkText(
                text: shorten(file.shortName, 22, 8),
                onTap: onOpen,
              ),
            ),
          ),
          IconButton(
            onPressed: onLocate,
            tooltip: 'Show in graph',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            iconSize: 15,
            icon: const Icon(Icons.my_location, color: GraphColors.cardDetail),
          ),
        ],
      ),
    );
  }
}

class _StateButton extends StatelessWidget {
  const _StateButton({
    required this.state,
    required this.active,
    required this.onPressed,
  });

  final ReviewState state;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: state.label,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(right: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? state.color : Colors.transparent,
            border: Border.all(
              color: active ? state.color : GraphColors.cardDetail,
            ),
          ),
          child: Text(
            state.glyph,
            style: TextStyle(
              color: active ? Colors.black : GraphColors.cardDetail,
              fontSize: 10,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
