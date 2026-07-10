import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

/// Where a graph comes from. Swapping the implementation is all it takes to
/// point the app at a different TripleCheck run.
abstract class GraphDataSource {
  Future<GraphData> load();
}

/// Reads a bundle produced by `tool/convert_data.js` from the asset bundle.
class AssetGraphDataSource implements GraphDataSource {
  const AssetGraphDataSource([this.assetPath = 'assets/data/triplecheck.json']);

  final String assetPath;

  @override
  Future<GraphData> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return GraphData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

/// Reads the same bundle from a file, so a run can be dropped in without
/// rebuilding the app.
class FileGraphDataSource implements GraphDataSource {
  const FileGraphDataSource(this.path);

  final String path;

  @override
  Future<GraphData> load() async {
    final raw = await File(path).readAsString();
    return GraphData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
