import 'dart:math' as math;

import 'mesh.dart';

/// Deterministic dummy data shaped like a Reticulum mesh: a backbone ring of
/// transport hubs with random chords, each hub relaying for a crowd of leaf
/// devices announced over BLE, LAN, TCP or UDP.
class FakeNetwork {
  static const List<String> _cities = <String>[
    'oslo', 'porto', 'berlin', 'tokyo', 'quito', 'accra', 'delhi', 'perth',
    'lima', 'cairo', 'seoul', 'boston', 'dakar', 'hanoi', 'turin', 'quebec',
    'malmo', 'kyoto', 'bergen', 'braga', 'basel', 'ghent', 'tartu', 'vaasa',
    'split', 'arhus', 'brno', 'graz', 'leon', 'oulu', 'pisa', 'riga',
    'sion', 'trier', 'umea', 'vigo', 'wels', 'york', 'zadar', 'evora',
  ];

  static const List<String> _deviceKinds = <String>[
    'node', 'sensor', 'gate', 'cam', 'relay', 'meter', 'beacon', 'pager',
    'probe', 'kiosk', 'buoy', 'tag',
  ];

  /// Leaf announces skew towards the short-range transports; the backbone
  /// between hubs skews towards the internet ones.
  static const List<Iface> _leafIfaces = <Iface>[
    Iface.ble, Iface.ble, Iface.ble, Iface.lan, Iface.lan, Iface.tcp,
    Iface.udp,
  ];
  static const List<Iface> _backboneIfaces = <Iface>[
    Iface.tcp, Iface.tcp, Iface.tcp, Iface.udp, Iface.udp, Iface.lan,
  ];

  static String _hex(math.Random random, int bytes) {
    const digits = '0123456789abcdef';
    final buffer = StringBuffer();
    for (var i = 0; i < bytes * 2; i++) {
      buffer.write(digits[random.nextInt(16)]);
    }
    return buffer.toString();
  }

  static MeshNetwork generate({
    int seed = 42,
    int hubCount = 28,
    int minDevices = 50,
    int maxDevices = 500,
  }) {
    final random = math.Random(seed);

    final hubs = <MeshHub>[];
    for (var i = 0; i < hubCount; i++) {
      final hash = _hex(random, 16);
      final city = _cities[i % _cities.length];
      final name = '$city-gw.${hash.substring(0, 4)}';
      final deviceCount =
          minDevices + random.nextInt(maxDevices - minDevices + 1);

      final devices = <MeshDevice>[
        for (var d = 0; d < deviceCount; d++)
          () {
            final destHash = _hex(random, 16);
            final kind = _deviceKinds[random.nextInt(_deviceKinds.length)];
            return MeshDevice(
              destHash: destHash,
              name: '$kind-${destHash.substring(0, 4)}',
              iface: _leafIfaces[random.nextInt(_leafIfaces.length)],
              // One hop to the hub, plus however deep the local mesh runs.
              hops: 1 + random.nextInt(4),
              nextHop: hash,
            );
          }(),
      ];

      hubs.add(
        MeshHub(
          hash: hash,
          name: name,
          region: 'region-${(i ~/ 6) + 1}',
          devices: devices,
        ),
      );
    }

    // Backbone: a ring keeps the graph connected, chords make it a mesh.
    final links = <HubLink>[
      for (var i = 0; i < hubCount; i++)
        HubLink(
          i,
          (i + 1) % hubCount,
          _backboneIfaces[random.nextInt(_backboneIfaces.length)],
        ),
    ];
    final chords = hubCount ~/ 3;
    final seen = <String>{for (final l in links) '${l.a}-${l.b}'};
    var attempts = 0;
    while (links.length < hubCount + chords && attempts < 200) {
      attempts++;
      final a = random.nextInt(hubCount);
      final b = random.nextInt(hubCount);
      if (a == b) continue;
      final lo = math.min(a, b);
      final hi = math.max(a, b);
      if (!seen.add('$lo-$hi')) continue;
      links.add(
        HubLink(lo, hi, _backboneIfaces[random.nextInt(_backboneIfaces.length)]),
      );
    }

    return MeshNetwork(hubs: hubs, links: links);
  }
}
