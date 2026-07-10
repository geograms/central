import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:graph3d/graph3d.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'data/mesh.dart';
import 'mesh_node.dart';

/// How far the expanded cluster's disc floats in front of its hub card.
const double _kDiscStandoff = 600;

/// Spacing between neighbouring leaves on the disc.
const double _kDiscSpacing = 150;

/// Owns the scene: which hub is expanded, what the current nodes and edges
/// are, and how tapping moves between the levels.
///
/// The clustering contract: every hub is always in the scene as one aggregate
/// card; at most ONE hub's devices are materialized at a time. Expanding a
/// hub collapses whichever was open — its leaves fly back into their hub and
/// fade while the new cluster fans out, in a single transition. That keeps
/// the rendered node count bounded no matter how large the network is.
class MeshClusterController extends ChangeNotifier {
  MeshClusterController({
    required this.network,
    required TickerProvider vsync,
  }) : scene = GraphSceneController<MeshNode>(vsync: vsync) {
    _apply(initial: true);
  }

  final MeshNetwork network;
  final GraphSceneController<MeshNode> scene;

  String? _expandedHubHash;
  String? get expandedHubHash => _expandedHubHash;

  MeshHub? get expandedHub => _expandedHubHash == null
      ? null
      : network.hubs.firstWhere((h) => h.hash == _expandedHubHash);

  double get _ringRadius =>
      math.max(1400, network.hubs.length * 420 / (2 * math.pi));

  List<Pose> get _hubRing =>
      ringPoses(network.hubs.length, radius: _ringRadius);

  int _hubIndexOf(String hash) =>
      network.hubs.indexWhere((h) => h.hash == hash);

  /// The scene: all hubs, plus the expanded hub's devices.
  GraphScene<MeshNode> _buildScene() {
    final hubs = network.hubs;
    final nodes = <SceneNode<MeshNode>>[
      for (var i = 0; i < hubs.length; i++)
        SceneNode<MeshNode>(
          key: HubNode(hubs[i], i).sceneKey,
          data: HubNode(hubs[i], i),
        ),
    ];

    final edges = <SceneEdge>[
      for (final link in network.links)
        SceneEdge(
          link.a + 1,
          link.b + 1,
          style: EdgeStyle(
            color: link.iface.color.withValues(alpha: 0.55),
            label: link.iface.label,
          ),
        ),
    ];

    final open = _expandedHubHash;
    if (open != null) {
      final hubIndex = _hubIndexOf(open);
      final hub = hubs[hubIndex];
      for (final device in hub.devices) {
        final node = DeviceNode(device, hub.hash);
        nodes.add(SceneNode<MeshNode>(key: node.sceneKey, data: node));
        edges.add(
          SceneEdge(
            hubIndex + 1,
            nodes.length,
            style: EdgeStyle(
              color: device.iface.color.withValues(alpha: 0.28),
              crawler: false, // 500 crawling balls would be noise
            ),
          ),
        );
      }
    }

    return GraphScene<MeshNode>(nodes: nodes, edges: edges);
  }

  /// Poses: hubs hold their ring slots; the open cluster fans out on a
  /// sunflower disc floating in front of its hub.
  LayoutGeometry _layout(List<SceneNode<MeshNode>> nodes) {
    final ring = _hubRing;
    final poses = <Pose>[];

    var deviceCount = 0;
    Pose? hubPose;
    for (final node in nodes) {
      if (node.data case DeviceNode(:final hubHash)) {
        deviceCount++;
        hubPose ??= ring[_hubIndexOf(hubHash)];
      }
    }
    final disc = hubPose == null
        ? const <Pose>[]
        : sunflowerDiscPoses(
            deviceCount,
            plane: Pose(
              hubPose.position + hubPose.facing * _kDiscStandoff,
              hubPose.rotation,
            ),
            spacing: _kDiscSpacing,
          );

    var device = 0;
    for (final node in nodes) {
      switch (node.data) {
        case HubNode(:final index):
          poses.add(ring[index]);
        case DeviceNode():
          poses.add(disc[device++]);
      }
    }
    return LayoutGeometry.fromPoses(poses);
  }

  void _apply({bool initial = false}) {
    // New leaves burst out of their hub; a collapsing cluster's leaves fly
    // back into theirs.
    Pose hubPoseOf(SceneNode<MeshNode> node) {
      final data = node.data;
      final hash = switch (data) {
        DeviceNode(:final hubHash) => hubHash,
        HubNode(:final hub) => hub.hash,
      };
      return _hubRing[_hubIndexOf(hash)];
    }

    scene.setScene(
      _buildScene(),
      layout: _layout,
      enterPoseOf: initial ? null : hubPoseOf,
      exitPoseOf: hubPoseOf,
      reframe: false,
    );

    resetView(immediate: initial);
    notifyListeners();
  }

  /// Frames whatever level the user is on: the open cluster face-on, or the
  /// whole ring from a raised vantage so it reads as a circle rather than a
  /// line of cards seen edge-on.
  void resetView({bool immediate = false}) {
    final open = _expandedHubHash;
    if (open != null) {
      // Leaves must stay readable; past this the cluster overflows and the
      // user pans.
      scene.camera.maxFrameDistance = 8000;
      final hubPose = _hubRing[_hubIndexOf(open)];
      final discRadius =
          _kDiscSpacing * math.sqrt(expandedHub!.devices.length + 0.5) + 100;
      scene.camera.frameFacing(
        Pose(
          hubPose.position + hubPose.facing * _kDiscStandoff,
          hubPose.rotation,
        ),
        halfExtent: Vector3(discRadius, discRadius, 0),
        durationMs: immediate ? 0 : 2200,
      );
      return;
    }

    // The ring is a 28-card overview: seeing all of it beats card legibility,
    // so let the camera back far enough off even on a portrait phone.
    scene.camera.maxFrameDistance = 24000;
    final r = _ringRadius;
    final vantage = Pose(
      Vector3.zero(),
      lookAtQuaternion(Vector3.zero(), Vector3(0, 0.55, 1)),
    );
    scene.camera.frameFacing(
      vantage,
      halfExtent: Vector3(r + 150, r * 0.6, r),
      sceneRadius: r + 300,
      durationMs: immediate ? 0 : 1800,
    );
  }

  /// The demo's tap semantics: leaves select, hubs expand and collapse.
  void tapNode(int id) {
    if (id < 1 || id > scene.liveCount) return;
    switch (scene.renderNodes[id - 1].data) {
      case DeviceNode():
        scene.tapNode(id);
      case HubNode(:final hub):
        if (_expandedHubHash == hub.hash) {
          collapse();
        } else {
          expand(hub.hash);
        }
    }
  }

  void expand(String hubHash) {
    if (_expandedHubHash == hubHash) return;
    _expandedHubHash = hubHash;
    _apply();
  }

  void collapse() {
    if (_expandedHubHash == null) return;
    _expandedHubHash = null;
    _apply();
  }

  @override
  void dispose() {
    scene.dispose();
    super.dispose();
  }
}
