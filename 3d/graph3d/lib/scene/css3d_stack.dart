import 'package:flutter/widgets.dart';

import 'pose.dart';
import 'projection.dart';

/// Projects every card through a full 4x4 matrix and paints them back to front.
///
/// Flutter has no depth buffer for widgets, so ordering happens here rather than
/// in the rasterizer. Flat cards never intersect, so a painter's-algorithm sort
/// on camera-space depth is exact.
///
/// Two constraints, both measured on a low-end phone with 426 cards:
///
///  * The sort permutes the children every frame. They must be keyed, or
///    Flutter rematches them by index and rebuilds every subtree.
///  * `Transform.filterQuality` cannot be used. It snapshots through
///    `ImageFilter.matrix`, which cannot express a perspective matrix, so most
///    cards silently fail to draw.
class Css3dStack extends StatelessWidget {
  const Css3dStack({
    super.key,
    required this.poses,
    required this.projector,
    required this.cardBuilder,
    this.foregroundIndex,
  });

  final List<Pose> poses;
  final Projector projector;

  /// Builds the card for a node index. Called for visible cards only.
  final Widget Function(int index) cardBuilder;

  /// Painted last whatever its depth, so a selected card is never occluded.
  /// Mirrors the original's `zIndex: 10` on the current node.
  final int? foregroundIndex;

  @override
  Widget build(BuildContext context) {
    final visible = <_ProjectedCard>[];
    for (var i = 0; i < poses.length; i++) {
      final model = poses[i].matrix;
      final depth = projector.depthOf(poses[i].position);
      if (depth > -1) continue; // behind, or level with, the eye
      visible.add(_ProjectedCard(i, depth, projector.cardMatrix(model)));
    }

    // Most negative depth is farthest away, so it gets painted first.
    visible.sort((a, b) => a.depth.compareTo(b.depth));

    final front = foregroundIndex;
    if (front != null) {
      final at = visible.indexWhere((card) => card.index == front);
      if (at != -1) visible.add(visible.removeAt(at));
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        for (final card in visible)
          Center(
            // The key must sit on the Stack's direct child. Anywhere deeper and
            // the reorder still rematches elements by index.
            key: ValueKey<int>(card.index),
            child: Transform(
              transform: card.matrix,
              alignment: Alignment.center,
              child: RepaintBoundary(child: cardBuilder(card.index)),
            ),
          ),
      ],
    );
  }
}

class _ProjectedCard {
  const _ProjectedCard(this.index, this.depth, this.matrix);

  final int index;
  final double depth;
  final Matrix4 matrix;
}
