import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:graph3d/graph3d.dart';
import 'package:vector_math/vector_math_64.dart' show Quaternion, Vector3;

import 'data/mesh.dart';

/// Which mental model the scene shows.
enum MeshView {
  /// What THIS node actually knows: itself at the centre, direct neighbours
  /// on an inner shell grouped by interface, relays further out, and
  /// destinations at a radius proportional to their hop count, reached
  /// through ghost segments (the middle of a Reticulum path is unknowable).
  ego,

  /// The aggregated whole-network picture — what several vantage points
  /// stitched together would show. Transports on a ring, backbone links.
  god,
}

/// Shell radii for the ego view.
const double _kPeerShell = 620;
const double _kRelayShell = 1300;
const double _kHopSpacing = 340;

/// The scene and everything the user does to it: view mode, the one expanded
/// cluster, the selected entity, and the walk along a path.
class MeshViewController extends ChangeNotifier {
  MeshViewController({required this.network, required TickerProvider vsync})
    : scene = GraphSceneController<MeshEntity>(vsync: vsync) {
    scene.addListener(_onSceneChanged);
    _apply(initial: true);
  }

  final MeshNetwork network;
  final GraphSceneController<MeshEntity> scene;

  MeshView _view = MeshView.ego;
  String? _expandedHash;
  List<String> _pathChain = const <String>[];
  int _pathStep = 0;

  MeshView get view => _view;
  String? get expandedHash => _expandedHash;
  List<String> get pathChain => _pathChain;
  int get pathStep => _pathStep;

  MeshEntity? get selectedEntity {
    final key = scene.selectedKey;
    if (key == null) return null;
    final id = scene.selectedId;
    return id == null ? null : scene.renderNodes[id - 1].data;
  }

  MeshEntity? get focusEntity {
    final id = scene.focusId;
    return id == null ? null : scene.renderNodes[id - 1].data;
  }

  static String keyOf(MeshEntity entity) =>
      entity.role == MeshRole.self ? 'self' : 'n:${entity.hash}';

  void _onSceneChanged() {
    // Selection is the tail of the path chain; if it went away, so does the
    // walk.
    if (_pathChain.isNotEmpty && scene.selectedKey == null) {
      _pathChain = const <String>[];
      _pathStep = 0;
      scene.highlightKeys = const <String>{};
    }
    notifyListeners();
  }

  // --- scene assembly ---------------------------------------------------------

  ({GraphScene<MeshEntity> scene, LayoutStrategy<MeshEntity> layout})
  _build() {
    return switch (_view) {
      MeshView.ego => _buildEgo(),
      MeshView.god => _buildGod(),
    };
  }

  List<MeshEntity> get _expandedLeaves => _expandedHash == null
      ? const <MeshEntity>[]
      : network.clusterLeaves[_expandedHash] ?? const <MeshEntity>[];

  ({GraphScene<MeshEntity> scene, LayoutStrategy<MeshEntity> layout})
  _buildEgo() {
    final all = <MeshEntity>[...network.entities, ..._expandedLeaves];
    final nodes = <SceneNode<MeshEntity>>[
      for (final entity in all)
        SceneNode<MeshEntity>(key: keyOf(entity), data: entity),
    ];
    final idOf = <String, int>{
      for (var i = 0; i < all.length; i++) all[i].hash: i + 1,
    };

    final edges = <SceneEdge>[];
    for (var i = 0; i < all.length; i++) {
      final entity = all[i];
      if (entity.role == MeshRole.self) continue;
      if (entity.nextHop == null) {
        // A direct neighbour: a live link from self.
        final relay = entity.deviceCount > 0 ||
            all.any((e) => e.nextHop == entity.hash);
        edges.add(
          SceneEdge(
            idOf[network.selfHash]!,
            i + 1,
            style: EdgeStyle(
              color: entity.iface.color.withValues(alpha: 0.75),
              width: relay ? 1.6 : 1.0,
              glow: true,
              crawler: relay,
              pulseCount: relay ? 2 : 1,
            ),
          ),
        );
      } else {
        final via = idOf[entity.nextHop];
        if (via == null) continue;
        final expanded = entity.nextHop == _expandedHash &&
            !network.entities.contains(entity);
        // The path beyond the first relay is unknowable: a ghost segment,
        // one tick per unknown intermediate hop.
        edges.add(
          SceneEdge(
            via,
            i + 1,
            style: expanded
                ? EdgeStyle(
                    color: entity.iface.color.withValues(alpha: 0.16),
                    width: 0.8,
                    crawler: false,
                  )
                : EdgeStyle(
                    color: entity.iface.color.withValues(alpha: 0.4),
                    width: 1.0,
                    dashed: true,
                    ticks: math.max(0, entity.hops - 2),
                    crawler: false,
                  ),
          ),
        );
      }
    }

    return (
      scene: GraphScene<MeshEntity>(nodes: nodes, edges: edges),
      layout: _egoLayout,
    );
  }

