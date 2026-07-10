import 'package:flutter/material.dart';

/// Colours lifted from the original `theme-default.css`.
abstract final class GraphColors {
  static const Color accent = Color(0xFF0A9999);

  /// The original's `rgba(0,0,0,0.6)` leaves the cards showing through the
  /// panel text. Opaque enough to read against a full table.
  static const Color panelBackground = Color(0xEE000000);
  static const Color panelText = Color(0xFF0A9999);
  static const Color link = Color(0xFF016161);

  static const Color cardTeal = Color(0xFF007F7F);
  static const Color cardRed = Color(0xFFEC001F);
  static const Color cardBorder = Color.fromRGBO(127, 255, 255, 0.25);
  static const Color cardBorderBright = Color.fromRGBO(127, 255, 255, 0.75);
  static const Color cardDetail = Color.fromRGBO(127, 255, 255, 0.75);
  static const Color symbol = Color.fromRGBO(255, 255, 255, 0.75);
  static const Color symbolInactive = Color.fromRGBO(4, 68, 68, 1);
  static const Color glowCyan = Color.fromRGBO(0, 255, 255, 0.95);
  static const Color glowRed = Color.fromRGBO(236, 0, 31, 0.95);
  static const Color boxGlow = Color.fromRGBO(0, 255, 255, 0.5);

  static const Color reviewUnknown = Color(0xFFFFAA00);
  static const Color reviewAttention = Color(0xFFFF00CF);
  static const Color reviewFailed = Color(0xFFFF4444);
  static const Color reviewAccepted = Color(0xFF00C853);
  static const Color reviewIgnore = Color(0xFF607D8B);
}

const TextStyle kMonospace = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: <String>['Courier New', 'DejaVu Sans Mono'],
  fontSize: 13,
  color: GraphColors.panelText,
  height: 1.35,
);

ThemeData buildGraphTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: base.colorScheme.copyWith(
      primary: GraphColors.accent,
      surface: Colors.black,
    ),
  );
}

/// The five verdicts a reviewer can record, in the order the original shows
/// them, with the glyph it prints on each button.
enum ReviewState {
  accepted('Accepted', '✓', GraphColors.reviewAccepted),
  failed('Failed', '✕', GraphColors.reviewFailed),
  ignore('Ignore', '//', GraphColors.reviewIgnore),
  unknown('Unknown', '?', GraphColors.reviewUnknown),
  attention('Attention', '!!', GraphColors.reviewAttention);

  const ReviewState(this.label, this.glyph, this.color);

  final String label;
  final String glyph;
  final Color color;

  static ReviewState? fromLabel(String? label) {
    if (label == null) return null;
    for (final state in values) {
      if (state.label == label) return state;
    }
    return null;
  }
}

/// The counters the review header shows, in its order of alarm.
const List<ReviewState> kCountedStates = <ReviewState>[
  ReviewState.unknown,
  ReviewState.attention,
  ReviewState.failed,
];

/// Files are listed most-alarming first within their type.
const List<ReviewState> kReviewSortOrder = <ReviewState>[
  ReviewState.unknown,
  ReviewState.failed,
  ReviewState.attention,
  ReviewState.accepted,
  ReviewState.ignore,
];
