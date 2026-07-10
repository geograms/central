import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Quaternion, Vector3;

import 'element_data.dart';
import 'scene.dart';

void main() => runApp(const PeriodicTableApp());

class PeriodicTableApp extends StatelessWidget {
  const PeriodicTableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Periodic Table 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const PeriodicTablePage(),
    );
  }
}

/// Card footprint in world units, matching the CSS `.element` box.
const Size kCardSize = Size(120, 160);

/// Vertical field of view, as in the three.js PerspectiveCamera.
const double kFovRadians = 40 * math.pi / 180;

/// Each card takes between one and two times this to reach its target.
const Duration kBaseTransition = Duration(milliseconds: 1100);
const Duration kMaxTransition = Duration(milliseconds: 2200);

/// TWEEN.Easing.Exponential.InOut, which the original uses. Much snappier
/// through the middle than Flutter's cubic [Curves.easeInOut].
class ExponentialInOut extends Curve {
  const ExponentialInOut();

  @override
  double transformInternal(double t) {
    final k = t * 2;
    if (k < 1) return 0.5 * math.pow(1024, k - 1);
    return 0.5 * (2 - math.pow(2, -10 * (k - 1)));
  }
}

const Curve kTransitionCurve = ExponentialInOut();

class PeriodicTablePage extends StatefulWidget {
  const PeriodicTablePage({super.key});

  @override
  State<PeriodicTablePage> createState() => _PeriodicTablePageState();
}