  /// Azimuth sector per interface present among direct neighbours, width
  /// proportional to sqrt(member count), fixed enum order.
  Map<Iface, (double, double)> _egoSectors(List<MeshEntity> all) {
    final counts = <Iface, int>{};
    for (final entity in all) {
      if (entity.hops == 1) {
        counts[entity.iface] = (counts[entity.iface] ?? 0) + 1;
      }
    }
    final present = <Iface>[
      for (final iface in Iface.values)
        if (counts.containsKey(iface)) iface,
    ];
    final weights = <double>[
      for (final iface in present) math.max(math.sqrt(counts[iface]!), 1.4),
    ];
    final total = weights.fold(0.0, (a, b) => a + b);
    final sectors = <Iface, (double, double)>{};
    var theta = 0.0;
    for (var i = 0; i < present.length; i++) {
      final sweep = 2 * math.pi * weights[i] / total;
      sectors[present[i]] = (theta, sweep);
      theta += sweep;
    }
    return sectors;
  }

  LayoutGeometry _egoLayout(List<SceneNode<MeshEntity>> nodes) {
    final all = <MeshEntity>[for (final n in nodes) n.data];
    final sectors = _egoSectors(all);

    // Pass 1: place self and every direct neighbour.
    final positions = List<Vector3?>.filled(all.length, null);
    final azimuthOf = <String, double>{};

    final byIfacePeers = <Iface, List<int>>{};
    final byIfaceRelays = <Iface, List<int>>{};
    for (var i = 0; i < all.length; i++) {
      final entity = all[i];
      if (entity.role == MeshRole.self) {
        positions[i] = Vector3.zero();
        continue;
      }
      if (entity.hops != 1) continue;
      final relay = entity.deviceCount > 0 ||
          all.any((e) => e.nextHop == entity.hash);
      (relay ? byIfaceRelays : byIfacePeers)
          .putIfAbsent(entity.iface, () => <int>[])
          .add(i);
    }

    byIfacePeers.forEach((iface, indices) {
      final (start, sweep) = sectors[iface]!;
      final poses = sectorShellPoses(
        indices.length,
        radius: _kPeerShell,
        thetaStart: start + sweep * 0.08,
        thetaSweep: sweep * 0.84,
        phiSpread: math.pi / 2.4,
      );
      for (var j = 0; j < indices.length; j++) {
        positions[indices[j]] = poses[j].position;
        azimuthOf[all[indices[j]].hash] =
            start + sweep * 0.08 + (j + 0.5) / indices.length * sweep * 0.84;
      }
    });

    byIfaceRelays.forEach((iface, indices) {
      final (start, sweep) = sectors[iface]!;
      for (var j = 0; j < indices.length; j++) {
        final theta = start + sweep * (j + 1) / (indices.length + 1);
        positions[indices[j]] = Vector3(
          _kRelayShell * math.sin(theta),
          0,
          _kRelayShell * math.cos(theta),
        );
        azimuthOf[all[indices[j]].hash] = theta;
      }
    });

    // Pass 2: destinations behind their relay, radius grows with hop count so
    // equal-hop nodes read as rings. Spread on a narrow cone per relay.
    final perRelayCount = <String, int>{};
    for (final entity in all) {
      if (entity.nextHop != null) {
        perRelayCount[entity.nextHop!] =
            (perRelayCount[entity.nextHop!] ?? 0) + 1;
      }
    }
    final perRelaySeen = <String, int>{};
    const golden = 0.6180339887498949;
    for (var i = 0; i < all.length; i++) {
      if (positions[i] != null) continue;
      final entity = all[i];
      final relayAzimuth = azimuthOf[entity.nextHop] ?? 0;
      final siblings = perRelayCount[entity.nextHop] ?? 1;
      final ordinal = perRelaySeen.update(
        entity.nextHop!,
        (v) => v + 1,
        ifAbsent: () => 0,
      );
      final spreadHalf = siblings > 40 ? 0.5 : 0.28;
      final theta = relayAzimuth +
          ((ordinal + 0.5) / siblings - 0.5) * 2 * spreadHalf;
      final phi = math.pi / 2 +
          (((ordinal * golden) % 1.0) - 0.5) * (siblings > 40 ? 0.9 : 0.45);
      final radius = _kRelayShell + _kHopSpacing * (entity.hops - 1);
      positions[i] = Vector3(
        radius * math.sin(phi) * math.sin(theta),
        radius * math.cos(phi),
        radius * math.sin(phi) * math.cos(theta),
      );
    }

    return LayoutGeometry.fromPoses(<Pose>[
      for (final position in positions)
        Pose(position!, Quaternion.identity()),
    ]);
  }

