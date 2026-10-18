import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:segui/src/rust/api/alignment_view.dart';

/// Chunk sizes, in sites, offered in the alignment viewer.
const List<int> alignmentChunkSizes = [250, 500, 1000, 2000];
const int defaultAlignmentChunkSize = 1000;

const int _gap = 0x2D; // -
const int _missing = 0x3F; // ?

/// How residue cells are colored.
enum AlignmentColorMode {
  base('Base'),
  mono('Mono'),
  reference('Diff to first');

  const AlignmentColorMode(this.label);

  final String label;
}

/// Opens the alignment at [path]. Residues stay in Rust and load as the
/// viewer needs them. Call [AlignmentViewData.dispose] when done.
Future<AlignmentViewData> loadAlignmentView(String path) async {
  final AlignmentHandle handle = await AlignmentHandle.open(path: path);
  final AlignmentSummary summary = handle.summary();
  return AlignmentViewData(
    names: summary.names,
    lengths: summary.lengths,
    length: summary.length,
    isAligned: summary.isAligned,
    isDna: summary.isDna,
    residues: RustResidues(handle, rows: summary.names.length),
  );
}

/// Names and shape of an open alignment, and its residues.
class AlignmentViewData {
  AlignmentViewData({
    required this.names,
    required this.lengths,
    required this.length,
    required this.isAligned,
    required this.isDna,
    required this.residues,
  });

  /// Alignment held in Dart, such as in tests.
  factory AlignmentViewData.fromSequences(
    List<String> names,
    List<Uint8List> sequences, {
    bool isDna = true,
  }) {
    final Uint32List lengths =
        Uint32List.fromList([for (final Uint8List s in sequences) s.length]);
    final int length = lengths.fold(0, (a, b) => a > b ? a : b);
    return AlignmentViewData(
      names: names,
      lengths: lengths,
      length: length,
      isAligned: lengths.every((l) => l == length),
      isDna: isDna,
      residues: MemoryResidues(names, sequences, isDna: isDna),
    );
  }

  final List<String> names;

  /// Residues in each row.
  final Uint32List lengths;

  /// Longest sequence length.
  final int length;

  /// Whether every sequence has the same length.
  final bool isAligned;

  /// Whether the sequences are DNA rather than amino acids.
  final bool isDna;
  final AlignmentResidues residues;

  int get rowCount => names.length;

  /// Residue at [site] of [row], or null past its end or while it loads.
  int? residueAt(int row, int site) {
    if (row < 0 || row >= rowCount || site < 0 || site >= lengths[row]) {
      return null;
    }
    final ResidueBlock? block = residues.blockAt(row, site);
    return block?[site];
  }

  void dispose() => residues.dispose();
}

/// Residues of one row from [start], as stored by [AlignmentResidues].
class ResidueBlock {
  const ResidueBlock(this.residues, this.start);

  final Uint8List residues;
  final int start;

  /// Exclusive last site.
  int get end => start + residues.length;

  int operator [](int site) => residues[site - start];
}

/// Residues of an alignment, read in blocks as the viewer needs them.
/// Notifies listeners when a block that was missing arrives.
abstract class AlignmentResidues extends ChangeNotifier {
  /// Sites per block. Blocks start at multiples of it.
  int get blockSites;

  /// Block of [row] that holds [site], or null while it loads.
  ResidueBlock? blockAt(int row, int site);

  /// One-based position of [site] in [row] without gaps, or null on a gap.
  int? ungappedPosition(int row, int site);

  /// Gap and variable-site shares of up to [count] chunks of [chunkSize]
  /// sites from chunk [first], computed in Rust.
  Future<List<AlignmentChunkStat>> chunkStats(
    int chunkSize,
    int first,
    int count,
  );

  /// Residues of [rows] at [width] evenly spaced sites, row after row.
  /// Cells past a row's end are zero.
  Future<Uint8List> sample(List<int> rows, int width);

  /// Selected sequences in FASTA format, in alignment order.
  Future<String> fasta(Set<int> rows);
}

/// Residues held in Dart.
class MemoryResidues extends AlignmentResidues {
  MemoryResidues(this.names, this.rows, {required this.isDna})
      : _blocks = [for (final Uint8List row in rows) ResidueBlock(row, 0)],
        _ungapped = UngappedIndex(rows);

  final List<String> names;
  final List<Uint8List> rows;
  final bool isDna;
  final List<ResidueBlock> _blocks;
  final UngappedIndex _ungapped;

