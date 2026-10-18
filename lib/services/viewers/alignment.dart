import 'dart:isolate';
import 'dart:typed_data';

import 'package:segui/src/rust/api/alignment_view.dart';

/// Chunk sizes, in sites, offered in the alignment viewer.
const List<int> alignmentChunkSizes = [250, 500, 1000, 2000];
const int defaultAlignmentChunkSize = 1000;

const int _gap = 0x2D; // -
const int _missing = 0x3F; // ?
const int _dnaUnknown = 0x4E; // N
const int _aaUnknown = 0x58; // X

/// How residue cells are colored.
enum AlignmentColorMode {
  base('Base'),
  mono('Mono'),
  reference('Diff to first');

  const AlignmentColorMode(this.label);

  final String label;
}

Future<AlignmentViewData> loadAlignmentView(String path) {
  return AlignmentViewServices(inputPath: path).load();
}

/// Whether [code] is a gap or missing data.
bool isGapResidue(int code) => code == _gap || code == _missing;

/// First and last (exclusive) visible index of equally sized items.
class VisibleRange {
  const VisibleRange(this.first, this.last);

  /// Items in a viewport of [extent] scrolled to [offset].
  factory VisibleRange.of({
    required double offset,
    required double extent,
    required double itemSize,
    required int count,
  }) {
    if (count <= 0 || itemSize <= 0 || extent <= 0) {
      return const VisibleRange(0, 0);
    }
    final int first = (offset / itemSize).floor().clamp(0, count);
    final int last = ((offset + extent) / itemSize).ceil().clamp(first, count);
    return VisibleRange(first, last);
  }

  final int first;
  final int last;

  int get length => last - first;

  @override
  bool operator ==(Object other) =>
      other is VisibleRange && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);
}

/// Splits an alignment of [length] sites into chunks of [size] sites.
class AlignmentChunks {
  const AlignmentChunks({required this.length, required this.size});

  final int length;
  final int size;

  int get count => length <= 0 ? 0 : (length + size - 1) ~/ size;

  /// Chunk that holds [site], a zero-based column.
  int chunkOf(int site) => length <= 0 ? 0 : site.clamp(0, length - 1) ~/ size;

  int startOf(int chunk) => (chunk * size).clamp(0, length);

  int endOf(int chunk) => ((chunk + 1) * size).clamp(0, length);

  /// Keeps [chunk] inside the alignment.
  int clamp(int chunk) => count == 0 ? 0 : chunk.clamp(0, count - 1);
}

/// Gap and variable-site share of one chunk.
class ChunkStat {
  const ChunkStat({
    required this.start,
    required this.end,
    required this.gapFraction,
    required this.variableFraction,
  });

  /// Zero-based first site and exclusive last site.
  final int start;
  final int end;

  /// Share of cells that are gaps, missing data, or past a sequence's end.
  final double gapFraction;

  /// Share of sites with more than one residue, ignoring gaps and unknowns.
  final double variableFraction;
}

/// Computes [ChunkStat]s for every chunk off the UI isolate.
Future<List<ChunkStat>> computeChunkStats(
  AlignmentViewData data,
  int chunkSize,
) {
  final List<Uint8List> rows = data.sequences;
  final int length = data.length;
  final bool isDna = data.isDna;
  return Isolate.run(() => chunkStats(rows, length, chunkSize, isDna: isDna));
}

List<ChunkStat> chunkStats(
  List<Uint8List> rows,
  int length,
  int chunkSize, {
  required bool isDna,
}) {
  final AlignmentChunks chunks =
      AlignmentChunks(length: length, size: chunkSize);
  final int unknown = isDna ? _dnaUnknown : _aaUnknown;
  final List<ChunkStat> stats = [];
  for (int chunk = 0; chunk < chunks.count; chunk++) {
    final int start = chunks.startOf(chunk);
    final int end = chunks.endOf(chunk);
    int gaps = 0;
    int variable = 0;
    for (int site = start; site < end; site++) {
      int first = -1;
      bool isVariable = false;
      for (final Uint8List row in rows) {
        if (site >= row.length) {
          gaps++;
          continue;
        }
        final int code = row[site];
        if (isGapResidue(code)) {
          gaps++;
        } else if (code != unknown) {
          if (first < 0) {
            first = code;
          } else if (code != first) {
            isVariable = true;
          }
        }
      }
      if (isVariable) variable++;
    }
    final int sites = end - start;
    final int cells = sites * rows.length;
    stats.add(ChunkStat(
      start: start,
      end: end,
      gapFraction: cells == 0 ? 0 : gaps / cells,
      variableFraction: sites == 0 ? 0 : variable / sites,
    ));
  }
  return stats;
}