  ({GraphScene<MeshEntity> scene, LayoutStrategy<MeshEntity> layout})
  _buildGod() {
    final hubs = <MeshEntity>[
      ...network.hubs,
      network.entities.firstWhere((e) => e.role == MeshRole.gateway),
    ];
    final all = <MeshEntity>[...hubs, ..._expandedLeaves];
    final nodes = <SceneNode<MeshEntity>>[
      for (final entity in all)
        SceneNode<MeshEntity>(key: keyOf(entity), data: entity),
    ];

    final edges = <SceneEdge>[
      for (final link in network.hubLinks)
        SceneEdge(
          link.a + 1,
          link.b + 1,
          style: EdgeStyle(
            color: link.iface.color.withValues(alpha: 0.6),
            width: 1.3,
            glow: true,
            label: link.iface.label,
            pulseCount: 2,
          ),
        ),
      // The LoRa gateway hangs off the first hub's LAN in this aggregate.
      SceneEdge(
        1,
        hubs.length,
        style: EdgeStyle(
          color: Iface.lan.color.withValues(alpha: 0.55),
          width: 1.2,
          glow: true,
          label: Iface.lan.label,
        ),
      ),
    ];
    if (_expandedHash != null) {
      final hubId = 1 + all.indexWhere((e) => e.hash == _expandedHash);
      if (hubId > 0) {
        for (var i = hubs.length; i < all.length; i++) {
          edges.add(
            SceneEdge(
              hubId,
              i + 1,
              style: EdgeStyle(
                color: all[i].iface.color.withValues(alpha: 0.16),
                width: 0.8,
                crawler: false,
              ),
            ),
          );
        }
      }
    }

    return (
      scene: GraphScene<MeshEntity>(nodes: nodes, edges: edges),
      layout: (nodes) => _godLayout(nodes, hubs.length),
    );
  }

  LayoutGeometry _godLayout(List<SceneNode<MeshEntity>> nodes, int hubCount) {
    final ring = ringPoses(hubCount, radius: 1050);
    final poses = <Pose>[...ring.take(nodes.length)];
    if (nodes.length > hubCount) {
      final hubIndex =
          nodes.indexWhere((n) => n.data.hash == _expandedHash);
      final hubPose = ring[hubIndex.clamp(0, hubCount - 1)];
      final disc = sunflowerDiscPoses(
        nodes.length - hubCount,
        plane: Pose(
          hubPose.position + hubPose.facing * 420,
          hubPose.rotation,
        ),
        spacing: 85,
      );
      poses.addAll(disc);
    }
    return LayoutGeometry.fromPoses(poses);
  }

