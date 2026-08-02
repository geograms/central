import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graph3d/graph3d.dart';

/// A viewport big enough that nothing is rejected for being off-screen.
final _viewport = Rect.fromLTWH(-500, -500, 1000, 1000);

LabelCandidate _c(
  int index,
  String key,
  Offset anchor, {
  double priority = 0,
  double depth = -1000,
  Size size = const Size(60, 14),
  double corePx = 6,
}) =>
    LabelCandidate(
      index: index,
      key: key,
      anchor: anchor,
      corePx: corePx,
      size: size,
      priority: priority,
      depth: depth,
    );

void main() {
  setUp(resetLabelSlots);

  test('a lone label takes the slot under its orb', () {
    final out = placeLabels(
      [_c(0, 'a', Offset.zero)],
      viewport: _viewport,
      budget: 40,
    );
    expect(out, hasLength(1));
    expect(out.single.slot, 0);
    // Centred horizontally, below the orb.
    expect(out.single.topLeft.dx, -30);
    expect(out.single.topLeft.dy, greaterThan(0));
  });

  test('two labels at the same point: the higher priority keeps slot 0', () {
    final out = placeLabels(
      [
        _c(0, 'low', Offset.zero, priority: 1),
        _c(1, 'high', Offset.zero, priority: 100),
      ],
      viewport: _viewport,
      budget: 40,
    );
    final byIndex = {for (final p in out) p.index: p};
    expect(byIndex[1]!.slot, 0, reason: 'winner keeps the natural position');
    // The loser is moved elsewhere or dropped — never left on top.
    if (byIndex.containsKey(0)) {
      expect(byIndex[0]!.slot, isNot(0));
      expect(
        Rect.fromLTWH(byIndex[0]!.topLeft.dx, byIndex[0]!.topLeft.dy, 60, 14)
            .overlaps(Rect.fromLTWH(
                byIndex[1]!.topLeft.dx, byIndex[1]!.topLeft.dy, 60, 14)),
        isFalse,
      );
    }
  });

  test('no two placed labels overlap, however tight the crowd', () {
    // Twelve nodes inside 40x40 px — the pathological case from the live
    // Reticulum view, where every peer projects into the same thumbprint.
    final crowd = [
      for (var i = 0; i < 12; i++)
        _c(i, 'n$i', Offset(i * 3.0 - 18, (i % 4) * 3.0 - 6), priority: 12.0 - i)
    ];
    final out = placeLabels(crowd, viewport: _viewport, budget: 40);
    for (var i = 0; i < out.length; i++) {
      for (var j = i + 1; j < out.length; j++) {
        final a = Rect.fromLTWH(out[i].topLeft.dx, out[i].topLeft.dy, 60, 14);
        final b = Rect.fromLTWH(out[j].topLeft.dx, out[j].topLeft.dy, 60, 14);
        expect(a.overlaps(b), isFalse, reason: 'labels $i and $j collide');
      }
    }
    expect(out.length, lessThan(crowd.length),
        reason: 'a crowd that cannot fit must lose some labels');
  });

  test('bright orb cores are never written over', () {
    final seed = Rect.fromCircle(center: Offset.zero, radius: 30);
    final out = placeLabels(
      [_c(0, 'a', Offset.zero, corePx: 26)],
      viewport: _viewport,
      budget: 40,
      seeds: [seed],
    );
    for (final p in out) {
      expect(
        Rect.fromLTWH(p.topLeft.dx, p.topLeft.dy, 60, 14).overlaps(seed),
        isFalse,
      );
    }
  });

  test('the budget caps placements, highest priority first', () {
    // Spread across the viewport (not past it — an off-screen label is
    // dropped before the budget ever sees it).
    final many = [
      for (var i = 0; i < 20; i++)
        _c(i, 'n$i', Offset(i * 40.0 - 400, 0), priority: i.toDouble())
    ];
    final out = placeLabels(many, viewport: _viewport, budget: 5);
    expect(out, hasLength(5));
    expect(out.map((p) => p.index).toSet(), {19, 18, 17, 16, 15});
  });

  test('identical input twice gives identical output', () {
    List<LabelPlacement> run() {
      resetLabelSlots();
      return placeLabels(
        [
          for (var i = 0; i < 8; i++)
            _c(i, 'n$i', Offset(i * 8.0, i.isEven ? 0 : 6), priority: 0)
        ],
        viewport: _viewport,
        budget: 40,
      );
    }

    final a = run();
    final b = run();
    expect(a.map((p) => (p.index, p.topLeft, p.slot)).toList(),
        b.map((p) => (p.index, p.topLeft, p.slot)).toList());
  });

  test('equal priority and depth still resolve deterministically by key', () {
    final out = placeLabels(
      [
        _c(0, 'zzz', Offset.zero),
        _c(1, 'aaa', Offset.zero),
      ],
      viewport: _viewport,
      budget: 40,
    );
    // 'aaa' sorts first, so it wins the natural slot.
    expect(out.first.index, 1);
    expect(out.first.slot, 0);
  });

  test('a label keeps the slot it had last frame', () {
    // Frame 1: two coincident labels, so the loser is pushed off slot 0.
    final first = placeLabels(
      [
        _c(0, 'a', Offset.zero, priority: 10),
        _c(1, 'b', Offset.zero, priority: 1),
      ],
      viewport: _viewport,
      budget: 40,
    );
    final loser = first.firstWhere((p) => p.index == 1, orElse: () => first.first);
    if (loser.index != 1) return; // dropped entirely: nothing to remember
    // Frame 2: 'b' alone would prefer slot 0, but remembers where it was.
    final second = placeLabels(
      [_c(1, 'b', Offset.zero, priority: 1)],
      viewport: _viewport,
      budget: 40,
    );
    expect(second.single.slot, loser.slot);
  });

  test('a label pushed off-screen is dropped, not clamped', () {
    final tiny = Rect.fromLTWH(-20, -20, 40, 40);
    final out = placeLabels(
      [_c(0, 'a', const Offset(400, 400))],
      viewport: tiny,
      budget: 40,
    );
    expect(out, isEmpty);
  });

  test('a label that would be clipped by the edge is dropped whole', () {
    // The orb is on screen but its 60px-wide name would run off the right
    // edge — a half-written name reads as a rendering bug.
    final narrow = Rect.fromLTWH(-100, -100, 200, 200);
    final out = placeLabels(
      [_c(0, 'a', const Offset(95, 0))],
      viewport: narrow,
      budget: 40,
    );
    for (final p in out) {
      final r = Rect.fromLTWH(p.topLeft.dx, p.topLeft.dy, 60, 14);
      expect(narrow.contains(r.topLeft), isTrue);
      expect(narrow.contains(r.bottomRight), isTrue);
    }
  });
}
