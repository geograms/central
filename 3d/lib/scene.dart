import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart';

import 'element_data.dart';

/// Position + orientation of one card in world space (y-up, right-handed,
/// camera looks down -z — the same convention three.js uses).
@immutable
class Pose {
  const Pose(this.position, this.rotation);

  final Vector3 position;
  final Quaternion rotation;

  Matrix4 get matrix => Matrix4.compose(position, rotation, Vector3.all(1));
}

Pose lerpPose(Pose a, Pose b, double t) => Pose(
  a.position + (b.position - a.position) * t,
  slerp(a.rotation, b.rotation, t),
);

/// Shortest-arc quaternion interpolation. vector_math ships no slerp.
Quaternion slerp(Quaternion a, Quaternion b, double t) {
  var cosHalfTheta = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
  var bx = b.x, by = b.y, bz = b.z, bw = b.w;
  if (cosHalfTheta < 0) {
    cosHalfTheta = -cosHalfTheta;
    bx = -bx;
    by = -by;
    bz = -bz;
    bw = -bw;
  }
  if (cosHalfTheta > 0.9995) {
    return Quaternion(
      a.x + (bx - a.x) * t,
      a.y + (by - a.y) * t,
      a.z + (bz - a.z) * t,
      a.w + (bw - a.w) * t,
    )..normalize();
  }
  final halfTheta = math.acos(cosHalfTheta);
  final sinHalfTheta = math.sqrt(1 - cosHalfTheta * cosHalfTheta);
  final ratioA = math.sin((1 - t) * halfTheta) / sinHalfTheta;
  final ratioB = math.sin(t * halfTheta) / sinHalfTheta;
  return Quaternion(
    a.x * ratioA + bx * ratioB,
    a.y * ratioA + by * ratioB,
    a.z * ratioA + bz * ratioB,
    a.w * ratioA + bw * ratioB,
  )..normalize();
}

/// Orientation whose +z axis points from [position] towards [target].
/// Mirrors three.js `Object3D.lookAt` for non-camera objects.
Quaternion _lookAt(Vector3 position, Vector3 target) {
  final up = Vector3(0, 1, 0);
  var z = target - position;
  if (z.length2 == 0) z.z = 1;
  z.normalize();

  var x = up.cross(z);
  if (x.length2 == 0) {
    // up and z are parallel — nudge z so the basis stays well defined.
    if (z.z.abs() == 1) {
      z.x += 0.0001;
    } else {
      z.z += 0.0001;
    }
    z.normalize();
    x = up.cross(z);
  }
  x.normalize();
  final y = z.cross(x);

  return Quaternion.fromRotation(
    Matrix3(x.x, x.y, x.z, y.x, y.y, y.z, z.x, z.y, z.z),
  );
}

enum Layout { table, sphere, helix, grid }

List<Pose> buildLayout(Layout layout) {
  final count = periodicTable.length;
  switch (layout) {
    case Layout.table:
      return <Pose>[
        for (final e in periodicTable)
          Pose(
            Vector3(e.col * 140.0 - 1330, -(e.row * 180.0) + 990, 0),
            Quaternion.identity(),
          ),
      ];

    case Layout.sphere:
      return <Pose>[
        for (var i = 0; i < count; i++) _spherePose(i, count),
      ];

    case Layout.helix:
      return <Pose>[
        for (var i = 0; i < count; i++) _helixPose(i),
      ];

    case Layout.grid:
      return <Pose>[
        for (var i = 0; i < count; i++)
          Pose(
            Vector3(
              (i % 5) * 400.0 - 800,
              -((i ~/ 5) % 5) * 400.0 + 800,
              (i ~/ 25) * 1000.0 - 2000,
            ),
            Quaternion.identity(),
          ),
      ];
  }
}

Pose _spherePose(int i, int count) {
  final phi = math.acos(-1 + (2 * i) / count);
  final theta = math.sqrt(count * math.pi) * phi;
  const radius = 800.0;
  final position = Vector3(
    radius * math.sin(phi) * math.sin(theta),
    radius * math.cos(phi),
    radius * math.sin(phi) * math.cos(theta),
  );
  // Face directly away from the sphere's centre.
  return Pose(position, _lookAt(position, position * 2.0));
}

Pose _helixPose(int i) {
  final theta = i * 0.175 + math.pi;
  final y = -(i * 8.0) + 450;
  const radius = 900.0;
  final position = Vector3(
    radius * math.sin(theta),
    y,
    radius * math.cos(theta),
  );
  // Face outwards from the helix axis, without tilting up or down.
  return Pose(
    position,
    _lookAt(position, Vector3(position.x * 2, position.y, position.z * 2)),
  );
}

/// Trackball-style camera orbiting [target] at [distance].
///
/// Releasing a drag leaves the camera spinning, shedding angular velocity
/// exponentially, the way TrackballControls' dynamic damping does.
class OrbitCamera extends ChangeNotifier {
  OrbitCamera({required TickerProvider vsync, this.rotateSpeed = mouseRotateSpeed}) {
    _ticker = vsync.createTicker(_onTick);
  }

  late final Ticker _ticker;

  Quaternion _rotation = Quaternion.identity();
  Vector3 _target = Vector3.zero();
  double _distance = 3000;

  Vector3 _spinAxis = Vector3(0, 1, 0);
  double _spinSpeed = 0; // radians per second
  Duration _lastTick = Duration.zero;

