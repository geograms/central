import 'package:flutter/material.dart';
import 'package:graph3d/graph3d.dart';

import '../data/models.dart';
import '../theme.dart';

/// One file, as the CSS `.element` div.
///
/// The cyan glow is a per-card blur, and Flutter cannot cache blurs under a
/// perspective transform — 426 of them cost roughly a third of a second per
/// frame. So [glow] is reserved for the handful of cards that are actually
/// selected, linked or hovered, which is what the effect means anyway.
class NodeCard extends StatelessWidget {
  const NodeCard({
    super.key,
    required this.node,
    required this.alpha,
    required this.emphasis,
    required this.glow,
    required this.hovered,
    required this.onTap,
    required this.onHover,
  });

  final GraphNode node;

  /// The card's own background opacity, drawn once at random per the original.
  final double alpha;
  final CardEmphasis emphasis;
  final bool glow;
  final bool hovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  bool get _inactive => emphasis == CardEmphasis.inactive;

  Color get _background {
    if (_inactive) return Colors.transparent;
    final base = node.riskyLicense ? GraphColors.cardRed : GraphColors.cardTeal;
    return emphasis == CardEmphasis.selected
        ? base
        : base.withValues(alpha: alpha);
  }

  Color get _glowColor =>
      node.riskyLicense ? GraphColors.glowRed : GraphColors.glowCyan;

  @override
  Widget build(BuildContext context) {
    final lit = glow || hovered;
    final bright = hovered || emphasis != CardEmphasis.normal;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: kCardWidth,
          height: kCardHeight,
          decoration: BoxDecoration(
            color: _background,
            border: Border.all(
              color: bright && !_inactive
                  ? GraphColors.cardBorderBright
                  : GraphColors.cardBorder,
            ),
            boxShadow: lit && !_inactive
                ? <BoxShadow>[
                    BoxShadow(
                      color: _glowColor.withValues(alpha: hovered ? 0.75 : 0.5),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 18,
                left: 16,
                right: 16,
                child: Text(
                  node.tag,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    color: GraphColors.cardDetail,
                    fontSize: 12,
                  ),
                ),
              ),
              if (node.hasCopyright)
                const Positioned(
                  top: 4,
                  right: 5,
                  child: Text(
                    '©',
                    style: TextStyle(
                      color: GraphColors.cardDetail,
                      fontSize: 12,
                    ),
                  ),
                ),
              Positioned(
                top: 36,
                left: 0,
                right: 0,
                child: Text(
                  node.symbol,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: _inactive
                        ? GraphColors.symbolInactive
                        : GraphColors.symbol,
                    fontSize: _inactive ? 50 : 56,
                    height: 1.1,
                    fontWeight:
                        _inactive ? FontWeight.w300 : FontWeight.bold,
                    shadows: lit && !_inactive
                        ? <Shadow>[
                            Shadow(color: _glowColor, blurRadius: 10),
                          ]
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 3,
                right: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      node.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GraphColors.cardDetail,
                        fontSize: 11,
                      ),
                    ),
                    if (node.license.isNotEmpty)
                      Text(
                        node.license,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: GraphColors.cardDetail,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
