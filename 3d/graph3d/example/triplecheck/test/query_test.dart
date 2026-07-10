import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triplecheck3d/data/models.dart';
import 'package:triplecheck3d/review/html_text.dart';
import 'package:triplecheck3d/review/review_store.dart';
import 'package:triplecheck3d/search/query.dart';
import 'package:triplecheck3d/theme.dart';

GraphNode _node(int id, String tag) => GraphNode(
  id: id,
  sourceId: id,
  symbol: 'n$id',
  name: 'f$id',
  license: '',
  column: id,
  row: 1,
  tag: tag,
  riskyLicense: false,
  hasCopyright: false,
);

FileDetail _detail(
  int id, {
  String license = '',
  String copyright = '',
  String path = './src/Main.java',
  String sha1 = 'abc123',
  int size = 100,
  int loc = 10,
}) => FileDetail(
  id: id,
  sourceId: id,
  sha1: sha1,
  size: size,
  linesOfCode: loc,
  license: license,
  copyright: copyright,
  path: path,
);

GraphData _data(List<GraphNode> nodes, List<FileDetail> details) => GraphData(
  project: const ProjectInfo(
    name: 'T',
    licence: '',
    conflicts: '',
    licences: <String>[],
    complete: '',
    files: 0,
    linesOfCode: 0,
    summary: '',
  ),
  nodes: nodes,
  links: const <GraphLink>[],
  details: details,
  coders: const <Coder>[],
  matches: const <MatchGroup>[],
  defaultReviews: const <String, String>{},
);