  // --- transitions ---------------------------------------------------------------

  void _apply({bool initial = false}) {
    final built = _build();

    // New nodes burst from their relay (or the centre); vanishing ones fold
    // back the same way. Snapshotted BEFORE setScene: during the diff the
    // scene's own lists are mid-swap.
    scene.advancePoses();
    final positionByHash = <String, Vector3>{
      for (var i = 0; i < scene.renderNodes.length; i++)
        scene.renderNodes[i].data.hash: scene.poses[i].position,
    };
    Vector3 sourceOf(MeshEntity entity) {
      final relayHash = entity.nextHop;
      if (relayHash != null) {
        final at = positionByHash[relayHash];
        if (at != null) return at;
      }
      return Vector3.zero();
    }

    scene.setScene(
      built.scene,
      layout: built.layout,
      enterPoseOf: initial
          ? null
          : (node) => Pose(sourceOf(node.data), Quaternion.identity()),
      exitPoseOf: (node) => Pose(sourceOf(node.data), Quaternion.identity()),
      reframe: false,
    );

    _relight();
    resetView(immediate: initial);
    notifyListeners();
  }

  /// Chain highlighting never rebuilds the scene.
  void _relight() {
    if (_pathChain.isEmpty) {
      scene.highlightKeys = const <String>{};
      return;
    }
    scene.highlightKeys = <String>{
      for (final hash in _pathChain)
        hash == network.selfHash ? 'self' : 'n:$hash',
    };
  }

  // --- camera ----------------------------------------------------------------------

  void resetView({bool immediate = false}) {
    final expanded = _expandedHash;
    if (expanded != null) {
      _frameCluster(expanded, immediate: immediate);
      return;
    }
    final radius = scene.geometry.radius + 300;
    // Fitting the whole ego sphere on a portrait phone would shrink the core
    // to specks; frame the heart of it and let the fringe overflow — panning
    // is tethered, nothing gets lost.
    scene.camera.maxFrameDistance = _view == MeshView.ego ? 12500 : 24000;
    scene.camera.frameFacing(
      Pose(
        Vector3.zero(),
        lookAtQuaternion(Vector3.zero(), Vector3(0, 0.5, 1)),
      ),
      halfExtent: Vector3(radius, radius * 0.62, radius * 0.9),
      sceneRadius: radius,
      durationMs: immediate ? 0 : 1800,
    );
  }

  void _frameCluster(String hash, {bool immediate = false}) {
    scene.camera.maxFrameDistance = 9000;
    final id = scene.renderNodes.indexWhere((n) => n.data.hash == hash);
    if (id == -1) return;
    scene.advancePoses();
    final leaves = _expandedLeaves;
    // Frame the middle of the cluster from outside, along its axis.
    final anchor = scene.geometry.poses[id].position;
    final outward = anchor.length < 1
        ? Vector3(0, 0, 1)
        : anchor.normalized();
    if (_view == MeshView.god) {
      final extent = 85.0 * math.sqrt(leaves.length + 0.5) + 200;
      final centre = anchor + outward * 420;
      scene.camera.frameFacing(
        Pose(centre, lookAtQuaternion(centre, centre + outward)),
        halfExtent: Vector3(extent, extent * 0.8, extent),
        sceneRadius: extent + 400,
        durationMs: immediate ? 0 : 2000,
      );
      return;
    }
    // Ego: the cluster is a cone of hop shells behind the relay. Approach it
    // from off-axis — straight down the axis, self / relay / leaves all
    // collapse onto one line of sight; from the side, the hop shells read as
    // depth.
    final side = Vector3(outward.z, 0, -outward.x);
    final viewDirection =
        (outward + side * 0.9 + Vector3(0, 0.42, 0)).normalized();
    final centre = anchor + outward * (_kHopSpacing * 2.0);
    scene.camera.frameFacing(
      Pose(centre, lookAtQuaternion(centre, centre + viewDirection)),
      halfExtent: Vector3(
        _kHopSpacing * 2.4,
        _kHopSpacing * 2.6,
        _kHopSpacing * 2.0,
      ),
      sceneRadius: _kHopSpacing * 6,
      durationMs: immediate ? 0 : 2000,
    );
  }

