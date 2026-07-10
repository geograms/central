import 'package:flutter/material.dart';

import '../data/models.dart';
import '../review/html_text.dart';
import '../review/review_store.dart';
import '../theme.dart';

/// The full-screen match report for one file: what it resembles, where, and
/// who signed off on it.
class ReviewFrame extends StatelessWidget {
  const ReviewFrame({
    super.key,
    required this.file,
    required this.coders,
    required this.store,
    required this.onClose,
  });

  final MatchFile file;
  final List<Coder> coders;
  final ReviewStore store;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Header(file: file),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: store,
                    builder: (context, _) => _Verdict(file: file, store: store),
                  ),
                  const SizedBox(height: 12),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: _Body(file: file)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 256,
                          child: _CoderProfile(coders: coders),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _Body(file: file),
                        const SizedBox(height: 12),
                        _CoderProfile(coders: coders),
                      ],
                    ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: onClose,
                iconSize: 24,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.file});

  final MatchFile file;

  @override
  Widget build(BuildContext context) {
    final clean = file.cleanName;
    final separator = clean.lastIndexOf(RegExp(r'[\\/]'));
    final path = separator == -1 ? '' : clean.substring(0, separator + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          color: GraphColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Text(
            'File: ${file.shortName}',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: GraphColors.accent, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
          child: SelectableText('Path: $path', style: kMonospace),
        ),
      ],
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.file, required this.store});

  final MatchFile file;
  final ReviewStore store;

  @override
  Widget build(BuildContext context) {
    final current = store.stateOrDefault(file.filename);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        const Text('Verdict:', style: kMonospace),
        for (final state in ReviewState.values)
          ChoiceChip(
            label: Text('${state.glyph}  ${state.label}'),
            selected: state == current,
            showCheckmark: false,
            selectedColor: state.color,
            backgroundColor: Colors.transparent,
            side: BorderSide(color: state.color),
            labelStyle: TextStyle(
              color: state == current ? Colors.black : state.color,
              fontSize: 12,
            ),
            shape: const StadiumBorder(),
            onSelected: (_) => store.setState(file.filename, state),
          ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.file});

  final MatchFile file;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (file.binaryMatches.isNotEmpty) _BinaryMatches(file: file),
        if (file.sourceMatches.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          for (final match in file.sourceMatches) _SourceMatchBox(match: match),
        ],
        if (file.binaryMatches.isEmpty && file.sourceMatches.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No matches recorded for this file', style: kMonospace),
          ),
      ],
    );
  }
}

class _BinaryMatches extends StatelessWidget {
  const _BinaryMatches({required this.file});

  final MatchFile file;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: GraphColors.accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(6),
            child: Text(
              'Matches Bin',
              textAlign: TextAlign.center,
              style: kMonospace,
            ),
          ),
          // The reference column is long, so it scrolls rather than wrapping
          // the whole page.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(GraphColors.accent),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: kMonospace,
              columnSpacing: 24,
              columns: const <DataColumn>[
                // The original's header row has these two the wrong way round.
                DataColumn(label: Text('Hash')),
                DataColumn(label: Text('Similarity')),
                DataColumn(label: Text('Reference')),
              ],
              rows: <DataRow>[
                for (final match in file.binaryMatches)
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text(match.hash)),
                      DataCell(Text('${match.similarity}%')),
                      DataCell(
                        SelectableText(stripHtml(match.reference)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceMatchBox extends StatelessWidget {
  const _SourceMatchBox({required this.match});

  final SourceMatch match;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: GraphColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              'Lines ${match.lines}',
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: GraphColors.panelBackground,
              border: Border.all(color: GraphColors.accent, width: 2),
            ),
            padding: const EdgeInsets.all(8),
            child: Scrollbar(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    unescapeHtml(match.code),
                    style: kMonospace.copyWith(height: 1.25),
                  ),
                ),
              ),
            ),
          ),
          for (final similarity in match.similarity)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 8),
              child: SelectableText(
                '${similarity.percent}%  Lines ${similarity.lines}\n'
                '${stripHtml(similarity.reference)}',
                style: kMonospace,
              ),
            ),
        ],
      ),
    );
  }
}

class _CoderProfile extends StatelessWidget {
  const _CoderProfile({required this.coders});

  final List<Coder> coders;

  @override
  Widget build(BuildContext context) {
    if (coders.isEmpty) return const SizedBox.shrink();
    final coder = coders.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          color: GraphColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Text(
            coder.displayName,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: GraphColors.panelBackground,
            border: Border.all(color: GraphColors.accent, width: 2),
          ),
          padding: const EdgeInsets.all(16),
          // The original loads an avatar from disk; the dataset ships none.
          child: const Icon(
            Icons.person_outline,
            size: 96,
            color: GraphColors.accent,
          ),
        ),
      ],
    );
  }
}