void main() {
  group('parseSearchText', () {
    test('splits a bare word', () {
      expect(parseSearchText('mit'), <SearchTerm>[
        const SearchTerm(word: 'mit'),
      ]);
    });

    test('reads a field qualifier written without a space', () {
      expect(parseSearchText('license:mit'), <SearchTerm>[
        const SearchTerm(word: 'mit', field: 'license'),
      ]);
    });

    test('carries the operand onto the term it precedes', () {
      expect(parseSearchText('license:mit AND .java'), <SearchTerm>[
        const SearchTerm(word: 'mit', field: 'license'),
        const SearchTerm(word: '.java', operand: 'AND'),
      ]);
    });

    test('quotes force a case-sensitive match', () {
      expect(parseSearchText('license:"MIT"'), <SearchTerm>[
        const SearchTerm(word: 'MIT', field: 'license', matchCase: true),
      ]);
    });

    test('a trailing qualifier with nothing after it is dropped', () {
      expect(parseSearchText('license:'), isEmpty);
    });

    test('an unknown qualifier is searched for literally', () {
      // `author:` is not a field, so the colon-split leaves two bare words.
      expect(parseSearchText('author:ann').map((t) => t.word), <String>[
        'author:',
        'ann',
      ]);
    });
  });

  group('runSearch', () {
    final data = _data(
      <GraphNode>[_node(1, 'source'), _node(2, 'config'), _node(3, 'source')],
      <FileDetail>[
        _detail(1, license: 'MIT', path: './src/Main.java'),
        _detail(2, license: 'GPL-3.0', path: './etc/build.xml'),
        _detail(3, license: 'MIT', copyright: 'Ann', path: './src/Util.kt'),
      ],
    );

    List<int> idsFor(String query) =>
        runSearch(data, parseSearchText(query)).map((hit) => hit.id).toList();

    test('matches a field, case-insensitively by default', () {
      expect(idsFor('license:mit'), <int>[1, 3]);
    });

    test('quoted terms respect case', () {
      expect(idsFor('license:"mit"'), isEmpty);
      expect(idsFor('license:"MIT"'), <int>[1, 3]);
    });

    test('AND narrows, OR widens', () {
      expect(idsFor('license:mit AND .kt'), <int>[3]);
      expect(idsFor('license:gpl OR license:mit'), <int>[1, 2, 3]);
    });

    test('a bare word is tried against every field in priority order', () {
      final hit = runSearch(data, parseSearchText('source')).first;
      expect(hit.primaryField, 'tag');
    });

    test('a licence hit reports the licence, not the copyright', () {
      // The original prints `details[row][5]` — the copyright — here.
      final hit = runSearch(data, parseSearchText('license:mit')).last;
      expect(hit.primaryField, 'license');
      expect(hit.texts.single, 'MIT');
    });

    test('an empty field never counts as a match', () {
      // Files 1 and 2 have no copyright, so an empty needle must not find them.
      expect(idsFor('copyright:Ann'), <int>[3]);
    });
  });

  group('formatting', () {
    test('formatBytes scales by a thousand', () {
      expect(formatBytes(0), '0 bytes');
      expect(formatBytes(512), '512 bytes');
      expect(formatBytes(3840), '3.84 Kb');
      expect(formatBytes(2500000), '2.5 Mb');
    });

    test('shorten elides the middle and keeps the tail', () {
      expect(shorten('short.java', 30), 'short.java');
      final long = shorten('a-very-long-file-name-indeed.java', 20, 8);
      expect(long.length, 20);
      expect(long, endsWith('eed.java'));
      expect(long, contains('...'));
    });
  });

  group('html_text', () {
    test('resolves named and numeric entities', () {
      expect(unescapeHtml('LinkedHashMap&#60;String&#62;'),
          'LinkedHashMap<String>');
      expect(unescapeHtml('a &amp; b'), 'a & b');
    });

    test('strips tags but keeps the anchor text', () {
      const html = '<a href="https://example.com/x" target="_blank">label</a>';
      expect(stripHtml(html), 'label');
      expect(hrefOf(html), 'https://example.com/x');
    });

    test('leaves an unrecognised entity alone rather than eating it', () {
      expect(unescapeHtml('100&pct;'), '100&pct;');
    });
  });

  group('ReviewStore', () {
    test('layers user verdicts over the dataset defaults', () async {
      final store = ReviewStore.inMemory(<String, String>{
        './a.java (MIT)': 'Unknown',
      });
      expect(store.stateFor('./a.java (MIT)'), ReviewState.unknown);
      expect(store.stateFor('./b.java'), isNull);
      expect(store.stateOrDefault('./b.java'), ReviewState.unknown);

      await store.setState('./b.java', ReviewState.accepted);
      expect(store.stateFor('./b.java'), ReviewState.accepted);
    });

    test('reviewed paths drop the licence annotation', () {
      final store = ReviewStore.inMemory(<String, String>{
        './a.java (MIT)[10..20]': 'Failed',
      });
      expect(store.reviewedPaths, <String>{'./a.java'});
    });
  });

  group('the converted dataset', () {
    test('loads, and its nodes and details line up', () {
      final file = File('assets/data/triplecheck.json');
      expect(file.existsSync(), isTrue, reason: 'run tool/convert_data.js');

      final data = GraphData.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );

      expect(data.nodeCount, 426);
      expect(data.links, hasLength(315));
      expect(data.matches, hasLength(7));
      expect(data.storageKey, 'Big-426');

      // Identity is the array position. The dataset's own `id` column is not
      // usable as one: 19 files share an id with another.
      expect(
        data.nodes.map((n) => n.id),
        List<int>.generate(data.nodeCount, (i) => i + 1),
      );
      final sourceIds = data.nodes.map((n) => n.sourceId).toSet();
      expect(sourceIds.length, lessThan(data.nodeCount));

      // A link endpoint names the node and the detail at the same position.
      final link = data.links.first;
      expect(
        data.detailById(link.from).path,
        endsWith('ProxyService.java'),
      );
      expect(data.detailById(link.to).path, endsWith('RootTools-1.7.jar'));
    });

    test('rejects a bundle whose details do not match its nodes', () {
      expect(
        () => GraphData.fromJson(<String, dynamic>{
          'project': <String, dynamic>{},
          'nodes': <dynamic>[
            <String, dynamic>{
              'id': 1,
              'symbol': 'a',
              'name': 'a',
              'license': '',
              'column': 1,
              'row': 1,
              'tag': 't',
              'riskyLicense': false,
              'hasCopyright': false,
            },
          ],
          'details': <dynamic>[],
          'links': <dynamic>[],
        }),
        throwsStateError,
      );
    });
  });
}
