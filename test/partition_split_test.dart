import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/alignment/partition.dart';
import 'package:segui/screens/alignment/split.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/summary.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/tasks/alignment.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Widget wrapWithApp(ProviderContainer container, Widget child) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('PartitionConversionPage defaults and toggles work',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        settingProvider.overrideWithValue(preferences),
        inputSummaryProvider.overrideWith(
          (ref) => Future.value(FileSetSummary.empty()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrapWithApp(container, const PartitionConversionPage()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ExecutionButton), findsOneWidget);
    final codonSwitchFinder =
        find.widgetWithText(SwitchForm, 'Convert to codon model');
    final checkSwitchFinder =
        find.widgetWithText(SwitchForm, 'Check partition for errors');

    expect(tester.widget<SwitchForm>(codonSwitchFinder).value, isFalse);
    expect(tester.widget<SwitchForm>(checkSwitchFinder).value, isTrue);

    final codonToggle = find.descendant(
      of: codonSwitchFinder,
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(codonToggle);
    await tester.tap(codonToggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchForm>(codonSwitchFinder).value, isTrue);
  });

  testWidgets(
      'SplitAlignmentPage allows embedded Charset without extra partition file',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        settingProvider.overrideWithValue(preferences),
        inputSummaryProvider.overrideWith(
          (ref) => Future.value(FileSetSummary.empty()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrapWithApp(container, const SplitAlignmentPage()),
    );
    await tester.pumpAndSettle();

    final checkSwitch = tester.widget<SwitchForm>(
      find.widgetWithText(SwitchForm, 'Check partition for errors'),
    );
    expect(checkSwitch.value, isTrue);

    await tester.runAsync(() async {
      await container.read(fileInputProvider.notifier).addFiles(
        [XFile(p.join('test', 'files', 'first.fas'))],
        sequenceTypeGroup,
      );
    });
    await tester.pumpAndSettle();

    // Select Output Format = FASTA (last 'FASTA' segment on screen; Input Format is first).
    final fastaOut = find.text('FASTA').last;
    await tester.ensureVisible(fastaOut);
    await tester.tap(fastaOut);
    await tester.pumpAndSettle();

    // Default Partition Format is NEXUS, which requires a separate partition file.
    ExecutionButton button =
        tester.widget<ExecutionButton>(find.byType(ExecutionButton));
    expect(button.onExecuted, isNull);

    // Switch Partition Format to Charset: embedded partition needs no second file.
    final charsetSeg = find.text('Charset');
    await tester.ensureVisible(charsetSeg);
    await tester.tap(charsetSeg);
    await tester.pumpAndSettle();

    button = tester.widget<ExecutionButton>(find.byType(ExecutionButton));
    expect(button.onExecuted, isNotNull);

    // Switch Partition Format to RaXML: disabled until a partition file is added.
    final raxmlSeg = find.text('RaXML');
    await tester.ensureVisible(raxmlSeg);
    await tester.tap(raxmlSeg);
    await tester.pumpAndSettle();

    button = tester.widget<ExecutionButton>(find.byType(ExecutionButton));
    expect(button.onExecuted, isNull);

    await tester.runAsync(() async {
      await container.read(fileInputProvider.notifier).replaceType(
        [XFile(p.join('test', 'files', 'parts.txt'))],
        partitionTypeGroup,
      );
    });
    await tester.pumpAndSettle();

    button = tester.widget<ExecutionButton>(find.byType(ExecutionButton));
    expect(button.onExecuted, isNotNull);
  });

  test('SplitAlignmentRunner accepts null inputPartition for Charset', () {
    final runner = SplitAlignmentRunner(
      inputFile: p.join('dir', 'concat.nex'),
      inputFmt: 'NEXUS',
      inputPartitionFmt: 'Charset',
      inputPartition: null,
      datatype: 'DNA',
      outputDir: p.join('dir', 'out'),
      prefix: '',
      outputFmt: 'FASTA',
      isUncheck: false,
    );
    expect(runner.inputPartition, isNull);
  });
}
