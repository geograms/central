import 'dart:ui';

/// The network a device is reached over, grouped the way a person thinks
/// about them rather than by wire protocol: LAN and WiFi are one local
/// network, TCP and UDP are both just "the internet". The palette is the
/// visualization's primary code — blue, green, yellow, purple and red, far
/// apart on a dark background.
///
/// BLE, LAN/WiFi and internet transports are implemented in reticulum-dart
/// today; LoRa and packet radio exist in the wider RNS world and are
/// included forward-looking.
enum Iface {
  ble('BLE', Color(0xFF4FC3F7), speedRank: 1),
  lanWifi('LAN/WiFi', Color(0xFF66BB6A), speedRank: 3),
  internet('Internet', Color(0xFFFFD54F), speedRank: 2),
  lora('LoRa', Color(0xFFB388FF), speedRank: 1, forwardLooking: true),
  radio('Radio', Color(0xFFFF5252), speedRank: 1, forwardLooking: true);

  const Iface(
    this.label,
    this.color, {
    required this.speedRank,
    this.forwardLooking = false,
  });

  final String label;
  final Color color;

  /// Path preference, as reticulum-dart ranks interfaces.
  final int speedRank;

  /// Not yet implemented in the Dart stack.
  final bool forwardLooking;
}

/// What a node does in the mesh.
enum MeshRole {
  /// This device — the vantage point of the ego view.
  self,

  /// A plain direct neighbour.
  peer,

  /// An edge bridge: lives on two networks, relays edge→core (e.g. a phone
  /// bridging its BLE mesh onto an internet hub).
  bridge,

  /// A transport node relaying for many destinations — an internet hub.
  transport,

  /// A gateway onto a slow radio network (LoRa, packet radio).
  gateway,

  /// A destination reached through a relay.
  leaf,
}

/// One entity in the mesh, shaped like what a Reticulum path table plus a
/// vantage node's own knowledge can express.
class MeshEntity {
  const MeshEntity({
    required this.hash,
    required this.name,
    required this.role,
    required this.ifaces,
    required this.hops,
    this.nextHop,
    this.deviceCount = 0,
    this.region,
    this.distanceM,
  });

  /// 16-byte destination hash, hex.
  final String hash;
  final String name;
  final MeshRole role;

  /// The networks this entity lives on. Bridges and gateways carry two.
  final List<Iface> ifaces;

  /// Path length from self. 0 = self, 1 = direct neighbour.
  final int hops;

  /// Hash of the direct neighbour relaying for this entity; null when the
  /// entity IS a direct neighbour (or self). Matches RnsPathEntry semantics.
  final String? nextHop;

  /// For transports and gateways: how many destinations they relay that are
  /// aggregated behind them (the expandable cluster).
  final int deviceCount;

  final String? region;

  /// Estimated radio distance in metres to whoever hears this node
  /// directly: self for direct neighbours, its relay for mesh members.
  /// BLE meshes report this per hop (RSSI-derived).
  final double? distanceM;

  Iface get iface => ifaces.first;
  String get shortHash => hash.substring(0, 8);
  bool get isAggregate => deviceCount > 0;
}

/// A backbone connection between two transport hubs — the god view's edges.
/// (A single vantage node cannot see these; the god view is an aggregate.)
class HubLink {
  const HubLink(this.a, this.b, this.iface);

  /// Indices into [MeshNetwork.hubs].
  final int a;
  final int b;
  final Iface iface;
}

class MeshNetwork {
  const MeshNetwork({
    required this.selfHash,
    required this.entities,
    required this.clusterLeaves,
    required this.hubLinks,
  });

  /// The vantage node's hash; also present in [entities] with role self.
  final String selfHash;

  /// Everything the ego view always shows: self, direct neighbours, relays,
  /// gateways, bridges, and non-aggregated destinations.
  final List<MeshEntity> entities;

  /// The leaves aggregated behind each transport/gateway, keyed by its hash.
  /// Materialized only while that cluster is expanded.
  final Map<String, List<MeshEntity>> clusterLeaves;

  /// God-view backbone between transports.
  final List<HubLink> hubLinks;

  Iterable<MeshEntity> get hubs =>
      entities.where((e) => e.role == MeshRole.transport);

  MeshEntity byHash(String hash) =>
      entities.firstWhere((e) => e.hash == hash);

  int get totalDevices =>
      clusterLeaves.values.fold(entities.length, (sum, l) => sum + l.length);

  /// How many known devices live on each network type — everything the node
  /// has paths for, aggregated cluster members included. A dual-homed device
  /// counts on every network it touches.
  Map<Iface, int> get ifaceCounts {
    final counts = <Iface, int>{};
    void tally(MeshEntity entity) {
      if (entity.role == MeshRole.self) return;
      for (final iface in entity.ifaces) {
        counts[iface] = (counts[iface] ?? 0) + 1;
      }
    }

    entities.forEach(tally);
    for (final leaves in clusterLeaves.values) {
      leaves.forEach(tally);
    }
    return counts;
  }
}
