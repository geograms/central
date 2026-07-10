import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:graph3d/graph3d.dart';

import 'cards.dart';
import 'cluster_controller.dart';
import 'data/fake_network.dart';
import 'mesh_node.dart';

void main() {
  if (kProfileScene) {
    WidgetsFlutterBinding.ensureInitialized();
    _reportFrameTimes();
  }
  runApp(const MeshDemoApp());
}

class MeshDemoApp extends StatelessWidget {
  const MeshDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reticulum Mesh 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const MeshPage(),
    );
  }
}

class MeshPage extends StatefulWidget {
  const MeshPage({super.key});

  @override
  State<MeshPage> createState() => _MeshPageState();
}

class _MeshPageState extends State<MeshPage> with TickerProviderStateMixin {
  late MeshClusterController _cluster;
  late CardBakery<MeshNode> _bakery;
  int _seed = 42;

  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    _cluster = MeshClusterController(
      network: FakeNetwork.generate(seed: _seed),
      vsync: this,
    );
    _bakery = CardBakery<MeshNode>(
      paint: paintMeshNode,
      // Hubs are few and get looked at; leaves are a crowd. 1x halves the
      // leaves' texture bill.
      scaleOf: (node) => node is HubNode ? 1.5 : 1.0,
      maxEntries: 700,
    );
    // The vantage depends on the viewport's aspect ratio, which the camera
    // only learns during the first layout pass.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _cluster.resetView(immediate: true),
    );
  }

  void _reseed() {
    final oldCluster = _cluster;
    final oldBakery = _bakery;
    setState(() {
      _seed += 1;
      _create();
    });
    oldCluster.dispose();
    oldBakery.dispose();
  }

  @override
  void dispose() {
    _cluster.dispose();
    _bakery.dispose();
    super.dispose();
  }

  Widget _buttons() {
    return AnimatedBuilder(
      animation: _cluster,
      builder: (context, _) => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: <Widget>[
          if (_cluster.expandedHubHash != null)
            _Button('COLLAPSE', onPressed: _cluster.collapse),
          _Button('RESET VIEW', onPressed: _cluster.resetView),
          _Button('RESEED', onPressed: _reseed),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _cluster.scene.clearSelection();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: <Widget>[
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _cluster,
                  builder: (context, _) => Graph3DView<MeshNode>(
                    key: ValueKey<int>(_seed),
                    controller: _cluster.scene,
                    bakery: _bakery,
                    initialReframe: false,
                    onNodeTap: _cluster.tapNode,
                    liveCardBuilder: (context, node, state) =>
                        LiveMeshCard(node: node, state: state),
                  ),
                ),
              ),
              if (wide) ...<Widget>[
                Positioned(
                  top: 12,
                  right: 12,
                  width: 320,
                  child: _InfoPanel(cluster: _cluster),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SafeArea(top: false, child: _buttons()),
                  ),
                ),
              ] else
                // Portrait: panel and buttons share the bottom, stacked so
                // they can never overlap.
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _InfoPanel(cluster: _cluster),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: _buttons(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button(this.label, {required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF80DEEA),
        side: const BorderSide(color: Color(0x8080DEEA)),
        shape: const RoundedRectangleBorder(),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, letterSpacing: 1)),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.cluster});

  final MeshClusterController cluster;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[cluster, cluster.scene]),
      builder: (context, _) {
        final scene = cluster.scene;
        final focusId = scene.focusId;
        final network = cluster.network;

        String title;
        List<(String, String)> rows;
        String? hint;

        if (focusId == null) {
          title = 'Reticulum mesh';
          rows = <(String, String)>[
            ('Hubs', '${network.hubs.length}'),
            ('Devices', '${network.deviceCount}'),
            ('Backbone links', '${network.links.length}'),
            if (cluster.expandedHub case final hub?)
              ('Expanded', '${hub.name} (${hub.devices.length})'),
          ];
          hint = 'tap a hub to open its cluster';
        } else {
          switch (scene.renderNodes[focusId - 1].data) {
            case HubNode(:final hub):
              title = hub.name;
              rows = <(String, String)>[
                ('Devices', '${hub.devices.length}'),
                ('Region', hub.region),
                ('Dest hash', hub.hash),
              ];
              hint = cluster.expandedHubHash == hub.hash
                  ? 'tap again to collapse'
                  : 'tap to expand';
            case DeviceNode(:final device, :final hubHash):
              final hub =
                  network.hubs.firstWhere((h) => h.hash == hubHash);
              title = device.name;
              rows = <(String, String)>[
                ('Dest hash', device.destHash),
                ('Interface', device.iface.label),
                ('Hops', '${device.hops}'),
                ('Next hop', '${hub.name} (${device.nextHop.substring(0, 8)})'),
              ];
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xEE000000),
            border: Border.all(color: const Color(0xFF00838F), width: 2),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF80DEEA),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: '$label: ',
                          style: const TextStyle(
                            color: Color(0x9980DEEA),
                          ),
                        ),
                        TextSpan(text: value),
                      ],
                    ),
                    style: const TextStyle(
                      color: Color(0xFFB2EBF2),
                      fontSize: 12.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              if (hint != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: const TextStyle(
                    color: Color(0x8080DEEA),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

void _reportFrameTimes() {
  final build = <double>[];
  final raster = <double>[];

  double percentile(List<double> values, double fraction) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.of(values)..sort();
    return sorted[((sorted.length - 1) * fraction).round()];
  }

  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      build.add(timing.buildDuration.inMicroseconds / 1000);
      raster.add(timing.rasterDuration.inMicroseconds / 1000);
    }
  });

  Timer.periodic(const Duration(seconds: 2), (_) {
    // ignore: avoid_print — this output is the point of the flag.
    print(
      'FRAMES n=${raster.length.toString().padLeft(3)} '
      'build p50=${percentile(build, 0.5).toStringAsFixed(1)}ms '
      'p95=${percentile(build, 0.95).toStringAsFixed(1)}ms  '
      'raster p50=${percentile(raster, 0.5).toStringAsFixed(1)}ms '
      'p95=${percentile(raster, 0.95).toStringAsFixed(1)}ms',
    );
    build.clear();
    raster.clear();
  });
}