  // A whole row is one block.
  @override
  int get blockSites => 1 << 30;

  @override
  ResidueBlock? blockAt(int row, int site) => _blocks[row];

  @override
  int? ungappedPosition(int row, int site) => _ungapped.positionOf(row, site);

  // Chunk statistics are computed only in Rust; rows held in Dart have none.
  @override
  Future<List<AlignmentChunkStat>> chunkStats(
    int chunkSize,
    int first,
    int count,
  ) async =>
      const [];

  @override
  Future<Uint8List> sample(List<int> rows, int width) async {
    final int length = this.rows.fold(0, (a, r) => r.length > a ? r.length : a);
    final Uint8List out = Uint8List(rows.length * width);
    for (int y = 0; y < rows.length; y++) {
      final Uint8List seq = this.rows[rows[y]];
      for (int x = 0; x < width; x++) {
        final int site = x * length ~/ width;
        if (site < seq.length) out[y * width + x] = seq[site];
      }
    }
    return out;
  }

  @override
  Future<String> fasta(Set<int> rows) async => fastaOf(names, this.rows, rows);
}

/// Residues read from Rust in tiles of [tileRows] rows by [tileSites]
/// sites, keeping the most recently used tiles.
class RustResidues extends AlignmentResidues {
  RustResidues(this._handle, {required this.rows});

  static const int tileRows = 32;
  static const int tileSites = 4096;

  /// Tiles kept, about 32 MiB at most.
  static const int maxTiles = 256;

  final AlignmentHandle _handle;
  final int rows;

  // Each tile split into one block per row, most recently used last.
  final LinkedHashMap<int, List<ResidueBlock>> _tiles = LinkedHashMap();
  final Set<int> _loading = {};
  final Set<int> _failed = {};
  bool _isDisposed = false;

  @override
  int get blockSites => tileSites;

  @override
  ResidueBlock? blockAt(int row, int site) {
    final int tileRow = row ~/ tileRows;
    final int tileSite = site ~/ tileSites;
    // Lengths fit in 32 bits, so tile columns fit in the low 20.
    final int key = (tileRow << 20) | tileSite;
    final List<ResidueBlock>? tile = _tiles.remove(key);
    if (tile != null) {
      _tiles[key] = tile;
      return tile[row - tileRow * tileRows];
    }
    _load(key, tileRow, tileSite);
    return null;
  }

  @override
  int? ungappedPosition(int row, int site) {
    if (_isDisposed) return null;
    return _handle.ungappedPosition(row: row, site: site);
  }

  @override
  Future<List<AlignmentChunkStat>> chunkStats(
    int chunkSize,
    int first,
    int count,
  ) {
    return _handle.chunkStats(
      chunkSize: chunkSize,
      first: first,
      count: count,
    );
  }

  @override
  Future<Uint8List> sample(List<int> rows, int width) {
    return _handle.sample(rows: rows, width: width);
  }

  @override
  Future<String> fasta(Set<int> rows) => _handle.fasta(rows: rows.toList());

  @override
  void dispose() {
    _isDisposed = true;
    _tiles.clear();
    _handle.dispose();
    super.dispose();
  }

  Future<void> _load(int key, int tileRow, int tileSite) async {
    if (_isDisposed || _loading.contains(key) || _failed.contains(key)) return;
    _loading.add(key);
    final int rowStart = tileRow * tileRows;
    final int rowCount = (rows - rowStart).clamp(0, tileRows);
    final int siteStart = tileSite * tileSites;
    try {
      final Uint8List cells = await _handle.tile(
        rowStart: rowStart,
        rowCount: rowCount,
        siteStart: siteStart,
        siteCount: tileSites,
      );
      if (_isDisposed) return;
      _tiles[key] = [
        for (int r = 0; r < rowCount; r++)
          ResidueBlock(
            Uint8List.sublistView(cells, r * tileSites, (r + 1) * tileSites),
            siteStart,
          ),
      ];
      while (_tiles.length > maxTiles) {
        _tiles.remove(_tiles.keys.first);
      }
      notifyListeners();
    } catch (_) {
      // Keep painting the rest; a tile that cannot be read stays blank.
      _failed.add(key);
    } finally {
      _loading.remove(key);
    }
  }
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
  /// rows in display [order]; [toggle] (Ctrl, or Cmd on Apple platforms)
  /// adds or removes [row];
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
