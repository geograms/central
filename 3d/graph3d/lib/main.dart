import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'data/graph_data_source.dart';
import 'data/models.dart';
import 'graph_page.dart';
import 'review/review_store.dart';
import 'theme.dart';

/// `--dart-define=GRAPH3D_FRAME_STATS=true` prints build and raster times every
/// few seconds. Rendering 426 perspective-transformed cards is the whole cost
/// of this app, so it needs to stay measurable on a real phone.
const bool kFrameStats = bool.fromEnvironment('GRAPH3D_FRAME_STATS');

void main() {
  if (kFrameStats) {
    WidgetsFlutterBinding.ensureInitialized();
    _reportFrameTimes();
  }
  runApp(const Graph3dApp());
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
    if (raster.length < 120) return;
    // ignore: avoid_print — this output is the point of the flag.
    print(
      'FRAMES n=${raster.length} '
      'build p50=${percentile(build, 0.5).toStringAsFixed(1)}ms '
      'p95=${percentile(build, 0.95).toStringAsFixed(1)}ms  '
      'raster p50=${percentile(raster, 0.5).toStringAsFixed(1)}ms '
      'p95=${percentile(raster, 0.95).toStringAsFixed(1)}ms',
    );
    build.clear();
    raster.clear();
  });
}

class Graph3dApp extends StatelessWidget {
  const Graph3dApp({super.key, this.source = const AssetGraphDataSource()});

  /// Swap this to point the app at another TripleCheck run.
  final GraphDataSource source;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripleCheck 3D',
      debugShowCheckedModeBanner: false,
      theme: buildGraphTheme(),
      home: _Loader(source: source),
    );
  }
}

class _Loader extends StatefulWidget {
  const _Loader({required this.source});

  final GraphDataSource source;

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  late Future<(GraphData, ReviewStore)> _load;

  @override
  void initState() {
    super.initState();
    _load = _open();
  }

  Future<(GraphData, ReviewStore)> _open() async {
    final data = await widget.source.load();
    return (data, await ReviewStore.open(data));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(GraphData, ReviewStore)>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load the graph:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: kMonospace,
                ),
              ),
            ),
          );
        }
        final loaded = snapshot.data;
        if (loaded == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: GraphColors.accent),
            ),
          );
        }
        return GraphPage(data: loaded.$1, reviewStore: loaded.$2);
      },
    );
  }
}
