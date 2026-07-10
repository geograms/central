import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../data/models.dart';
import '../scene/projection.dart';
import '../theme.dart';

/// Oversampling factor for the baked textures. Cards in the crowd render at
/// well under their natural 120x160, and the two cards the user is actually
/// looking at (selected, hovered) are drawn as live widgets, so 1.5x keeps
/// them crisp through a deep pinch-zoom without an outsized texture bill:
/// 426 cards at 180x240 RGBA is ~74MB.
const double kBakeScale = 1.5;

/// Rasterizes every card once, up front, into GPU-resident images.
///
/// This exists because Flutter re-rasterizes anything under a perspective
/// transform on every frame — the raster cache is disabled there, and Android
/// has no partial repaint. 426 widget cards cost 20-30ms of raster per
/// animated frame on a low-end phone, all of it glyph drawing. A baked card
/// is one textured quad; the whole crowd rasters in a few milliseconds.
class CardBakery {
  CardBakery._(this.images);

  /// One image per node, in node order.
  final List<ui.Image> images;

  static TextPainter _text(
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
    );
    painter.layout(maxWidth: maxWidth ?? double.infinity);
    return painter;
  }

  /// Paints one card exactly as `NodeCard` does in its normal state. The
  /// emphasised states are handled at draw time: inactive as an alpha fade,
  /// highlighted as a stroked border, selected and hovered as live widgets.
  static void paintCard(Canvas canvas, GraphNode node, double alpha) {
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

  /// Bakes all cards. Synchronous — a few hundred milliseconds at startup,
  /// hidden behind the fly-in animation — and the images live on the GPU.
  static CardBakery bake(List<GraphNode> nodes, List<double> alphas) {
    final images = <ui.Image>[];
    for (var i = 0; i < nodes.length; i++) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(kBakeScale);
      paintCard(canvas, nodes[i], alphas[i]);
      final picture = recorder.endRecording();
      images.add(
        picture.toImageSync(
          (kCardWidth * kBakeScale).round(),
          (kCardHeight * kBakeScale).round(),
        ),
      );
      picture.dispose();
    }
    return CardBakery._(images);
  }

  void dispose() {
    for (final image in images) {
      image.dispose();
    }
  }
}
