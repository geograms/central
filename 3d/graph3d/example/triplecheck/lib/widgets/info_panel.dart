import 'package:flutter/material.dart';

import '../graph_controller.dart';
import '../search/query.dart';
import '../theme.dart';
import 'panel.dart';

/// The project overview, or the details of whatever node has focus.
class InfoPanel extends StatefulWidget {
  const InfoPanel({super.key, required this.controller, this.onClose});

  final GraphController controller;
  final VoidCallback? onClose;

  @override
  State<InfoPanel> createState() => _InfoPanelState();
}

class _InfoPanelState extends State<InfoPanel> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final id = controller.focusId;

    return GraphPanel(
      title: id == null
          ? const Text('Details')
          : Text(
              shorten(controller.data.detailById(id).fileName, 24, 8),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
      collapsed: _collapsed,
      onMinimize: () => setState(() => _collapsed = !_collapsed),
      onClose: widget.onClose,
      child: id == null
          ? Text(controller.data.project.summary.trim(), style: kMonospace)
          : _FileInfo(controller: controller, id: id),
    );
  }
}

class _FileInfo extends StatelessWidget {
  const _FileInfo({required this.controller, required this.id});

  final GraphController controller;
  final int id;

  @override
  Widget build(BuildContext context) {
    final detail = controller.data.detailById(id);
    final links = controller.focusLinks;
    final linked = <int>[...links.incoming, ...links.outgoing];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (detail.linesOfCode > 0) _row('LOC', '${detail.linesOfCode}'),
        _row('License', detail.license.isEmpty ? 'Not Found' : detail.license),
        // The original labels this "License" too, which is plainly a slip.
        _row(
          'Copyright',
          detail.copyright.isEmpty ? 'Not Found' : detail.copyright,
        ),
        _row('Path', detail.path),
        _row('SHA1', detail.sha1),
        _row('Size', formatBytes(detail.size)),
        if (linked.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            linked.length == 1
                ? '1 file linked:'
                : '${linked.length} files linked:',
            style: kMonospace,
          ),
          const SizedBox(height: 4),
          for (final other in linked)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 2),
              child: GraphLinkText(
                text: controller.data.detailById(other).fileName,
                trailing: controller.data.detailById(other).license.isEmpty
                    ? ''
                    : ' // ${controller.data.detailById(other).license}',
                onTap: () => controller.selectNode(other),
              ),
            ),
        ],
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: SelectableText('$label: $value', style: kMonospace),
  );
}
