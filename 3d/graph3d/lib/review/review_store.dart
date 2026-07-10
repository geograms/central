import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models.dart';
import '../theme.dart';

/// Review verdicts, keyed by the full annotated match filename.
///
/// The dataset ships verdicts of its own; the user's are layered on top and
/// written to disk, one file per project, so reopening the app restores them.
class ReviewStore extends ChangeNotifier {
  ReviewStore._(this._file, this._states);

  /// An in-memory store, for tests and for platforms with no writable dir.
  ReviewStore.inMemory(Map<String, String> initial)
    : _file = null,
      _states = Map<String, String>.of(initial);

  final File? _file;
  final Map<String, String> _states;

  static Future<ReviewStore> open(GraphData data) async {
    File? file;
    final states = Map<String, String>.of(data.defaultReviews);
    try {
      final dir = await getApplicationSupportDirectory();
      file = File('${dir.path}/reviews/${data.storageKey}.json');
      if (file.existsSync()) {
        final saved = jsonDecode(await file.readAsString());
        if (saved is Map) {
          saved.forEach((key, value) {
            if (value is String) states[key as String] = value;
          });
        }
      }
    } on Exception catch (error) {
      // A corrupt or unreachable file must not stop the graph from opening;
      // the dataset's own verdicts are a fine starting point.
      debugPrint('review state not restored: $error');
      file = null;
    }
    return ReviewStore._(file, states);
  }

  ReviewState? stateFor(String filename) =>
      ReviewState.fromLabel(_states[filename]);

  /// The verdict shown on a file that has never been reviewed.
  ReviewState stateOrDefault(String filename) =>
      stateFor(filename) ?? ReviewState.unknown;

  /// Paths of every file carrying a verdict, for the `review` search.
  Set<String> get reviewedPaths => _states.keys
      .map((filename) {
        final bracket = filename.indexOf(' (');
        return bracket == -1 ? filename : filename.substring(0, bracket);
      })
      .toSet();

  Future<void> setState(String filename, ReviewState state) async {
    if (_states[filename] == state.label) return;
    _states[filename] = state.label;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final file = _file;
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(_states));
    } on Exception catch (error) {
      debugPrint('review state not saved: $error');
    }
  }
}
