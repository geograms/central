import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:graph3d/graph3d.dart';

import 'data/fake_network.dart';
import 'data/mesh.dart';
import 'theme.dart';
import 'view_controller.dart';
import 'widgets/backdrop.dart';
import 'widgets/holo_panel.dart';

/// Azimuth drift while the scene is left alone, radians per second.
/// `--dart-define=MESH_NO_DRIFT=true` pins the camera for scripted testing.
const double kIdleDrift =
    bool.fromEnvironment('MESH_NO_DRIFT') ? 0 : 0.05;
const Duration kIdleDelay = Duration(seconds: 30);

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
  late MeshViewController _controller;
  Timer? _idleTimer;
  int _seed = 42;

  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    _controller = MeshViewController(
      network: FakeNetwork.generate(seed: _seed),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.resetView(immediate: true);
      _armIdle();
    });
  }

  void _reseed() {
    final old = _controller;
    setState(() {
      _seed += 1;
      _create();
    });
    old.dispose();
  }

  /// Any touch stops the cinematic drift; stillness brings it back.
  void _wakeFromIdle() {
    _controller.scene.camera.idleDriftSpeed = 0;
    _armIdle();
  }

  void _armIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(kIdleDelay, () {
      if (mounted) _controller.scene.camera.idleDriftSpeed = kIdleDrift;
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _controller.back,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Listener(
            onPointerDown: (_) => _wakeFromIdle(),
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: <Widget>[
                const Positioned.fill(child: Backdrop()),
                Positioned.fill(
                  child: Graph3DView<MeshEntity>.sprites(
                    key: ValueKey<int>(_seed),
                    controller: _controller.scene,
                    spriteOf: (node) => spriteOfEntity(
                      node,
                      hubScale:
                          _controller.view == MeshView.god ? 2.6 : 1.0,
                    ),
                    initialReframe: false,
                    onNodeTap: _controller.tapNode,
                    onBackgroundDoubleTap: _controller.back,
                  ),
                ),
                HoloPanel(controller: _controller),
                _TopBar(controller: _controller),
                _BottomBar(
                  controller: _controller,
                  onReseed: _reseed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final MeshViewController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  controller.breadcrumb,
                  style: kMono.copyWith(color: kTextDim, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ViewToggle(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.controller});

  final MeshViewController controller;

  @override
  Widget build(BuildContext context) {
    Widget option(MeshView view, String label) {
      final active = controller.view == view;
      return GestureDetector(
        onTap: () => controller.setView(view),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: active ? kAccent.withValues(alpha: 0.18) : null,
            border: Border.all(
              color: kAccent.withValues(alpha: active ? 0.9 : 0.3),
            ),
          ),
          child: Text(
            label,
            style: kMono.copyWith(
              fontSize: 11,
              color: active ? kAccent : kTextDim,
            ),
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        option(MeshView.ego, 'MY NODE'),
        const SizedBox(width: 4),
        option(MeshView.god, 'BACKBONE'),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller, required this.onReseed});

  final MeshViewController controller;
  final VoidCallback onReseed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _Legend(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    if (controller.expandedHash != null)
                      _BarButton('COLLAPSE', onPressed: controller.collapse),
                    _BarButton('RESET VIEW', onPressed: controller.resetView),
                    _BarButton('RESEED', onPressed: onReseed),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (final iface in Iface.values)
          Opacity(
            opacity: iface.forwardLooking ? 0.55 : 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: iface.color,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: iface.color.withValues(alpha: 0.7),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  iface.forwardLooking ? '${iface.label}*' : iface.label,
                  style: kMono.copyWith(fontSize: 10.5, color: kTextDim),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton(this.label, {required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: kAccent,
        side: BorderSide(color: kAccent.withValues(alpha: 0.45)),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11.5, letterSpacing: 1.1),
      ),
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
