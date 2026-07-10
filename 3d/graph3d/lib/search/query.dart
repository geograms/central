import 'package:flutter/foundation.dart';

import '../data/models.dart';

/// The searchable fields, in the order the original tries them. A bare word
/// with no `field:` prefix is tested against each in turn and reports the first
/// that matches, which is why the order is also the display grouping.
const List<String> kSearchFields = <String>[
  'tag',
  'license',
  'name',
  'copyright',
  'path',
  'sha1',
];

/// One token of a query: a word, optionally preceded by an `AND`/`OR` operand
/// and a `field:` qualifier, optionally quoted to force a case-sensitive match.
@immutable
class SearchTerm {
  const SearchTerm({
    required this.word,
    this.operand,
    this.field,
    this.matchCase = false,
  });

  final String word;

  /// 'AND' or 'OR'. Only 'AND' changes anything: it makes this term a
  /// requirement of the one before it.
  final String? operand;
  final String? field;
  final bool matchCase;

  @override
  bool operator ==(Object other) =>
      other is SearchTerm &&
      other.word == word &&
      other.operand == operand &&
      other.field == field &&
      other.matchCase == matchCase;

  @override
  int get hashCode => Object.hash(word, operand, field, matchCase);

  @override
  String toString() =>
      'SearchTerm($word, operand: $operand, field: $field, case: $matchCase)';
}

/// A file that matched, with the fields it matched on and the text that did it.
@immutable
class SearchHit {
  const SearchHit({
    required this.id,
    required this.fileName,
    required this.fields,
    required this.texts,
  });

  final int id;
  final String fileName;
  final List<String> fields;
  final List<String> texts;

  /// The field the hit is grouped under in the result list.
  String get primaryField => fields.first;

  String get joinedFields => <String>{...fields}.join(', ');
}

/// Splits a query into terms. `license:mit AND .java` becomes two terms, the
/// second carrying operand `AND`.
List<SearchTerm> parseSearchText(String searchText) {
  // The original inserts a space after every colon so that `license:mit` splits
  // into the qualifier token `license:` and the word `mit`.
  final spaced = searchText.replaceAll(':', ': ');
  final words = spaced.trim().split(RegExp(r'[ \t]+'));
  final terms = <SearchTerm>[];

  var i = 0;
  while (i < words.length) {
    var word = words[i];
    String? operand;
    String? field;
    var matchCase = false;

    if (word == 'AND' || word == 'OR') {
      operand = word;
      i += 1;
      if (i >= words.length) break;
      word = words[i];
    }
    for (final candidate in kSearchFields) {
      if (word == '$candidate:') {
        field = candidate;
        i += 1;
        if (i >= words.length) {
          word = '';
          break;
        }
        word = words[i];
        break;
      }
    }
    if (word.contains('"')) {
      matchCase = true;
      final parts = word.split('"');
      word = parts.length > 1 ? parts[1] : '';
    }

    if (word.isNotEmpty) {
      terms.add(
        SearchTerm(
          word: word,
          operand: operand,
          field: field,
          matchCase: matchCase,
        ),
      );
    }
    i += 1;
  }

  return terms;
}

bool textMatch(String searchWord, String text, bool matchCase) {
  if (matchCase) return text.contains(searchWord);
  return text.toLowerCase().contains(searchWord.toLowerCase());
}