class _PeriodicTablePageState extends State<PeriodicTablePage>
    with TickerProviderStateMixin {
  final math.Random _random = math.Random(4);

  late final OrbitCamera _camera;
  late final AnimationController _controller;
  late final List<double> _alphas;
  late final List<double> _durationsMs;

  late List<Pose> _start;
  late List<Pose> _target;
  late List<Pose> _current;

  Layout _layout = Layout.table;

  /// Screen pixels per world unit at the camera's focus plane. Keeps panning
  /// tracking the pointer instead of drifting as you zoom.
  double _pixelsPerWorldUnit = 1;

  /// Shortest viewport side, used to normalize rotation drags.
  double _viewportExtent = 1;

  double _lastScale = 1;

  /// Whether the gesture in flight is a one-finger rotate, so that letting go
  /// flings the scene rather than ending a pinch or a pan.
  bool _rotating = false;

  @override
  void initState() {
    super.initState();
    _camera = OrbitCamera(vsync: this, rotateSpeed: _rotateSpeedForPlatform);
    final count = periodicTable.length;

    _alphas =
        List<double>.generate(count, (_) => _random.nextDouble() * 0.5 + 0.25);
    _durationsMs = List<double>.filled(count, 0);

    // Cards fly in from random positions, exactly as the original does.
    _start = List<Pose>.generate(
      count,
      (_) => Pose(_randomPosition(), Quaternion.identity()),
    );
    _current = List<Pose>.of(_start);
    _target = buildLayout(Layout.table);

    _controller = AnimationController(vsync: this, duration: kMaxTransition);
    _randomizeDurations();
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _camera.dispose();
    super.dispose();
  }

  Vector3 _randomPosition() => Vector3(
    _random.nextDouble() * 4000 - 2000,
    _random.nextDouble() * 4000 - 2000,
    _random.nextDouble() * 4000 - 2000,
  );

  void _randomizeDurations() {
    final base = kBaseTransition.inMilliseconds.toDouble();
    for (var i = 0; i < _durationsMs.length; i++) {
      _durationsMs[i] = base + _random.nextDouble() * base;
    }
  }

  void _transitionTo(Layout layout) {
    if (layout == _layout && _controller.isCompleted) return;
    setState(() {
      _layout = layout;
      _start = List<Pose>.of(_current);
      _target = buildLayout(layout);
    });
    _randomizeDurations();
    _controller.forward(from: 0);
  }

  /// Advances every card towards its target at its own pace.
  void _advance() {
    final elapsedMs = _controller.value * kMaxTransition.inMilliseconds;
    for (var i = 0; i < _current.length; i++) {
      final t = (elapsedMs / _durationsMs[i]).clamp(0.0, 1.0);
      _current[i] =
          lerpPose(_start[i], _target[i], kTransitionCurve.transform(t));
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _camera.zoomBy(math.exp(event.scrollDelta.dy * 0.001));
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastScale = 1;
    _rotating = false;
    _camera.stopSpin(); // grabbing the scene halts any coast
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (!_rotating) return;
    final velocity = details.velocity.pixelsPerSecond;
    _camera.flingRotate(velocity.dx, velocity.dy, _viewportExtent);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2) {
      _rotating = false;
      final step = details.scale / _lastScale;
      _lastScale = details.scale;
      if (step > 0) _camera.zoomBy(1 / step);
      _camera.pan(
        details.focalPointDelta.dx,
        details.focalPointDelta.dy,
        _pixelsPerWorldUnit,
      );
    } else {
      _rotating = true;
      _camera.rotate(
        details.focalPointDelta.dx,
        details.focalPointDelta.dy,
        _viewportExtent,
      );
    }
  }

  bool get _isTouchPlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  double get _rotateSpeedForPlatform => _isTouchPlatform
      ? OrbitCamera.touchRotateSpeed
      : OrbitCamera.mouseRotateSpeed;

  /// Touch devices have no scroll wheel, and no mouse to hover with.
  String get _hintText {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return 'drag to rotate · pinch to zoom · two fingers to pan';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return 'drag to rotate · scroll to zoom · two fingers to pan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Listener(
              onPointerSignal: _onPointerSignal,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Distance at which a card renders at its natural size —
                    // the value CSS3DRenderer writes into `perspective`.
                    final perspective =
                        0.5 / math.tan(kFovRadians / 2) * constraints.maxHeight;
                    _pixelsPerWorldUnit = perspective / _camera.distance;
                    _viewportExtent =
                        math.min(constraints.maxWidth, constraints.maxHeight);

                    return AnimatedBuilder(
                      animation:
                          Listenable.merge(<Listenable>[_controller, _camera]),
                      builder: (context, _) {
                        _advance();
                        return _Css3dStack(
                          poses: _current,
                          alphas: _alphas,
                          view: _camera.viewMatrix,
                          perspective: perspective,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: SafeArea(
                bottom: false,
                child: Text(
                  _hintText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.cyanAccent.withValues(alpha: 0.5),
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: SafeArea(
                top: false,
                // Wraps to a second line rather than overflowing on a phone.
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final layout in Layout.values)
                      _LayoutButton(
                        label: layout.name.toUpperCase(),
                        selected: layout == _layout,
                        onPressed: () => _transitionTo(layout),
                      ),
                    _LayoutButton(
                      label: 'RESET VIEW',
                      selected: false,
                      onPressed: _camera.reset,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Projects every card through a full 4x4 matrix and paints them back to front.
///
/// Flutter has no depth buffer for widgets, so ordering happens here rather
/// than in the rasterizer. Flat cards never intersect, so a painter's-algorithm
/// sort on view-space depth is exact.
class _Css3dStack extends StatelessWidget {
  const _Css3dStack({
    required this.poses,
    required this.alphas,
    required this.view,
    required this.perspective,
  });

  final List<Pose> poses;
  final List<double> alphas;
  final Matrix4 view;
  final double perspective;

  @override
  Widget build(BuildContext context) {
    // World is y-up, the screen is y-down. Flipping on both sides of the model
    // transform keeps card contents upright.
    final flipY = Matrix4.diagonal3Values(1, -1, 1);
    final projection = Matrix4.identity()..setEntry(3, 2, -1 / perspective);
    final eyeShift = Matrix4.translationValues(0, 0, perspective);
    final clip = flipY * projection * eyeShift;

    final visible = <_ProjectedCard>[];
    for (var i = 0; i < poses.length; i++) {
      final modelView = view * poses[i].matrix;
      final depth = modelView.getTranslation().z;
      if (depth > -1) continue; // behind, or level with, the eye
      visible.add(_ProjectedCard(i, depth, clip * modelView * flipY));
    }

    // Most negative depth is farthest away, so it gets painted first.
    visible.sort((a, b) => a.depth.compareTo(b.depth));

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        for (final card in visible)
          Center(
            child: Transform(
              transform: card.matrix,
              alignment: Alignment.center,
              child: ElementCard(
                key: ValueKey<int>(card.index),
                index: card.index,
                element: periodicTable[card.index],
                alpha: alphas[card.index],
              ),
            ),
          ),
      ],
    );
  }
}

class _ProjectedCard {
  const _ProjectedCard(this.index, this.depth, this.matrix);

  final int index;
  final double depth;
  final Matrix4 matrix;
}

class ElementCard extends StatefulWidget {
  const ElementCard({
    super.key,
    required this.index,
    required this.element,
    required this.alpha,
  });

  final int index;
  final ChemElement element;
  final double alpha;

  @override
  State<ElementCard> createState() => _ElementCardState();
}

class _ElementCardState extends State<ElementCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: kCardSize.width,
        height: kCardSize.height,
        decoration: BoxDecoration(
          color: _hovered
              ? const Color.fromRGBO(0, 255, 255, 0.75)
              : Color.fromRGBO(0, 127, 127, widget.alpha),
          border: Border.all(
            color: _hovered
                ? const Color.fromRGBO(127, 255, 255, 0.75)
                : const Color.fromRGBO(127, 255, 255, 0.25),
          ),
          boxShadow: _hovered
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color.fromRGBO(0, 255, 255, 0.75),
                    blurRadius: 40,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 14,
              right: 14,
              child: Text(
                '${widget.index + 1}',
                style: const TextStyle(
                  color: Color.fromRGBO(127, 255, 255, 0.75),
                  fontSize: 12,
                ),
              ),
            ),
            Positioned(
              top: 36,
              left: 0,
              right: 0,
              child: Text(
                widget.element.symbol,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  height: 1.1,
                  fontWeight: FontWeight.w300,
                  shadows: <Shadow>[
                    Shadow(
                      color: Color.fromRGBO(0, 255, 255, 0.95),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 4,
              right: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    widget.element.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color.fromRGBO(127, 255, 255, 0.75),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    widget.element.mass,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color.fromRGBO(127, 255, 255, 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutButton extends StatelessWidget {
  const _LayoutButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.cyanAccent,
        backgroundColor: selected
            ? const Color.fromRGBO(0, 255, 255, 0.2)
            : Colors.transparent,
        side: BorderSide(
          color: Colors.cyanAccent.withValues(alpha: selected ? 0.9 : 0.4),
        ),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, letterSpacing: 1.1),
      ),
    );
  }
}
