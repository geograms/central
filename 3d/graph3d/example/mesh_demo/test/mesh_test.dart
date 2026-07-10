import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph3d/graph3d.dart';
import 'package:mesh_demo/data/fake_network.dart';
import 'package:mesh_demo/data/mesh.dart';
import 'package:mesh_demo/view_controller.dart';

class _TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void main() {
  group('FakeNetwork', () {
    test('is deterministic and honest about path semantics', () {
      final a = FakeNetwork.generate(seed: 7);
      final b = FakeNetwork.generate(seed: 7);
      expect(
        a.entities.map((e) => e.hash),
        b.entities.map((e) => e.hash),
      );

      final direct = <String>{
        for (final e in a.entities)
          if (e.hops <= 1) e.hash,
      };
      for (final entity in a.entities) {
        expect(entity.hash, hasLength(32));
        if (entity.role == MeshRole.self) {
          expect(entity.hops, 0);
          expect(entity.nextHop, isNull);
        } else if (entity.hops == 1) {
          expect(entity.nextHop, isNull, reason: 'direct = no nextHop');
        } else {
          expect(entity.nextHop, isNotNull);
          expect(
            direct.contains(entity.nextHop),
            isTrue,
            reason: 'a nextHop is always a direct neighbour',
          );
        }
      }

      // Bridges and gateways live on two networks.
      for (final entity in a.entities) {
        if (entity.role == MeshRole.bridge ||
            entity.role == MeshRole.gateway) {
          expect(entity.ifaces, hasLength(2));
        }
      }

      // Every aggregate has its leaves, and they all point back at it.
      for (final entity in a.entities.where((e) => e.isAggregate)) {
        final leaves = a.clusterLeaves[entity.hash]!;
        expect(leaves, hasLength(entity.deviceCount));
        for (final leaf in leaves) {
          expect(leaf.nextHop, entity.hash);
          expect(leaf.hops, inInclusiveRange(2, 6));
        }
      }

      // All seven interface types appear somewhere.
      final used = <Iface>{
        for (final e in a.entities) ...e.ifaces,
        for (final l in a.clusterLeaves.values)
          for (final e in l) ...e.ifaces,
      };
      expect(used, containsAll(Iface.values));
    });
  });

  group('iface stats and multi-homing', () {
    test('counts every device once per network it touches', () {
      final network = FakeNetwork.generate(seed: 42);
      final counts = network.ifaceCounts;

      // Dual-homed BLE+LAN peers exist and count on both networks.
      final dualHomed = network.entities
          .where((e) => e.ifaces.length >= 2 && e.role == MeshRole.peer)
          .toList();
      expect(dualHomed, isNotEmpty);

      var expectedBle = 0;
      void tally(MeshEntity e) {
        if (e.role != MeshRole.self && e.ifaces.contains(Iface.ble)) {
          expectedBle++;
        }
      }

      network.entities.forEach(tally);
      for (final leaves in network.clusterLeaves.values) {
        leaves.forEach(tally);
      }
      expect(counts[Iface.ble], expectedBle);
      // Every palette entry has at least one device somewhere.
      for (final iface in Iface.values) {
        expect(counts[iface], greaterThan(0), reason: iface.label);
      }
    });
  });

