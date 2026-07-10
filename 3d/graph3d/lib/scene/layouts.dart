import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import '../data/models.dart';
import 'pose.dart';

enum GraphLayout {
  table,
  helix,
  grid;

  String get label => name.toUpperCase();
}

/// The grid is 9 columns by 9 rows per slab, 1000 units between slabs.
const int _gridSize = 9;

/// Card poses for one layout, plus the framing the camera should use for it.
@immutable
class LayoutGeometry {
  const LayoutGeometry({
    required this.poses,
    required this.center,
    required this.radius,
    required this.halfExtent,
  });

  final List<Pose> poses;

  /// Where the camera aims when the layout is first shown, or reset.
  final Vector3 center;

  /// Distance from [center] out to the farthest card. Bounds panning.
  final double radius;

  /// Half the layout's width, height and depth. The camera backs off far
  /// enough to fit all three.
  final Vector3 halfExtent;
}

LayoutGeometry buildLayout(GraphLayout layout, List<GraphNode> nodes) {
  final poses = switch (layout) {
    GraphLayout.table => <Pose>[
      for (final node in nodes)
        Pose(
          Vector3(node.column * 140.0 - 1330, -(node.row * 180.0) + 990, 0),
          Quaternion.identity(),
        ),
    ],
    GraphLayout.helix => <Pose>[
      for (var i = 0; i < nodes.length; i++) _helixPose(i),
    ],
    GraphLayout.grid => <Pose>[
      for (var i = 0; i < nodes.length; i++)
        Pose(
          Vector3(
            (i % _gridSize) * 400.0 - 800,
            -((i ~/ _gridSize) % _gridSize) * 400.0 + 800,
            (i ~/ (_gridSize * _gridSize)) * 1000.0 - 2000,
          ),
          Quaternion.identity(),
        ),
    ],
  };

  // The original seeds its extents at zero and only ever widens them, so the
  // origin always sits inside the framed region. Match that.
  var minX = 0.0, maxX = 0.0, minY = 0.0, maxY = 0.0;
  var minZ = 0.0, maxZ = 0.0;
  for (final pose in poses) {
    minX = math.min(minX, pose.position.x);
    maxX = math.max(maxX, pose.position.x);
    minY = math.min(minY, pose.position.y);
    maxY = math.max(maxY, pose.position.y);
    minZ = math.min(minZ, pose.position.z);
    maxZ = math.max(maxZ, pose.position.z);
  }
  // The camera aims at the middle of the cards, not at the world origin, which
  // for the table sits off in the corner.
  final center = Vector3((minX + maxX) / 2, (minY + maxY) / 2, 0);

  var radius = 0.0;
  for (final pose in poses) {
    radius = math.max(radius, (pose.position - center).length);
  }

  return LayoutGeometry(
    poses: poses,
    center: center,
    radius: radius,
    // Widened by half a card, so the edge cards are not clipped in half.
    halfExtent: Vector3(
      (maxX - minX) / 2 + 70,
      (maxY - minY) / 2 + 80,
      (maxZ - minZ) / 2,
    ),
  );
}

Pose _helixPose(int i) {
  const radius = 900.0;
  final theta = i * 0.175 + math.pi;
  final y = -(i * 8.0) + 450;
  final position = Vector3(
    radius * math.sin(theta),
    y,
    radius * math.cos(theta),
  );
  // Face outwards from the helix axis, without tilting up or down.
  return Pose(
    position,
    lookAtQuaternion(
      position,
      Vector3(position.x * 2, position.y, position.z * 2),
    ),
  );
}
