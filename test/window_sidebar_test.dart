import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/alignment/window_sidebar.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/src/rust/api/alignment_view.dart';
import 'package:segui/styles/themes.dart';

/// Rows held in Dart that answer window requests like Rust, recording them.
class _PagedResidues extends MemoryResidues {
  _PagedResidues(List<Uint8List> rows) : super(['a'], rows, isDna: true);

  final List<(int, int)> requests = [];

  @override
  Future<List<AlignmentWindowStat>> windowStats(
    int windowSize,
    int first,
    int count,
  ) async {
    requests.add((first, count));
    final int length = rows.first.length;
    return [
      for (int c = first; c < first + count && c * windowSize < length; c++)
        AlignmentWindowStat(
          start: c * windowSize,
          end: ((c + 1) * windowSize).clamp(0, length),
          gapFraction: 0.25,
          variableFraction: 0.5,
        ),
    ];
  }
}

void main() {
  testWidgets('Summarizes only the pages of windows in view', (tester) async {
    const int windowSize = 250;
    // 1,000 windows, many more than the sidebar shows at once.
    final Uint8List row = Uint8List(windowSize * 1000)..fillRange(0, 1, 0x41);
    final _PagedResidues residues = _PagedResidues([row]);
    final AlignmentViewData data = AlignmentViewData(
      names: const ['a'],
      lengths: Uint32List.fromList([row.length]),
      length: row.length,
      isAligned: true,
      isDna: true,
      residues: residues,
    );
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: Scaffold(
          body: WindowSidebar(
            data: data,
            windowSize: windowSize,
            currentWindow: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    ));
    expect(find.text('Counting…'), findsWidgets);
    await tester.pumpAndSettle();

    expect(residues.requests, [(0, windowPageSize)]);
    expect(find.text('1–250'), findsOneWidget);
    expect(find.text('Gaps 25% · Variable 50%'), findsWidgets);
  });
}
