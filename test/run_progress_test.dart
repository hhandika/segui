import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/services/tasks/progress.dart';

void main() {
  test('formats elapsed time', () {
    expect(formatElapsed(const Duration(seconds: 5)), '0:05');
    expect(formatElapsed(const Duration(minutes: 2, seconds: 14)), '2:14');
    expect(
      formatElapsed(const Duration(hours: 1, minutes: 3, seconds: 9)),
      '1:03:09',
    );
  });

  test('progress fraction is unknown before the total and during a stage', () {
    final DateTime now = DateTime.now();
    expect(RunProgress(tool: null, startedAt: now).fraction, isNull);
    expect(
      RunProgress(tool: null, startedAt: now, done: 3, total: 12).fraction,
      0.25,
    );
    expect(
      RunProgress(
        tool: null,
        startedAt: now,
        done: 12,
        total: 12,
        stage: 'Writing records',
      ).fraction,
      isNull,
    );
  });

  testWidgets('progress bar shows file count and current file',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskProgressBar(
          progress: RunProgress(
            tool: null,
            startedAt: DateTime.now(),
            done: 3,
            total: 12,
            currentFile: 'sample_R1.fastq.gz',
          ),
        ),
      ),
    ));
    expect(find.text('3 of 12 files'), findsOneWidget);
    expect(find.textContaining('sample_R1.fastq.gz'), findsOneWidget);
    final LinearProgressIndicator bar =
        tester.widget(find.byType(LinearProgressIndicator));
    expect(bar.value, 0.25);
  });

  testWidgets('cancel button turns into a disabled cancelling button',
      (WidgetTester tester) async {
    int presses = 0;
    Future<void> pump(bool isCancelling) {
      return tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CancelRunButton(
            isCancelling: isCancelling,
            onPressed: () => presses++,
          ),
        ),
      ));
    }

    await pump(false);
    await tester.tap(find.text('Cancel'));
    expect(presses, 1);
    await pump(true);
    await tester.tap(find.text('Cancelling…'));
    expect(presses, 1);
  });
}
