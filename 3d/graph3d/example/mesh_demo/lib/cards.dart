import 'package:flutter/material.dart';
import 'package:graph3d/graph3d.dart';

import 'data/mesh.dart';
import 'mesh_node.dart';

const Color _hubTint = Color(0xFF00838F);
const Color _panelText = Color.fromRGBO(178, 235, 242, 0.85);
const Color _dimText = Color.fromRGBO(178, 235, 242, 0.55);

TextPainter _text(
  String text,
  double size, {
  FontWeight weight = FontWeight.normal,
  Color color = _panelText,
  double? maxWidth,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: size, fontWeight: weight, color: color),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth ?? double.infinity);
  return painter;
}

void _centered(Canvas canvas, TextPainter painter, double y) {
  painter.paint(canvas, Offset((kCardWidth - painter.width) / 2, y));
}

/// One hub, collapsed: the aggregate card for a whole cluster.
void paintHubCard(Canvas canvas, MeshHub hub, double alpha) {
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, kCardWidth, kCardHeight),
    Paint()..color = _hubTint.withValues(alpha: 0.25 + alpha * 0.4),
  );
  canvas.drawRect(
    const Rect.fromLTWH(0.75, 0.75, kCardWidth - 1.5, kCardHeight - 1.5),
    Paint()
      ..color = const Color.fromRGBO(128, 222, 234, 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );

  _centered(canvas, _text('HUB', 11, color: _dimText), 10);
  final count = _text(
    '${hub.devices.length}',
    44,
    weight: FontWeight.bold,
    color: Colors.white.withValues(alpha: 0.9),
    maxWidth: kCardWidth,
  );
  _centered(canvas, count, 34);
  _centered(canvas, _text('devices', 11, color: _dimText), 84);
  _centered(canvas, _text(hub.name, 12, maxWidth: kCardWidth - 8), 112);
  _centered(
    canvas,
    _text(
      '${hub.region} · ${hub.hash.substring(0, 8)}',
      9,
      color: _dimText,
      maxWidth: kCardWidth - 8,
    ),
    132,
  );
}

/// One leaf device of the expanded cluster, tinted by its interface.
void paintDeviceCard(Canvas canvas, MeshDevice device, double alpha) {
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, kCardWidth, kCardHeight),
    Paint()..color = device.iface.color.withValues(alpha: 0.10 + alpha * 0.25),
  );
  canvas.drawRect(
    const Rect.fromLTWH(0.5, 0.5, kCardWidth - 1, kCardHeight - 1),
    Paint()
      ..color = device.iface.color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke,
  );

  // Interface badge.
  final badge = _text(
    device.iface.label,
    11,
    weight: FontWeight.bold,
    color: Colors.black,
  );
  final badgeRect = Rect.fromLTWH(8, 8, badge.width + 10, badge.height + 4);
  canvas.drawRRect(
    RRect.fromRectAndRadius(badgeRect, const Radius.circular(3)),
    Paint()..color = device.iface.color,
  );
  badge.paint(canvas, const Offset(13, 10));

  final hops = _text('${device.hops} hop${device.hops == 1 ? '' : 's'}', 10,
      color: _dimText);
  hops.paint(canvas, Offset(kCardWidth - 8 - hops.width, 11));

  _centered(
    canvas,
    _text(
      device.name.split('-').first,
      26,
      weight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.85),
      maxWidth: kCardWidth - 8,
    ),
    52,
  );
  _centered(canvas, _text(device.name, 11, maxWidth: kCardWidth - 8), 96);
  _centered(
    canvas,
    _text(device.shortHash, 10, color: _dimText, maxWidth: kCardWidth - 8),
    128,
  );
}

void paintMeshNode(Canvas canvas, MeshNode node, double alpha) {
  switch (node) {
    case HubNode(:final hub):
      paintHubCard(canvas, hub, alpha);
    case DeviceNode(:final device):
      paintDeviceCard(canvas, device, alpha);
  }
}

/// The live widget for a selected or hovered card: the same painting as the
/// bake, plus the glow only live cards can afford.
class LiveMeshCard extends StatelessWidget {
  const LiveMeshCard({super.key, required this.node, required this.state});

  final SceneNode<MeshNode> node;
  final CardState state;

  Color get _glowColor => switch (node.data) {
    HubNode() => const Color(0xFF4DD0E1),
    DeviceNode(:final device) => device.iface.color,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kCardWidth,
      height: kCardHeight,
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: state.glow || state.hovered
            ? <BoxShadow>[
                BoxShadow(
                  color: _glowColor.withValues(alpha: state.glow ? 0.7 : 0.45),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _MeshCardPainter(node.data, state.alpha),
      ),
    );
  }
}

class _MeshCardPainter extends CustomPainter {
  const _MeshCardPainter(this.node, this.alpha);

  final MeshNode node;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) => paintMeshNode(canvas, node, alpha);

  @override
  bool shouldRepaint(_MeshCardPainter oldDelegate) =>
      oldDelegate.node != node || oldDelegate.alpha != alpha;
}