  group('MeshViewController', () {
    late MeshViewController controller;

    MeshViewController build() => MeshViewController(
      network: FakeNetwork.generate(seed: 5),
      vsync: _TestVSync(),
    );

    tearDown(() => controller.dispose());

    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      controller.scene.advancePoses();
      await tester.pump();
      await tester.pump();
      controller.scene.camera.stop();
      controller.scene.clock.run(false);
      await tester.pump();
    }

    testWidgets('ego layout: hop distance is radial distance', (tester) async {
      controller = build();
      await settle(tester);

      final scene = controller.scene;
      for (var i = 0; i < scene.liveCount; i++) {
        final entity = scene.renderNodes[i].data;
        final radius = scene.poses[i].position.length;
        switch (entity.hops) {
          case 0:
            expect(radius, 0);
          case 1:
            expect(
              radius,
              anyOf(closeTo(620, 1), closeTo(1300, 1)),
              reason: 'direct neighbours sit on the two inner shells',
            );
          default:
            expect(
              radius,
              closeTo(1300 + 340.0 * (entity.hops - 1), 1),
              reason: 'destination radius encodes its hop count',
            );
        }
      }
    });

    testWidgets('one cluster max, in both views', (tester) async {
      controller = build();
      await settle(tester);
      final base = controller.scene.liveCount;
      final hub = controller.network.hubs.first;

      controller.expand(hub.hash);
      await settle(tester);
      expect(controller.scene.liveCount, base + hub.deviceCount);

      final other = controller.network.hubs.elementAt(1);
      controller.expand(other.hash);
      await settle(tester);
      expect(controller.scene.liveCount, base + other.deviceCount);

      controller.setView(MeshView.god);
      await settle(tester);
      expect(controller.expandedHash, isNull, reason: 'toggle collapses');
      // God view: transports + gateway only.
      expect(
        controller.scene.liveCount,
        controller.network.hubs.length + 1,
      );

      controller.setView(MeshView.ego);
      await settle(tester);
      expect(controller.scene.liveCount, base);
    });

    testWidgets('hub orbs keep their key across the view toggle', (
      tester,
    ) async {
      controller = build();
      await settle(tester);
      final hubKeys = <String>{
        for (final hub in controller.network.hubs) 'n:${hub.hash}',
      };
      final egoKeys = <String>{
        for (final n in controller.scene.renderNodes) n.key,
      };
      expect(egoKeys.containsAll(hubKeys), isTrue);

      controller.setView(MeshView.god);
      final godKeys = <String>{
        for (final n in controller.scene.renderNodes) n.key,
      };
      expect(
        godKeys.containsAll(hubKeys),
        isTrue,
        reason: 'same keys = the toggle morphs hubs instead of replacing them',
      );
      await settle(tester);
    });

    testWidgets('selecting a destination lights its chain and walks it', (
      tester,
    ) async {
      controller = build();
      await settle(tester);
      final scene = controller.scene;

      // A multi-hop, non-aggregate destination.
      final id = 1 +
          scene.renderNodes.indexWhere(
            (n) => n.data.hops >= 2 && !n.data.isAggregate,
          );
      expect(id, greaterThan(0));
      controller.tapNode(id);

      final dest = scene.renderNodes[id - 1].data;
      expect(controller.pathChain, <String>[
        controller.network.selfHash,
        dest.nextHop!,
        dest.hash,
      ]);
      expect(scene.highlightKeys, hasLength(3));
      expect(controller.pathStep, 2, reason: 'starts at the destination');

      controller.stepPath(-1);
      expect(controller.selectedEntity!.hash, dest.nextHop);
      controller.stepPath(-1);
      expect(controller.selectedEntity!.role, MeshRole.self);
      controller.stepPath(-1);
      expect(controller.pathStep, 0, reason: 'clamped at self');
      controller.stepPath(1);
      expect(controller.selectedEntity!.hash, dest.nextHop);

      controller.clearSelection();
      expect(controller.pathChain, isEmpty);
      expect(scene.highlightKeys, isEmpty);
      await settle(tester);
    });

    testWidgets('tapping an aggregate expands it; back() walks the ladder', (
      tester,
    ) async {
      controller = build();
      await settle(tester);
      final scene = controller.scene;
      final hub = controller.network.hubs.first;
      final hubId =
          1 + scene.renderNodes.indexWhere((n) => n.data.hash == hub.hash);

      controller.tapNode(hubId);
      expect(controller.expandedHash, hub.hash);
      await settle(tester);

      // Select a leaf, then back() unwinds selection first, cluster second.
      final leafId = 1 +
          scene.renderNodes.indexWhere(
            (n) => n.data.nextHop == hub.hash && !n.data.isAggregate,
          );
      controller.tapNode(leafId);
      expect(scene.selectedKey, isNotNull);

      controller.back();
      expect(scene.selectedKey, isNull);
      expect(controller.expandedHash, hub.hash);

      controller.back();
      expect(controller.expandedHash, isNull);
      await settle(tester);
    });

    testWidgets('a dual-homed peer has one edge back to self per network', (
      tester,
    ) async {
      controller = build();
      await settle(tester);
      final scene = controller.scene;

      final dualId = 1 +
          scene.renderNodes.indexWhere(
            (n) =>
                n.data.role == MeshRole.peer && n.data.ifaces.length == 2,
          );
      expect(dualId, greaterThan(0));

      final toDual = scene.edges.where((e) => e.to == dualId).toList();
      expect(toDual, hasLength(2), reason: 'one link per shared network');
      final colors = toDual.map((e) => e.style.color.toARGB32()).toSet();
      expect(colors, hasLength(2), reason: 'each in its own network colour');
      final offsets = toDual.map((e) => e.style.offsetPx).toSet();
      expect(offsets, hasLength(2), reason: 'drawn as parallel lanes');
      // Both connect back to self.
      for (final edge in toDual) {
        expect(scene.renderNodes[edge.from - 1].data.role, MeshRole.self);
      }
    });

    testWidgets('focusing a network lights exactly its members', (
      tester,
    ) async {
      controller = build();
      await settle(tester);
      final scene = controller.scene;

      controller.focusIface(Iface.ble);
      expect(controller.focusedIface, Iface.ble);
      expect(controller.breadcrumb, contains('BLE'));

      for (var i = 0; i < scene.liveCount; i++) {
        final entity = scene.renderNodes[i].data;
        if (entity.role == MeshRole.self) continue;
        final lit = scene.emphasisOf(i + 1) == CardEmphasis.highlighted;
        expect(
          lit,
          entity.ifaces.contains(Iface.ble),
          reason: '\${entity.name} lit=\$lit',
        );
      }

      // Same chip again lets go.
      controller.focusIface(Iface.ble);
      expect(controller.focusedIface, isNull);
      expect(scene.highlightKeys, isEmpty);
      await settle(tester);
    });

    testWidgets('sector containment: neighbours sit in their iface sector', (
      tester,
    ) async {
      controller = build();
      await settle(tester);
      final scene = controller.scene;

      // Group direct neighbours by iface and check azimuth ordering is
      // consistent: all members of one iface stay contiguous.
      final azimuthByIface = <Iface, List<double>>{};
      for (var i = 0; i < scene.liveCount; i++) {
        final entity = scene.renderNodes[i].data;
        if (entity.hops != 1) continue;
        final p = scene.poses[i].position;
        azimuthByIface
            .putIfAbsent(entity.iface, () => <double>[])
            .add((math.atan2(p.x, p.z) + 2 * math.pi) % (2 * math.pi));
      }
      // Sector spans must not overlap: max of one iface's span stays below
      // the min of the next when sorted by their mean.
      final spans = azimuthByIface.values
          .map(
            (a) => (
              a.reduce(math.min),
              a.reduce(math.max),
            ),
          )
          .toList()
        ..sort((x, y) => x.$1.compareTo(y.$1));
      for (var i = 1; i < spans.length; i++) {
        expect(
          spans[i].$1,
          greaterThanOrEqualTo(spans[i - 1].$2 - 1e-9),
          reason: 'iface sectors do not interleave',
        );
      }
    });
  });
}