/// Maps alignment columns to ungapped positions, one row at a time.
class UngappedIndex {
  UngappedIndex(this.rows);

  final List<Uint8List> rows;
  final Map<int, Uint32List> _counts = {};

  /// One-based position of [site] in [row] without gaps, or null on a gap.
  int? positionOf(int row, int site) {
    final Uint8List seq = rows[row];
    if (site < 0 || site >= seq.length || isGapResidue(seq[site])) {
      return null;
    }
    return _countsOf(row)[site];
  }

  // Running residue count through each site.
  Uint32List _countsOf(int row) {
    return _counts.putIfAbsent(row, () {
      final Uint8List seq = rows[row];
      final Uint32List counts = Uint32List(seq.length);
      int count = 0;
      for (int i = 0; i < seq.length; i++) {
        if (!isGapResidue(seq[i])) count++;
        counts[i] = count;
      }
      return counts;
    });
  }
}

/// Sequences picked in the name panel, and how the grid shows them.
class RowSelection {
  const RowSelection({
    this.rows = const {},
    this.anchor,
    this.showOnlySelected = false,
    this.pinSelected = false,
  });

  /// Selected rows, as indexes into the loaded sequences.
  final Set<int> rows;

  /// Row a Shift selection extends from.
  final int? anchor;

  /// Hides unselected sequences.
  final bool showOnlySelected;

  /// Moves selected sequences to the top.
  final bool pinSelected;

  bool get isEmpty => rows.isEmpty;

  /// Selection after tapping [row]. Shift extends from the anchor over the
  /// rows in display [order]; [toggle] (Ctrl or Cmd) adds or removes [row];
  /// a plain tap selects [row] alone, or clears it when it is the only one.
  RowSelection tap(
    int row,
    List<int> order, {
    bool extend = false,
    bool toggle = false,
  }) {
    final int? anchor = this.anchor;
    if (extend && anchor != null) {
      final int from = order.indexOf(anchor);
      final int to = order.indexOf(row);
      if (from >= 0 && to >= 0) {
        final int start = from < to ? from : to;
        final int end = from < to ? to : from;
        return _withRows(
          {...rows, ...order.sublist(start, end + 1)},
          anchor,
        );
      }
    }
    if (toggle) {
      final Set<int> next = {...rows};
      if (!next.remove(row)) next.add(row);
      return _withRows(next, row);
    }
    if (rows.length == 1 && rows.contains(row)) return _withRows({}, null);
    return _withRows({row}, row);
  }

  RowSelection copyWith({bool? showOnlySelected, bool? pinSelected}) {
    return RowSelection(
      rows: rows,
      anchor: anchor,
      showOnlySelected: showOnlySelected ?? this.showOnlySelected,
      pinSelected: pinSelected ?? this.pinSelected,
    );
  }

  /// Display order of [count] sequences: indexes into the loaded sequences.
  List<int> orderOf(int count) {
    final List<int> all = List<int>.generate(count, (i) => i);
    if (rows.isEmpty) return all;
    final List<int> selected = all.where(rows.contains).toList();
    if (showOnlySelected) return selected;
    if (!pinSelected) return all;
    return [...selected, ...all.where((i) => !rows.contains(i))];
  }

  // Clearing the selection also turns off the views that depend on it.
  RowSelection _withRows(Set<int> next, int? anchor) {
    return RowSelection(
      rows: next,
      anchor: anchor,
      showOnlySelected: next.isEmpty ? false : showOnlySelected,
      pinSelected: next.isEmpty ? false : pinSelected,
    );
  }
}

/// Selected sequences in FASTA format, in alignment order.
String fastaOf(List<String> names, List<Uint8List> sequences, Set<int> rows) {
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < names.length; i++) {
    if (!rows.contains(i)) continue;
    buffer
      ..write('>')
      ..writeln(names[i])
      ..writeln(String.fromCharCodes(sequences[i]));
  }
  return buffer.toString();
}
