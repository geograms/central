import 'package:flutter/foundation.dart';

/// One file in the project, drawn as a card in the graph.
@immutable
class GraphNode {
  const GraphNode({
    required this.id,
    required this.sourceId,
    required this.symbol,
    required this.name,
    required this.license,
    required this.column,
    required this.row,
    required this.tag,
    required this.riskyLicense,
    required this.hasCopyright,
  });

  factory GraphNode.fromJson(Map<String, dynamic> json, int id) => GraphNode(
    id: id,
    sourceId: json['id'] as int,
    symbol: json['symbol'] as String,
    name: json['name'] as String,
    license: json['license'] as String,
    column: json['column'] as int,
    row: json['row'] as int,
    tag: json['tag'] as String,
    riskyLicense: json['riskyLicense'] as bool,
    hasCopyright: json['hasCopyright'] as bool,
  );

  /// One-based position in the node list. This, not [sourceId], is what a link
  /// endpoint names and what the rest of the app keys on.
  final int id;

  /// The id the analyser recorded. It is neither ordered nor unique — 19 of the
  /// 426 files share one — so nothing may be looked up by it.
  final int sourceId;

  /// Three-letter abbreviation printed large on the card.
  final String symbol;

  /// Abbreviated file name printed under the symbol.
  final String name;
  final String license;
  final int column;
  final int row;

  /// Coarse file classification: config, source, image, ...
  final String tag;

  /// Draws the card red rather than teal.
  final bool riskyLicense;
  final bool hasCopyright;
}

@immutable
class FileDetail {
  const FileDetail({
    required this.id,
    required this.sourceId,
    required this.sha1,
    required this.size,
    required this.linesOfCode,
    required this.license,
    required this.copyright,
    required this.path,
  });

  factory FileDetail.fromJson(Map<String, dynamic> json, int id) => FileDetail(
    id: id,
    sourceId: json['id'] as int,
    sha1: json['sha1'] as String,
    size: json['size'] as int,
    linesOfCode: json['linesOfCode'] as int,
    license: json['license'] as String,
    copyright: json['copyright'] as String,
    path: json['path'] as String,
  );

  /// One-based position, matching the node at the same position.
  final int id;

  /// See [GraphNode.sourceId]: not an identity.
  final int sourceId;
  final String sha1;
  final int size;
  final int linesOfCode;
  final String license;
  final String copyright;

  /// Repository-relative path, e.g. `./project/src/Main.java`.
  final String path;

  static final RegExp _separator = RegExp(r'[\\/]');

  String get fileName => path.split(_separator).last;

  String get directory {
    final index = path.lastIndexOf(_separator);
    return index == -1 ? '' : path.substring(0, index + 1);
  }
}

@immutable
class GraphLink {
  const GraphLink(this.from, this.to);

  factory GraphLink.fromJson(Map<String, dynamic> json) =>
      GraphLink(json['from'] as int, json['to'] as int);

  final int from;
  final int to;

  bool get isSelfLink => from == to;
  bool touches(int id) => from == id || to == id;
}

/// A binary-similarity hit: one hash algorithm, one percentage, one reference.
@immutable
class BinaryMatch {
  const BinaryMatch({
    required this.hash,
    required this.similarity,
    required this.reference,
  });

  factory BinaryMatch.fromJson(List<dynamic> json) => BinaryMatch(
    hash: json[0] as String,
    similarity: json[1] as String,
    reference: json.length > 2 ? json[2] as String : '',
  );

  final String hash;

  /// A percentage, but the source data stores it as text.
  final String similarity;

  /// May carry an HTML anchor; see `stripHtml` in `html_text.dart`.
  final String reference;
}

@immutable
class SourceSimilarity {
  const SourceSimilarity({
    required this.percent,
    required this.lines,
    required this.reference,
  });

  factory SourceSimilarity.fromJson(Map<String, dynamic> json) =>
      SourceSimilarity(
        percent: (json['percent'] as num).toInt(),
        lines: json['lines'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
      );

  final int percent;
  final String lines;
  final String reference;
}

/// A source-code snippet from the project that resembles code found elsewhere.
@immutable
class SourceMatch {
  const SourceMatch({
    required this.lines,
    required this.code,
    required this.similarity,
  });

  factory SourceMatch.fromJson(Map<String, dynamic> json) => SourceMatch(
    lines: json['lines'] as String? ?? '',
    code: json['code'] as String? ?? '',
    similarity: <SourceSimilarity>[
      for (final s in (json['similarity'] as List<dynamic>? ?? const []))
        SourceSimilarity.fromJson(s as Map<String, dynamic>),
    ],
  );

  /// A line range, e.g. `97..111`.
  final String lines;

  /// HTML-escaped source text.
  final String code;
  final List<SourceSimilarity> similarity;
}

@immutable
class MatchFile {
  const MatchFile({
    required this.filename,
    required this.binaryMatches,
    required this.sourceMatches,
  });

  factory MatchFile.fromJson(Map<String, dynamic> json) => MatchFile(
    filename: json['filename'] as String,
    binaryMatches: <BinaryMatch>[
      for (final b in (json['matches_bin'] as List<dynamic>? ?? const []))
        BinaryMatch.fromJson(b as List<dynamic>),
    ],
    sourceMatches: <SourceMatch>[
      for (final s in (json['matches_source'] as List<dynamic>? ?? const []))
        SourceMatch.fromJson(s as Map<String, dynamic>),
    ],
  );

  /// Carries a trailing licence annotation, e.g. `./a/b.java (GPL-3.0)[97..111]`.
  /// This full string is the review key; [cleanName] is what it points at.
  final String filename;
  final List<BinaryMatch> binaryMatches;
  final List<SourceMatch> sourceMatches;