  static const double minDistance = 500;
  static const double maxDistance = 8000;

  /// Radians per unit of normalized drag, matching TrackballControls' default.
  static const double mouseRotateSpeed = 0.5;

  /// A drag is normalized against the shorter viewport side, which on a phone
  /// is roughly a third of a desktop window's. Left at [mouseRotateSpeed] the
  /// same finger travel would spin the scene about 2.5x further, so touch gets
  /// its own, gentler constant.
  static const double touchRotateSpeed = 0.2;

  /// How far [target] may stray from the origin. Without this the scene can be
  /// panned clean off-screen, leaving the user staring at empty space with no
  /// way to recover their bearings.
  static const double maxTargetRadius = 700;

  /// Angular velocity falls to 1/e of its value over this many seconds.
  static const double spinDecaySeconds = 0.35;

  /// Below this the spin is imperceptible, so the ticker shuts off.
  static const double minSpinSpeed = 0.05;

  /// Keeps a violent flick from turning into a blur.
  static const double maxSpinSpeed = 4;

  /// Radians per unit of normalized drag for this input device.
  final double rotateSpeed;

  double get distance => _distance;

  /// The point the camera orbits and keeps centred on screen.
  Vector3 get target => _target.clone();

  bool get isSpinning => _spinSpeed > 0;

  /// Halts any coasting spin. Call when a new drag grabs the scene.
  void stopSpin() {
    _spinSpeed = 0;
    _lastTick = Duration.zero;
    if (_ticker.isActive) _ticker.stop();
  }

  /// Hands the camera the pointer velocity (logical pixels/second) left over
  /// at the end of a drag, so the scene keeps turning and eases to a stop.
  void flingRotate(double vx, double vy, double viewportExtent) {
    final pixelsPerSecond = math.sqrt(vx * vx + vy * vy);
    if (pixelsPerSecond == 0) return;

    final speed = pixelsPerSecond / (viewportExtent / 2) * rotateSpeed;
    if (speed < minSpinSpeed) return;

    _spinAxis = Vector3(-vy, -vx, 0)..normalize();
    _spinSpeed = math.min(speed, maxSpinSpeed);
    _lastTick = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    // The first tick has no previous timestamp to difference against.
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = elapsed;
    if (dt <= 0) return;

    _rotation = (_rotation * Quaternion.axisAngle(_spinAxis, _spinSpeed * dt))
      ..normalize();
    _spinSpeed *= math.exp(-dt / spinDecaySeconds);
    if (_spinSpeed < minSpinSpeed) stopSpin();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// The camera's orientation as a basis whose columns are its right, up and
  /// backwards axes in world space.
  ///
  /// Deliberately not `Quaternion.rotated`: in vector_math that applies the
  /// *inverse* rotation, while `asRotationMatrix`, `Matrix4.compose` and
  /// `Quaternion.fromRotation` all apply the forward one. Mixing the two makes
  /// the camera orbit around a point it is not actually looking at, so the
  /// scene drifts off screen as you rotate.
  Matrix3 get _basis => _rotation.asRotationMatrix();

  /// World-to-camera transform. The camera sits at [target], offset along its
  /// own +z axis by [distance], looking back down that axis at the target.
  Matrix4 get viewMatrix {
    final eye = _target + _basis * Vector3(0, 0, _distance);
    return Matrix4.inverted(Matrix4.compose(eye, _rotation, Vector3.all(1)));
  }

  /// Drag delta in logical pixels. Rotates about camera-local axes so the
  /// surface under the pointer follows it.
  ///
  /// [viewportExtent] normalizes the drag, so the same gesture turns the scene
  /// by the same angle whatever the window size. TrackballControls measures the
  /// drag against half the viewport, so this does too.
  void rotate(double dx, double dy, double viewportExtent) {
    final pixels = math.sqrt(dx * dx + dy * dy);
    if (pixels == 0) return;
    final angle = pixels / (viewportExtent / 2) * rotateSpeed;
    final axis = Vector3(-dy, -dx, 0)..normalize();
    _rotation = (_rotation * Quaternion.axisAngle(axis, angle))..normalize();
    notifyListeners();
  }

  /// [factor] > 1 pushes the camera away, < 1 pulls it in.
  void zoomBy(double factor) {
    final next = (_distance * factor).clamp(minDistance, maxDistance);
    if (next == _distance) return;
    _distance = next;
    notifyListeners();
  }

  /// Pans in the camera's screen plane, scaled so the world tracks the pointer.
  ///
  /// The focus point is tethered to within [maxTargetRadius] of the origin, so
  /// some of the scene always stays on screen.
  void pan(double dx, double dy, double pixelsPerWorldUnit) {
    if (dx == 0 && dy == 0) return;
    final basis = _basis;
    final right = basis * Vector3(1, 0, 0);
    final up = basis * Vector3(0, 1, 0);
    final moved =
        _target + right * (-dx / pixelsPerWorldUnit) + up * (dy / pixelsPerWorldUnit);

    _target = moved.length > maxTargetRadius
        ? moved.normalized() * maxTargetRadius
        : moved;
    notifyListeners();
  }

  void reset() {
    stopSpin();
    _rotation = Quaternion.identity();
    _target = Vector3.zero();
    _distance = 3000;
    notifyListeners();
  }
}
