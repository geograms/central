import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph3d/graph3d.dart';

SceneNode<String> _node(String key) => SceneNode<String>(key: key, data: key);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CardBakery<String> bakery({int maxEntries = 4, double scale = 1.0}) =>
      CardBakery<String>(
        paint: (canvas, data, alpha) {
          canvas.drawRect(
            const Rect.fromLTWH(0, 0, kCardWidth, kCardHeight),
            Paint()..color = const Color(0xFF00FFFF),
          );
        },
        scaleOf: (_) => scale,
        maxEntries: maxEntries,
      );

  test('bakes once per key and reuses the image', () {
    final cache = bakery();
    final first = cache.imageFor(_node('a'), 0.5);
    final again = cache.imageFor(_node('a'), 0.5);
    expect(identical(first, again), isTrue);
    expect(cache.length, 1);
    cache.dispose();
  });

  test('scaleOf sets the texture size', () {
    final cache = bakery(scale: 1.5);
    final image = cache.imageFor(_node('a'), 0.5);
    expect(image.width, (kCardWidth * 1.5).round());
    expect(image.height, (kCardHeight * 1.5).round());
    cache.dispose();
  });

  test('evicts least-recently-used beyond maxEntries', () {
    final cache = bakery(maxEntries: 2);
    final a = cache.imageFor(_node('a'), 0.5);
    cache.imageFor(_node('b'), 0.5);
    cache.imageFor(_node('a'), 0.5); // touch a: b is now the oldest
    cache.imageFor(_node('c'), 0.5); // evicts b
    expect(cache.length, 2);

    // a survived the eviction (same instance), b did not.
    expect(identical(cache.imageFor(_node('a'), 0.5), a), isTrue);
    // b was disposed; using it would throw. Re-baking gives a fresh image.
    final b2 = cache.imageFor(_node('b'), 0.5);
    expect(b2.debugDisposed, isFalse);
    cache.dispose();
  });

  test('evictWhere drops a whole prefix, e.g. a collapsed cluster', () {
    final cache = bakery(maxEntries: 10);
    for (final key in <String>['hub:1', 'dev:1/a', 'dev:1/b', 'dev:2/a']) {
      cache.imageFor(_node(key), 0.5);
    }
    cache.evictWhere((key) => key.startsWith('dev:1/'));
    expect(cache.length, 2);
    cache.dispose();
  });
}