  /// The filename with its ` (licence)` annotation removed.
  String get cleanName {
    final bracket = filename.indexOf(' (');
    return bracket == -1 ? filename : filename.substring(0, bracket);
  }

  String get shortName => cleanName.split(RegExp(r'[\\/]')).last;
}

@immutable
class MatchGroup {
  const MatchGroup({required this.type, required this.files});

  factory MatchGroup.fromJson(Map<String, dynamic> json) => MatchGroup(
    type: json['type'] as String,
    files: <MatchFile>[
      for (final f in (json['files'] as List<dynamic>? ?? const []))
        MatchFile.fromJson(f as Map<String, dynamic>),
    ],
  );

  /// source, script, image, executable, archive, text or binary.
  final String type;
  final List<MatchFile> files;
}

@immutable
class Coder {
  const Coder({
    required this.id,
    required this.name,
    required this.lastName,
    required this.imageSrc,
  });

  factory Coder.fromJson(Map<String, dynamic> json) => Coder(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    imageSrc: json['imageSrc'] as String? ?? '',
  );

  final String id;
  final String name;
  final String lastName;
  final String imageSrc;

  String get displayName {
    final full = '$name $lastName'.trim();
    return full.isEmpty ? 'No-name' : full;
  }
}

@immutable
class ProjectInfo {
  const ProjectInfo({
    required this.name,
    required this.licence,
    required this.conflicts,
    required this.licences,
    required this.complete,
    required this.files,
    required this.linesOfCode,
    required this.summary,
  });

  factory ProjectInfo.fromJson(Map<String, dynamic> json) => ProjectInfo(
    name: json['name'] as String? ?? '',
    licence: json['licence'] as String? ?? '',
    conflicts: json['conflicts'] as String? ?? '',
    licences: <String>[
      for (final l in (json['licences'] as List<dynamic>? ?? const []))
        l as String,
    ],
    complete: json['complete'] as String? ?? '',
    files: (json['files'] as num?)?.toInt() ?? 0,
    linesOfCode: (json['linesOfCode'] as num?)?.toInt() ?? 0,
    summary: json['summary'] as String? ?? '',
  );

  final String name;
  final String licence;
  final String conflicts;
  final List<String> licences;
  final String complete;
  final int files;
  final int linesOfCode;

  /// Pre-rendered plain-text overview shown when nothing is selected.
  final String summary;
}

/// Everything one TripleCheck run produced, as the app consumes it.
@immutable
class GraphData {
  const GraphData({
    required this.project,
    required this.nodes,
    required this.links,
    required this.details,
    required this.coders,
    required this.matches,
    required this.defaultReviews,
  });

  factory GraphData.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'] as List<dynamic>;
    final rawDetails = json['details'] as List<dynamic>;

    // Nodes and details are parallel arrays, and a link endpoint is a one-based
    // index into both. Their `id` column is a source id that is neither ordered
    // nor unique, so it is kept for reference and never looked up. A length
    // mismatch would silently print one file's licence on another's card.
    if (rawNodes.length != rawDetails.length) {
      throw StateError(
        'node/detail count mismatch: ${rawNodes.length} vs ${rawDetails.length}',
      );
    }

    final nodes = <GraphNode>[
      for (var i = 0; i < rawNodes.length; i++)
        GraphNode.fromJson(rawNodes[i] as Map<String, dynamic>, i + 1),
    ];
    final details = <FileDetail>[
      for (var i = 0; i < rawDetails.length; i++)
        FileDetail.fromJson(rawDetails[i] as Map<String, dynamic>, i + 1),
    ];

    for (var i = 0; i < nodes.length; i++) {
      if (nodes[i].sourceId != details[i].sourceId) {
        throw StateError(
          'node and detail disagree at index $i: '
          '${nodes[i].sourceId} vs ${details[i].sourceId}',
        );
      }
    }

    final links = <GraphLink>[
      for (final l in json['links'] as List<dynamic>)
        GraphLink.fromJson(l as Map<String, dynamic>),
    ];
    for (final link in links) {
      if (link.from < 1 ||
          link.from > nodes.length ||
          link.to < 1 ||
          link.to > nodes.length) {
        throw StateError('link ${link.from} -> ${link.to} names no node');
      }
    }

    final reviews = <String, String>{};
    for (final entry in (json['reviewStates'] as List<dynamic>? ?? const [])) {
      final map = entry as Map<String, dynamic>;
      final review = map['review'] as String?;
      if (review != null && review.isNotEmpty) {
        reviews[map['filename'] as String] = review;
      }
    }

    return GraphData(
      project: ProjectInfo.fromJson(json['project'] as Map<String, dynamic>),
      nodes: nodes,
      details: details,
      links: links,
      coders: <Coder>[
        for (final c in json['coders'] as List<dynamic>? ?? const [])
          Coder.fromJson(c as Map<String, dynamic>),
      ],
      matches: <MatchGroup>[
        for (final m in json['matches'] as List<dynamic>? ?? const [])
          MatchGroup.fromJson(m as Map<String, dynamic>),
      ],
      defaultReviews: reviews,
    );
  }

  final ProjectInfo project;
  final List<GraphNode> nodes;
  final List<GraphLink> links;
  final List<FileDetail> details;
  final List<Coder> coders;
  final List<MatchGroup> matches;

  /// Review verdicts shipped with the dataset, keyed by full match filename.
  /// The user's own verdicts are layered over these at runtime.
  final Map<String, String> defaultReviews;

  int get nodeCount => nodes.length;

  GraphNode nodeById(int id) => nodes[id - 1];
  FileDetail detailById(int id) => details[id - 1];

  /// Distinguishes one dataset's saved reviews from another's.
  String get storageKey {
    final safe = project.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '${safe.isEmpty ? 'project' : safe}-$nodeCount';
  }
}
