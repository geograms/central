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

  group('BLE distances', () {
    test('every BLE link reports metres, mesh members from their relay', () {
      final network = FakeNetwork.generate(seed: 42);

      for (final entity in network.entities) {
        if (entity.role == MeshRole.self) continue;
        if (entity.hops == 1 && entity.ifaces.contains(Iface.ble)) {
          expect(entity.distanceM, isNotNull, reason: entity.name);
          expect(entity.distanceM, inInclusiveRange(1, 50));
        }
      }

      // The BLE bridge aggregates a mesh: count badge + per-member reports.
      final bridge = network.entities.firstWhere(
        (e) => e.role == MeshRole.bridge,
      );
      expect(bridge.isAggregate, isTrue);
      final mesh = network.clusterLeaves[bridge.hash]!;
      expect(mesh, hasLength(bridge.deviceCount));
      for (final member in mesh) {
        expect(member.nextHop, bridge.hash);
        expect(member.distanceM, isNotNull);
      }
    });

    testWidgets('BLE positions and edge labels encode the metres', (
      tester,
    ) async {
      final controller = MeshViewController(
        network: FakeNetwork.generate(seed: 5),
        vsync: _TestVSync(),
      );
      addTearDown(controller.dispose);
      Future<void> settle() async {
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
        controller.scene.advancePoses();
        await tester.pump();
        await tester.pump();
        controller.scene.camera.stop();
        controller.scene.clock.run(false);
        await tester.pump();
      }

      await settle();
      final scene = controller.scene;

      // Direct BLE peers: radius grows with metres.
      final blePeers = <(double, double)>[]; // (metres, radius)
      for (var i = 0; i < scene.liveCount; i++) {
        final entity = scene.renderNodes[i].data;
        if (entity.hops == 1 &&
            entity.role == MeshRole.peer &&
            entity.iface == Iface.ble) {
          blePeers.add((
            entity.distanceM!,
            scene.poses[i].position.length,
          ));
        }
      }
      expect(blePeers.length, greaterThanOrEqualTo(3));
      blePeers.sort((a, b) => a.$1.compareTo(b.$1));
      for (var i = 1; i < blePeers.length; i++) {
        expect(
          blePeers[i].$2,
          greaterThanOrEqualTo(blePeers[i - 1].$2),
          reason: 'farther in metres = farther from self',
        );
      }

      // Their edges carry the metre label.
      final labelled = scene.edges.where(
        (e) => e.style.label != null && e.style.label!.endsWith('m'),
      );
      expect(labelled.length, greaterThanOrEqualTo(blePeers.length));

      // Expanding the bridge materializes its mesh, with labelled edges.
      final bridge = controller.network.entities.firstWhere(
        (e) => e.role == MeshRole.bridge,
      );
      controller.expand(bridge.hash);
      await settle();
      final meshEdges = scene.edges.where(
        (e) =>
            e.style.label != null &&
            e.style.label!.endsWith('m') &&
            scene.renderNodes[e.from - 1].data.hash == bridge.hash,
      );
      expect(meshEdges.length, bridge.deviceCount);
      await settle();
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
            if (entity.distanceM != null &&
                entity.role == MeshRole.peer) {
              // BLE peers sit at their measured range.
              expect(
                radius,
                closeTo(
                  (330 + entity.distanceM! * 22).clamp(330.0, 1150.0),
                  1,
                ),
                reason: 'radius encodes the metres estimate',
              );
            } else {
              expect(
                radius,
                anyOf(closeTo(620, 1), closeTo(1300, 1)),
                reason: 'direct neighbours sit on the two inner shells',
              );
            }
          default:
            expect(
              radius,
              entity.distanceM != null
                  ? closeTo(1300 + 200 + entity.distanceM! * 18, 1)
                  : closeTo(1300 + 340.0 * (entity.hops - 1), 1),
              reason: 'destination radius encodes hops, or metres when known',
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
      // God view: self at the centre, plus transports, gateway and bridge.
      expect(
        controller.scene.liveCount,
        controller.network.hubs.length + 3,
      );
      // Self is present, wired to every hub plus the gateway and bridge.
      final scene = controller.scene;
      final selfId = 1 +
          scene.renderNodes.indexWhere((n) => n.data.role == MeshRole.self);
      expect(selfId, greaterThan(0));
      expect(scene.poses[selfId - 1].position.length, 0,
          reason: 'self sits at the centre of the backbone');
      final spokes = scene.edges.where((e) => e.touches(selfId)).length;
      expect(
        spokes,
        controller.network.hubs.length + 2,
        reason: 'one adapter spoke per hub, plus LoRa gateway and BLE bridge',
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