  // --- interactions -----------------------------------------------------------------

  /// Taps: aggregates expand/collapse, everything else selects and lights its
  /// path back to self.
  void tapNode(int id) {
    if (id < 1 || id > scene.liveCount) return;
    final entity = scene.renderNodes[id - 1].data;

    if (entity.isAggregate) {
      if (_expandedHash == entity.hash) {
        collapse();
      } else {
        expand(entity.hash);
      }
      return;
    }
    if (scene.selectedId == id) {
      clearSelection();
      return;
    }
    scene.selectNode(id);
    _selectChainFor(entity);
    scene.advancePoses();
    scene.camera.flyToPoint(
      scene.geometry.poses[id - 1].position,
      distance: 1500,
    );
  }

  void _selectChainFor(MeshEntity entity) {
    if (entity.role == MeshRole.self) {
      _pathChain = const <String>[];
    } else if (entity.nextHop == null) {
      _pathChain = <String>[network.selfHash, entity.hash];
    } else {
      _pathChain = <String>[network.selfHash, entity.nextHop!, entity.hash];
    }
    _pathStep = _pathChain.isEmpty ? 0 : _pathChain.length - 1;
    _relight();
  }

  /// Walks the camera one stop along the lit path.
  void stepPath(int direction) {
    if (_pathChain.isEmpty) return;
    _pathStep = (_pathStep + direction).clamp(0, _pathChain.length - 1);
    final hash = _pathChain[_pathStep];
    final key = hash == network.selfHash ? 'self' : 'n:$hash';
    final id = scene.renderNodes.indexWhere((n) => keyOf(n.data) == key);
    if (id == -1) return;
    scene.selectNode(id + 1);
    _relight(); // selectNode does not touch highlights, but keep in sync
    scene.advancePoses();
    scene.camera.flyToPoint(
      scene.geometry.poses[id].position,
      distance: 1300,
      durationMs: 1400,
    );
    notifyListeners();
  }

  void expand(String hash) {
    if (_expandedHash == hash) return;
    _expandedHash = hash;
    _apply();
  }

  void collapse() {
    if (_expandedHash == null) return;
    _expandedHash = null;
    _apply();
  }

  void setView(MeshView next) {
    if (_view == next) return;
    _view = next;
    _expandedHash = null;
    _pathChain = const <String>[];
    _pathStep = 0;
    scene.clearSelection();
    _apply();
  }

  void clearSelection() {
    _pathChain = const <String>[];
    _pathStep = 0;
    scene.highlightKeys = const <String>{};
    scene.clearSelection();
  }

  /// The escape ladder: selection → cluster → framing.
  void back() {
    if (scene.selectedKey != null || _pathChain.isNotEmpty) {
      clearSelection();
    } else if (_expandedHash != null) {
      collapse();
    } else {
      resetView();
    }
  }

  String get breadcrumb {
    final parts = <String>['mesh'];
    if (_view == MeshView.god) parts.add('backbone');
    if (_expandedHash != null) {
      parts.add(network.byHash(_expandedHash!).name);
    }
    final selected = selectedEntity;
    if (selected != null && selected.hash != _expandedHash) {
      parts.add(selected.name);
    }
    return parts.join(' › ');
  }

  @override
  void dispose() {
    scene.removeListener(_onSceneChanged);
    scene.dispose();
    super.dispose();
  }
}
