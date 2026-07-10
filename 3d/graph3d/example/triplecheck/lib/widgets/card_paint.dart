import 'package:flutter/painting.dart';
import 'package:graph3d/graph3d.dart';

import '../data/models.dart';
import '../theme.dart';

TextPainter _text(
  String text,
  double fontSize, {
  FontWeight weight = FontWeight.normal,
  Color color = GraphColors.cardDetail,
  double? maxWidth,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth ?? double.infinity);
  return painter;
}

/// Paints one card exactly as `NodeCard` does in its normal state; the engine
/// bakes it once to a texture. Emphasised states are handled at draw time.
void paintTcCard(Canvas canvas, GraphNode node, double alpha) {
  const width = kCardWidth;
  const height = kCardHeight;
  final base = node.riskyLicense ? GraphColors.cardRed : GraphColors.cardTeal;

  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()..color = base.withValues(alpha: alpha),
  );
  canvas.drawRect(
    const Rect.fromLTWH(0.5, 0.5, width - 1, height - 1),
    Paint()
      ..color = GraphColors.cardBorder
      ..style = PaintingStyle.stroke,
  );

  _text(node.tag, 12, maxWidth: width - 32).paint(canvas, const Offset(16, 18));

  if (node.hasCopyright) {
    final copyright = _text('©', 12);
    copyright.paint(canvas, Offset(width - 5 - copyright.width, 4));
  }

  final symbol = _text(
    node.symbol,
    56,
    weight: FontWeight.bold,
    color: GraphColors.symbol,
    maxWidth: width,
  );
  symbol.paint(canvas, Offset((width - symbol.width) / 2, 36));

  var bottom = height - 12.0;
  if (node.license.isNotEmpty) {
    final license = _text(node.license, 11, maxWidth: width - 6);
    bottom -= license.height;
    license.paint(canvas, Offset((width - license.width) / 2, bottom));
  }
  final name = _text(node.name, 11, maxWidth: width - 6);
  bottom -= name.height;
  name.paint(canvas, Offset((width - name.width) / 2, bottom));
}
