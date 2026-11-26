import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:segui/src/rust/api/alignment_view.dart';

/// Window sizes, in sites, offered in the alignment viewer.
const List<int> alignmentWindowSizes = [250, 500, 1000, 2000];
const int defaultAlignmentWindowSize = 1000;

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
  final AlignmentPartitions? partitions = handle.partitions();
  return AlignmentViewData(
    names: summary.names,
    lengths: summary.lengths,
    length: summary.length,
    isAligned: summary.isAligned,
    isDna: summary.isDna,
    residues: RustResidues(handle, rows: summary.names.length),
    partitions: partitions?.partitions ?? const [],
    partitionSource: partitions?.source,
    partitionError: handle.partitionError(),
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
    this.partitions = const [],
    this.partitionSource,
    this.partitionError,
  });

  /// Alignment held in Dart, such as in tests.
  factory AlignmentViewData.fromSequences(
    List<String> names,
    List<Uint8List> sequences, {
    bool isDna = true,
    List<AlignmentPartition> partitions = const [],
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
      partitions: partitions,
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

  /// Partitions of a concatenated alignment, in site order, or empty.
  final List<AlignmentPartition> partitions;

  /// File the partitions were read from.
  final String? partitionSource;

  /// Why a partition file next to the alignment could not be read.
  final String? partitionError;

  late final AlignmentPartitionIndex partitionIndex =
      AlignmentPartitionIndex(partitions);

  bool get hasPartitions => partitions.isNotEmpty;

  int get rowCount => names.length;

  /// Name of the partition at [site], naming the codon subset when several
  /// share a band.
  String? partitionNameAt(int site) {
    final int? index = partitionIndex.indexAt(site);
    if (index == null) return null;
    if (partitions[index].subsets.isEmpty) return partitions[index].name;
    return residues.partitionAt(site) ?? partitions[index].name;
  }

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

  /// Gap and variable-site shares of up to [count] windows of [windowSize]
  /// sites from window [first], computed in Rust.
  Future<List<AlignmentWindowStat>> windowStats(
    int windowSize,
    int first,
    int count,
  );

  /// Gap and variable-site shares of sites [start] to [end] (exclusive),
  /// such as one partition, or null when not computed.
  Future<AlignmentWindowStat?> rangeStats(int start, int end);

  /// Name of the partition subset holding [site], when known.
  String? partitionAt(int site);

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

  // Window statistics are computed only in Rust; rows held in Dart have none.
  @override
  Future<List<AlignmentWindowStat>> windowStats(
    int windowSize,
    int first,
    int count,
  ) async =>
      const [];

  @override
  Future<AlignmentWindowStat?> rangeStats(int start, int end) async => null;

  @override
  String? partitionAt(int site) => null;

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
  Future<List<AlignmentWindowStat>> windowStats(
    int windowSize,
    int first,
    int count,
  ) {
    return _handle.windowStats(
      windowSize: windowSize,
      first: first,
      count: count,
    );
  }

  @override
  Future<AlignmentWindowStat?> rangeStats(int start, int end) {
    return _handle.rangeStats(start: start, end: end);
  }

  @override
  String? partitionAt(int site) {
    if (_isDisposed) return null;
    return _handle.partitionAt(site: site);
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

/// Splits an alignment of [length] sites into windows of [size] sites.
class AlignmentWindows {
  const AlignmentWindows({required this.length, required this.size});

  final int length;
  final int size;

  int get count => length <= 0 ? 0 : (length + size - 1) ~/ size;

  /// Window that holds [site], a zero-based column.
  int windowOf(int site) => length <= 0 ? 0 : site.clamp(0, length - 1) ~/ size;

  int startOf(int window) => (window * size).clamp(0, length);

  int endOf(int window) => ((window + 1) * size).clamp(0, length);

  /// Keeps [window] inside the alignment.
  int clamp(int window) => count == 0 ? 0 : window.clamp(0, count - 1);
}

/// Index of the first item of [sorted] that is at least [value].
int lowerBoundOf(List<int> sorted, int value) {
  int low = 0;
  int high = sorted.length;
  while (low < high) {
    final int mid = (low + high) >> 1;
    if (sorted[mid] < value) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  return low;
}

/// Finds partitions by site. [partitions] are in site order without overlaps.
class AlignmentPartitionIndex {
  AlignmentPartitionIndex(this.partitions)
      : starts = [for (final AlignmentPartition p in partitions) p.start];

  final List<AlignmentPartition> partitions;

  /// First site of each partition.
  final List<int> starts;

  int get length => partitions.length;

  /// Partition holding [site], or null between partitions.
  int? indexAt(int site) {
    final int index = lowerBoundOf(starts, site + 1) - 1;
    if (index < 0 || site >= partitions[index].end) return null;
    return index;
  }

  /// First partition starting after [site].
  int? nextAfter(int site) {
    final int index = lowerBoundOf(starts, site + 1);
    return index < length ? index : null;
  }

  /// Last partition starting before [site].
  int? previousBefore(int site) {
    final int index = lowerBoundOf(starts, site) - 1;
    return index >= 0 ? index : null;
  }

  /// Partition at [site], or the last one before it.
  int? nearest(int site) => indexAt(site) ?? previousBefore(site);
}

/// Where go-to text points: a site, a taxon row, or a partition, or why
/// it points nowhere.
class GoToTarget {
  const GoToTarget({this.site, this.row, this.partition, this.error});

  /// Zero-based site.
  final int? site;

  /// Loaded sequence index.
  final int? row;

  /// Partition to show from its first site.
  final int? partition;
  final String? error;
}

/// Partitions suggested for go-to [text]: those whose name holds the text
/// before any `:`, exact and prefix matches first.
List<int> goToMatches(AlignmentViewData data, String text) {
  final String name = text.split(':').first.trim().toLowerCase();
  if (name.isEmpty || int.tryParse(name.replaceAll(',', '')) != null) {
    return const [];
  }
  final List<(int, int)> ranked = [];
  for (int i = 0; i < data.partitions.length; i++) {
    final String partition = data.partitions[i].name.toLowerCase();
    if (partition == name) {
      ranked.add((0, i));
    } else if (partition.startsWith(name)) {
      ranked.add((1, i));
    } else if (partition.contains(name)) {
      ranked.add((2, i));
    }
  }
  ranked.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  return [for (final (int, int) r in ranked) r.$2];
}

/// Reads go-to [text]: `123` (a site), a partition, `partition:12` (a site
/// within it), a taxon, or `taxon:123`. Partitions win over taxa of the same
/// name; part of a partition name goes to the first match when no taxon
/// matches.
GoToTarget parseGoTo(AlignmentViewData data, String text) {
  final NumberFormat format = NumberFormat('#,###');
  final String input = text.trim();
  if (input.isEmpty) {
    return const GoToTarget(error: 'Enter a site, partition, or taxon.');
  }
  final int colon = input.lastIndexOf(':');
  final String name = (colon < 0 ? input : input.substring(0, colon)).trim();
  final String? siteText =
      colon < 0 ? null : input.substring(colon + 1).replaceAll(',', '').trim();
  final int? partition = _partitionNamed(data, name);
  if (partition != null) {
    if (siteText == null) return GoToTarget(partition: partition);
    final AlignmentPartition p = data.partitions[partition];
    final int sites = p.end - p.start;
    final int? site = int.tryParse(siteText);
    if (site == null || site < 1 || site > sites) {
      return GoToTarget(
        error: 'Enter a site from 1 to ${format.format(sites)} in ${p.name}.',
      );
    }
    return GoToTarget(site: p.start + site - 1);
  }
  final String siteError =
      'Enter a site from 1 to ${format.format(data.length)}.';
  final int? number = int.tryParse(input.replaceAll(',', ''));
  if (colon < 0 && number != null) {
    if (number < 1 || number > data.length) {
      return GoToTarget(error: siteError);
    }
    return GoToTarget(site: number - 1);
  }
  int? row;
  if (name.isNotEmpty) {
    final String lower = name.toLowerCase();
    final int index =
        data.names.indexWhere((n) => n.toLowerCase().contains(lower));
    if (index < 0) {
      final List<int> matches = goToMatches(data, name);
      if (siteText == null && matches.isNotEmpty) {
        return GoToTarget(partition: matches.first);
      }
      return GoToTarget(error: 'No taxon or partition matches "$name".');
    }
    row = index;
  }
  if (siteText == null) return GoToTarget(row: row);
  final int? site = int.tryParse(siteText);
  if (site == null || site < 1 || site > data.length) {
    return GoToTarget(error: siteError);
  }
  return GoToTarget(site: site - 1, row: row);
}

int? _partitionNamed(AlignmentViewData data, String name) {
  final String lower = name.toLowerCase();
  final int index =
      data.partitions.indexWhere((p) => p.name.toLowerCase() == lower);
  return index < 0 ? null : index;
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
