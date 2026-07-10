import 'dart:math' as math;

import 'mesh.dart';

/// Deterministic dummy data shaped like one coherent Reticulum neighbourhood,
/// seen from a single vantage node ("self"), plus the aggregated backbone the
/// god view shows.
///
/// The honest parts mirror the real path-table semantics: every entity knows
/// only {hash, hops, via-interface, nextHop}; the intermediate relays of a
/// multi-hop path are NOT modelled, because a real node cannot know them.
class FakeNetwork {
  static const List<String> _cities = <String>[
    'oslo', 'porto', 'berlin', 'tokyo', 'quito', 'accra', 'delhi', 'perth',
    'lima', 'cairo', 'seoul', 'boston',
  ];

  static const List<String> _deviceKinds = <String>[
    'node', 'sensor', 'gate', 'cam', 'relay', 'meter', 'beacon', 'pager',
    'probe', 'kiosk', 'buoy', 'tag', 'tracker', 'valve',
  ];

  static String _hex(math.Random random, int bytes) {
    const digits = '0123456789abcdef';
    final buffer = StringBuffer();
    for (var i = 0; i < bytes * 2; i++) {
      buffer.write(digits[random.nextInt(16)]);
    }
    return buffer.toString();
  }

  static String _deviceName(math.Random random, String hash) =>
      '${_deviceKinds[random.nextInt(_deviceKinds.length)]}-${hash.substring(0, 4)}';

  static MeshNetwork generate({int seed = 42}) {
    final random = math.Random(seed);
    final entities = <MeshEntity>[];
    final clusterLeaves = <String, List<MeshEntity>>{};

    final selfHash = _hex(random, 16);
    entities.add(
      MeshEntity(
        hash: selfHash,
        name: 'this-node',
        role: MeshRole.self,
        ifaces: const <Iface>[Iface.ble, Iface.lanWifi, Iface.internet],
        hops: 0,
      ),
    );

    MeshEntity direct({
      required String name,
      required MeshRole role,
      required List<Iface> ifaces,
      int deviceCount = 0,
      String? region,
    }) {
      final hash = _hex(random, 16);
      final entity = MeshEntity(
        hash: hash,
        name: name,
        role: role,
        ifaces: ifaces,
        hops: 1,
        deviceCount: deviceCount,
        region: region,
      );
      entities.add(entity);
      return entity;
    }

    MeshEntity dest({
      required String via,
      required Iface iface,
      required int hops,
      MeshRole role = MeshRole.leaf,
      String? name,
    }) {
      final hash = _hex(random, 16);
      final entity = MeshEntity(
        hash: hash,
        name: name ?? _deviceName(random, hash),
        role: role,
        ifaces: <Iface>[iface],
        hops: hops,
        nextHop: via,
      );
      entities.add(entity);
      return entity;
    }

    // --- BLE neighbourhood: a local mesh around this device ---------------
    for (var i = 0; i < 9; i++) {
      // A few of these devices are also on the LAN — a laptop or a printer
      // reachable both ways. They get one link back to self per network.
      final dualHomed = i % 3 == 0;
      direct(
        name: _deviceName(random, _hex(random, 2)),
        role: MeshRole.peer,
        ifaces: dualHomed
            ? const <Iface>[Iface.ble, Iface.lanWifi]
            : const <Iface>[Iface.ble],
      );
    }
    // A bridge phone: BLE on our side, TCP up to the internet. Two BLE peers
    // are only reachable through it (2 hops).
    final bridge = direct(
      name: 'bridge-phone',
      role: MeshRole.bridge,
      ifaces: const <Iface>[Iface.ble, Iface.internet],
    );
    for (var i = 0; i < 2; i++) {
      dest(via: bridge.hash, iface: Iface.ble, hops: 2);
    }

    // --- LAN / WiFi ----------------------------------------------------------
    for (var i = 0; i < 7; i++) {
      direct(
        name: _deviceName(random, _hex(random, 2)),
        role: MeshRole.peer,
        ifaces: const <Iface>[Iface.lanWifi],
      );
    }

    // --- Internet hubs: transport nodes with big aggregated clusters ---------
    final hubs = <MeshEntity>[];
    for (var i = 0; i < 4; i++) {
      final hash = _hex(random, 16);
      final city = _cities[i * 3 % _cities.length];
      const iface = Iface.internet;
      final count = 80 + random.nextInt(421); // 80..500
      final hub = MeshEntity(
        hash: hash,
        name: '$city-gw.${hash.substring(0, 4)}',
        role: MeshRole.transport,
        ifaces: <Iface>[iface],
        hops: 1,
        deviceCount: count,
        region: 'region-${i + 1}',
      );
      entities.add(hub);
      hubs.add(hub);

      clusterLeaves[hash] = <MeshEntity>[
        for (var d = 0; d < count; d++)
          () {
            final leafHash = _hex(random, 16);
            return MeshEntity(
              hash: leafHash,
              name: _deviceName(random, leafHash),
              role: MeshRole.leaf,
              ifaces: <Iface>[iface],
              hops: 2 + random.nextInt(4),
              nextHop: hash,
            );
          }(),
      ];
    }

    // A few interesting destinations behind hubs, always visible (not
    // aggregated): far-away services at 2-5 hops.
    for (var i = 0; i < 6; i++) {
      final hub = hubs[i % hubs.length];
      dest(
        via: hub.hash,
        iface: hub.iface,
        hops: 2 + i % 4,
      );
    }

    // --- LoRa gateway + radio nodes: the slow long-range fringe -------------
    final lora = direct(
      name: 'lora-gw',
      role: MeshRole.gateway,
      ifaces: const <Iface>[Iface.lora, Iface.lanWifi],
      deviceCount: 24,
    );
    clusterLeaves[lora.hash] = <MeshEntity>[
      for (var d = 0; d < 24; d++)
        () {
          final leafHash = _hex(random, 16);
          return MeshEntity(
            hash: leafHash,
            name: _deviceName(random, leafHash),
            role: MeshRole.leaf,
            ifaces: const <Iface>[Iface.lora],
            hops: 2 + random.nextInt(5),
            nextHop: lora.hash,
          );
        }(),
    ];
    // Two packet-radio nodes, deep in the mesh, always visible.
    for (var i = 0; i < 2; i++) {
      dest(
        via: lora.hash,
        iface: Iface.radio,
        hops: 4 + i * 2,
        name: 'aprs-${_hex(random, 2)}',
      );
    }

    // --- God-view backbone (aggregated knowledge, not ego-visible) ----------
    final hubLinks = <HubLink>[
      for (var i = 0; i < hubs.length; i++)
        HubLink(i, (i + 1) % hubs.length, Iface.internet),
      HubLink(0, 2, Iface.internet),
    ];

    return MeshNetwork(
      selfHash: selfHash,
      entities: entities,
      clusterLeaves: clusterLeaves,
      hubLinks: hubLinks,
    );
  }
}
