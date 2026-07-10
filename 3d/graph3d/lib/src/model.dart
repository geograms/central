import 'dart:ui';

import 'package:flutter/foundation.dart';

/// One node in the scene, wrapping the consumer's own data type.
///
/// The [key] is the node's durable identity: it survives scene rebuilds, keys
/// the baked-image cache, and carries selection and hover across
/// expand/collapse. The engine never inspects [data]; it only hands it back
/// to the consumer's paint and build callbacks.
@immutable
class SceneNode<T> {
  const SceneNode({required this.key, required this.data});

  final String key;
  final T data;
}

/// How one edge is drawn.
@immutable
class EdgeStyle {
  const EdgeStyle({
    this.color = const Color(0xFF016161),
    this.width = 1,
    this.label,
    this.crawler = true,
  });

  final Color color;
  final double width;

  /// Drawn at the projected midpoint of the edge, e.g. an interface name.
  final String? label;

  /// Whether a ball crawls from [SceneEdge.from] to [SceneEdge.to].
  final bool crawler;
}

/// A directed edge between two nodes of the current scene.
///
/// Endpoints are one-based indices into the scene's node list — the same
/// per-frame id handed to the pick and emphasis callbacks. Durable identity
/// belongs to keys; edges are rebuilt with each scene.
@immutable
class SceneEdge {
  const SceneEdge(this.from, this.to, {this.style = const EdgeStyle()});

  final int from;
  final int to;
  final EdgeStyle style;

  bool get isSelfEdge => from == to;
  bool touches(int id) => from == id || to == id;
}

/// What the engine renders: nodes plus the edges between them.
@immutable
class GraphScene<T> {
  const GraphScene({required this.nodes, this.edges = const <SceneEdge>[]});

  final List<SceneNode<T>> nodes;
  final List<SceneEdge> edges;
}

/// How prominently a card is drawn, given what is selected or highlighted.
enum CardEmphasis {
  /// The current node: fully opaque, drawn in front of everything.
  selected,

  /// Related to the focus — linked to it, or in the highlight set.
  highlighted,

  /// Nothing has focus, so everything reads normally.
  normal,

  /// Dimmed out of the way while something else has the user's attention.
  inactive,
}

/// Engine-level draw constants a consumer may retheme.
@immutable
class GraphStyle {
  const GraphStyle({
    this.highlightBorder = const Color.fromRGBO(127, 255, 255, 0.75),
    this.inactiveAlpha = 0.16,
  });

  /// Stroked around cards with [CardEmphasis.highlighted].
  final Color highlightBorder;

  /// Alpha a [CardEmphasis.inactive] card's image is drawn with.
  final double inactiveAlpha;
}