/// Runs [terms] against every file.
///
/// Terms are ORed together, except that a term carrying `AND` is a requirement
/// of the term before it: if it fails, the preceding results in that chain are
/// dropped and the rest of the chain is skipped. That is what the original's
/// `removeNotConditions` / `skipNotConditions` pair does.
List<SearchHit> runSearch(GraphData data, List<SearchTerm> terms) {
  if (terms.isEmpty) return const <SearchHit>[];

  final hits = <SearchHit>[];
  for (var row = 0; row < data.details.length; row++) {
    final detail = data.details[row];
    final node = data.nodes[row];
    final fileName = detail.fileName;
    final filePath = detail.directory;

    final foundFields = <String>[];
    final foundTexts = <String>[];

    var index = 0;
    while (index < terms.length) {
      final term = terms[index];
      final field = term.field;
      String? foundField;
      String? foundText;

      if ((field == null || field == 'tag') &&
          textMatch(term.word, node.tag, term.matchCase)) {
        foundField = 'tag';
        foundText = node.tag;
      } else if ((field == null || field == 'license') &&
          textMatch(term.word, detail.license, term.matchCase)) {
        foundField = 'license';
        // The original reports the copyright here, which is plainly a slip:
        // the licence is what matched.
        foundText = detail.license;
      } else if ((field == null || field == 'name') &&
          textMatch(term.word, fileName, term.matchCase)) {
        foundField = 'name';
        foundText = fileName;
      } else if ((field == null || field == 'copyright') &&
          textMatch(term.word, detail.copyright, term.matchCase)) {
        foundField = 'copyright';
        foundText = detail.copyright;
      } else if ((field == null || field == 'path') &&
          textMatch(term.word, filePath, term.matchCase)) {
        foundField = 'path';
        foundText = filePath;
      } else if ((field == null || field == 'sha1') &&
          textMatch(term.word, detail.sha1, term.matchCase)) {
        foundField = 'sha1';
        foundText = detail.sha1;
      }

      if (foundText != null && foundText.isNotEmpty) {
        foundFields.add(foundField!);
        foundTexts.add(foundText);
      } else {
        _dropAndedResults(index, terms, foundFields, foundTexts);
        index = _skipAndedTerms(index, terms);
      }
      index += 1;
    }

    if (foundTexts.isNotEmpty) {
      hits.add(
        SearchHit(
          id: detail.id,
          fileName: fileName,
          fields: foundFields,
          texts: foundTexts,
        ),
      );
    }
  }
  return hits;
}

/// A failed term invalidates whatever it was ANDed onto.
void _dropAndedResults(
  int index,
  List<SearchTerm> terms,
  List<String> foundFields,
  List<String> foundTexts,
) {
  var i = index;
  while (i >= 0 && i < terms.length && terms[i].operand == 'AND') {
    if (foundFields.isNotEmpty) foundFields.removeLast();
    if (foundTexts.isNotEmpty) foundTexts.removeLast();
    i -= 1;
  }
}

/// ...and the rest of the chain can no longer succeed either.
int _skipAndedTerms(int index, List<SearchTerm> terms) {
  var i = index;
  while (i < terms.length - 1 && terms[i + 1].operand == 'AND') {
    i += 1;
  }
  return i;
}

/// Files that carry any review verdict at all. Typing `review` in the find box
/// switches to this, as in the original.
List<SearchHit> findReviewedFiles(
  GraphData data,
  Set<String> reviewedFileNames,
) {
  return <SearchHit>[
    for (final detail in data.details)
      if (reviewedFileNames.contains(detail.path))
        SearchHit(
          id: detail.id,
          fileName: detail.fileName,
          fields: const <String>['tag'],
          texts: <String>[detail.path],
        ),
  ];
}

String formatBytes(int bytes, {int decimals = 2}) {
  if (bytes == 0) return '0 bytes';
  const units = <String>['bytes', 'Kb', 'Mb', 'Gb', 'Tb', 'Pb'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit += 1;
  }
  final text = value.toStringAsFixed(unit == 0 ? 0 : decimals);
  return '${text.contains('.') ? text.replaceFirst(RegExp(r'\.?0+$'), '') : text} ${units[unit]}';
}

/// Elides the middle of a long string, keeping its tail visible.
String shorten(String value, int maxLength, [int endChars = 5]) {
  final text = value.trim();
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - endChars - 3)}...'
      '${text.substring(text.length - endChars)}';
}
