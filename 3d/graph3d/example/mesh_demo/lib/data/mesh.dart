import 'dart:ui';

/// The transport an announce arrived over — Reticulum bridges them all.
enum Iface {
  ble('BLE', Color(0xFF7E8CE0)),
  lan('LAN', Color(0xFF35D0BA)),
  tcp('TCP', Color(0xFFE0A458)),
  udp('UDP', Color(0xFFB07BAC));

  const Iface(this.label, this.color);

  final String label;
  final Color color;
}

/// An internet hub: a Reticulum transport node relaying for many devices.
class MeshHub {
  const MeshHub({
    required this.hash,
    required this.name,
    required this.region,
    required this.devices,
  });

  /// 16-byte destination hash, hex.
  final String hash;

  /// Human name, e.g. `oslo-gw.9f2c`.
  final String name;
  final String region;
  final List<MeshDevice> devices;
}

/// A leaf device reachable through a hub — the shape of an RNS path entry:
/// destination hash, hops, the interface the announce came in on, and the
/// transport node relaying for it.
class MeshDevice {
  const MeshDevice({
    required this.destHash,
    required this.name,
    required this.iface,
    required this.hops,
    required this.nextHop,
  });

  final String destHash;
  final String name;
  final Iface iface;
  final int hops;

  /// The hub's destination hash.
  final String nextHop;

  String get shortHash => destHash.substring(0, 12);
}

/// A backbone connection between two hubs.
class HubLink {
  const HubLink(this.a, this.b, this.iface);

  /// Indices into the network's hub list.
  final int a;
  final int b;
  final Iface iface;
}

class MeshNetwork {
  const MeshNetwork({required this.hubs, required this.links});

  final List<MeshHub> hubs;
  final List<HubLink> links;

  int get deviceCount =>
      hubs.fold(0, (sum, hub) => sum + hub.devices.length);
}
