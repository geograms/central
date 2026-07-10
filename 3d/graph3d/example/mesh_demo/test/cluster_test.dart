import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh_demo/cluster_controller.dart';
import 'package:mesh_demo/data/fake_network.dart';
import 'package:mesh_demo/mesh_node.dart';

class _TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void main() {
  test('the generator is deterministic and well-formed', () {
    final a = FakeNetwork.generate(seed: 7, hubCount: 12);
    final b = FakeNetwork.generate(seed: 7, hubCount: 12);
    expect(a.hubs.map((h) => h.hash), b.hubs.map((h) => h.hash));

    expect(a.hubs, hasLength(12));
    for (final hub in a.hubs) {
      expect(hub.hash, hasLength(32)); // 16 bytes hex
      expect(hub.devices.length, inInclusiveRange(50, 500));
      for (final device in hub.devices) {
        expect(device.nextHop, hub.hash);
        expect(device.hops, inInclusiveRange(1, 4));
      }
    }
    // Ring + chords, all endpoints valid.
    expect(a.links.length, greaterThanOrEqualTo(12));
    for (final link in a.links) {
      expect(link.a, inInclusiveRange(0, 11));
      expect(link.b, inInclusiveRange(0, 11));
      expect(link.a == link.b, isFalse);
    }
  });

  testWidgets('at most one cluster is ever materialized', (tester) async {
    final network = FakeNetwork.generate(seed: 3, hubCount: 6, maxDevices: 80);
    final cluster = MeshClusterController(
      network: network,
      vsync: _TestVSync(),
    );
    addTearDown(cluster.dispose);

    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      cluster.scene.advancePoses();
      await tester.pump();
      await tester.pump();
      cluster.scene.camera.stop();
      cluster.scene.clock.run(false);
      await tester.pump();
    }

    int devicesInScene() => cluster.scene.renderNodes
        .where((n) => n.data is DeviceNode)
        .length;

    await settle();
    expect(cluster.scene.liveCount, 6, reason: 'collapsed: hubs only');
    expect(devicesInScene(), 0);

    cluster.expand(network.hubs[0].hash);
    await settle();
    expect(
      cluster.scene.liveCount,
      6 + network.hubs[0].devices.length,
      reason: 'hubs plus exactly the open cluster',
    );

    // Switching hubs mid-everything: the old cluster leaves, the new enters,
    // and after settling only the new cluster's devices remain.
    cluster.expand(network.hubs[3].hash);
    await settle();
    expect(cluster.scene.liveCount, 6 + network.hubs[3].devices.length);
    expect(devicesInScene(), network.hubs[3].devices.length);

    cluster.collapse();
    await settle();
    expect(cluster.scene.liveCount, 6);
    expect(devicesInScene(), 0);
  });

  testWidgets('tapping a hub toggles it; tapping a leaf selects it', (
    tester,
  ) async {
    final network = FakeNetwork.generate(seed: 5, hubCount: 4, maxDevices: 60);
    final cluster = MeshClusterController(
      network: network,
      vsync: _TestVSync(),
    );
    addTearDown(cluster.dispose);

    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      cluster.scene.advancePoses();
      await tester.pump();
      await tester.pump();
      cluster.scene.camera.stop();
      cluster.scene.clock.run(false);
      await tester.pump();
    }

    await settle();
    cluster.tapNode(2); // a hub
    expect(cluster.expandedHubHash, network.hubs[1].hash);
    await settle();

    cluster.tapNode(5); // first device of the open cluster
    expect(cluster.scene.selectedKey, startsWith('dev:'));
    await settle();

    cluster.tapNode(2); // same hub again: collapse, selection released
    expect(cluster.expandedHubHash, isNull);
    await settle();
    expect(cluster.scene.selectedKey, isNull);
  });
}
