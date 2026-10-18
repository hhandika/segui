import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/src/rust/api/alignment_view.dart';

/// Serves tiles of rows of one repeated residue per row, and records the
/// tiles asked for.
class _FakeHandle implements AlignmentHandle {
  _FakeHandle(this.lengths);

  final List<int> lengths;
  final List<(int, int)> requests = [];
  bool _isDisposed = false;

  @override
  Future<Uint8List> tile({
    required int rowStart,
    required int rowCount,
    required int siteStart,
    required int siteCount,
  }) async {
    requests.add((rowStart, siteStart));
    final Uint8List out = Uint8List(rowCount * siteCount);
    for (int r = 0; r < rowCount; r++) {
      final int row = rowStart + r;
      for (int s = 0; s < siteCount && siteStart + s < lengths[row]; s++) {
        out[r * siteCount + s] = 0x41 + row % 26;
      }
    }
    return out;
  }

  @override
  void dispose() => _isDisposed = true;

  @override
  bool get isDisposed => _isDisposed;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('RustResidues', () {
    test('Loads a tile on first use and notifies listeners', () async {
      final _FakeHandle handle = _FakeHandle(List.filled(40, 10000));
      final RustResidues residues = RustResidues(handle, rows: 40);
      int notified = 0;
      residues.addListener(() => notified++);

      expect(residues.blockAt(33, 5000), isNull);
      // A second miss before the tile arrives does not ask again.
      expect(residues.blockAt(34, 5001), isNull);
      await pumpEventQueue();

      expect(notified, 1);
      expect(handle.requests, [(32, RustResidues.tileSites)]);
      final ResidueBlock block = residues.blockAt(33, 5000)!;
      expect(block.start, RustResidues.tileSites);
      expect(block[5000], 0x41 + 33 % 26);
      residues.dispose();
    });

    test('Keeps only the most recently used tiles', () async {
      final _FakeHandle handle =
          _FakeHandle([RustResidues.tileSites * (RustResidues.maxTiles + 2)]);
      final RustResidues residues = RustResidues(handle, rows: 1);
      for (int t = 0; t <= RustResidues.maxTiles; t++) {
        residues.blockAt(0, t * RustResidues.tileSites);
      }
      await pumpEventQueue();
      handle.requests.clear();

      // The first tile was evicted; the last is still held.
      expect(residues.blockAt(0, 0), isNull);
      expect(
        residues.blockAt(0, RustResidues.maxTiles * RustResidues.tileSites),
        isNotNull,
      );
      await pumpEventQueue();
      expect(handle.requests, [(0, 0)]);
      residues.dispose();
    });

    test('Dispose releases the handle and drops late tiles', () async {
      final _FakeHandle handle = _FakeHandle([100]);
      final RustResidues residues = RustResidues(handle, rows: 1);
      residues.blockAt(0, 0);
      residues.dispose();
      await pumpEventQueue();
      expect(handle.isDisposed, isTrue);
    });
  });

  test('AlignmentViewData reads residues within row lengths', () {
    final AlignmentViewData data = AlignmentViewData.fromSequences(
      ['a', 'b'],
      [
        Uint8List.fromList('ACGT'.codeUnits),
        Uint8List.fromList('AC'.codeUnits)
      ],
    );
    expect(data.length, 4);
    expect(data.isAligned, isFalse);
    expect(data.residueAt(0, 3), 0x54);
    expect(data.residueAt(1, 3), isNull);
    expect(data.residueAt(2, 0), isNull);
  });
}
