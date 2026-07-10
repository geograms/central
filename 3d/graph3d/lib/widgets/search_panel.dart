import 'package:flutter/material.dart';

import '../graph_controller.dart';
import '../search/query.dart';
import '../theme.dart';
import 'panel.dart';

const String _kHelpText = '''
Find files using a field:
  license:mit

Find files with a field and extension
  license:mit AND .java

Find files with one license or another
  license:mit OR license:gpl

Exact matches are enclosed with "":
  license:"MIT"

Fields that can be used:
  tag, license, name, copyright, path, sha1''';

class SearchPanel extends StatefulWidget {
  const SearchPanel({super.key, required this.controller, this.onClose});

  final GraphController controller;
  final VoidCallback? onClose;

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  final TextEditingController _input = TextEditingController();
  bool _collapsed = false;
  bool _showHelp = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _find() {
    setState(() => _lastQuery = _input.text.trim());
    widget.controller.search(_input.text);
  }

  @override
  Widget build(BuildContext context) {
    return GraphPanel(
      title: Text(
        _lastQuery.isEmpty
            ? 'Find files'
            : 'Find files: "${shorten(_lastQuery, 24, 0)}"',
      ),
      collapsed: _collapsed,
      onMinimize: () => setState(() => _collapsed = !_collapsed),
      onClose: widget.onClose,
      maxBodyHeight: 380,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _input,
                  onSubmitted: (_) => _find(),
                  maxLength: 200,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    counterText: '',
                    hintText: 'search ...',
                    hintStyle: TextStyle(color: GraphColors.accent),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: GraphColors.accent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: GraphColors.cardDetail),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GraphButton(label: 'FIND', onPressed: _find),
              const SizedBox(width: 4),
              GraphButton(
                label: '?',
                active: _showHelp,
                onPressed: () => setState(() => _showHelp = !_showHelp),
              ),
            ],
          ),
          if (_showHelp) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: GraphColors.accent),
              ),
              child: const Text(_kHelpText, style: kMonospace),
            ),
          ],
          const SizedBox(height: 10),
          _Results(controller: widget.controller),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.controller});

  final GraphController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.searchSummary;
    if (summary.isEmpty) return const SizedBox.shrink();

    final hits = controller.searchResults;
    if (hits.isEmpty) return Text(summary, style: kMonospace);

    // Grouped by the field that matched, in the field priority order — which
    // is what the original's per-field HTML buckets amount to.
    final byField = <String, List<SearchHit>>{};
    for (final hit in hits) {
      byField.putIfAbsent(hit.primaryField, () => <SearchHit>[]).add(hit);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(summary, style: kMonospace),
        const Divider(color: GraphColors.accent, height: 12),
        for (final field in kSearchFields)
          for (final hit in byField[field] ?? const <SearchHit>[])
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: GraphLinkText(
                text: shorten(hit.fileName, 30, 8),
                trailing: ' // ${hit.joinedFields}',
                onTap: () => controller.selectNode(hit.id),
              ),
            ),
      ],
    );
  }
}
