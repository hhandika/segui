import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/alignment/entry_page.dart';
import 'package:segui/screens/shared/io/workbench_view.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/workbench.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('segui-workbench-');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  List<File> writeFiles(List<String> names) {
    return [
      for (final name in names)
        File(p.join(dir.path, name))..writeAsStringSync('ACGT'),
    ];
  }

  List<String> names(List<File> files) =>
      [for (final file in files) p.basename(file.path)];

  test('Every tool has a data flow', () {
    for (final tool in homeTools) {
      expect(dataFlowFor(tool).accepts, isNotEmpty, reason: tool.title);
    }
  });

  test('Partition files are named by SEGUL', () {
    expect(isPartitionFile(File(p.join('out', 'concat_partition.nex'))), true);
    expect(isPartitionFile(File(p.join('out', 'concat_partition.txt'))), true);
    expect(isPartitionFile(File(p.join('out', 'concat.nex'))), false);
  });

  test('Filter suggests the next workflow step with its output', () {
    final WorkbenchSuggestions suggestions = WorkbenchSuggestions.after(
      tool: filterTool,
      inputFiles: writeFiles(['a.nex', 'b.nex', 'c.nex']),
      outputFiles: writeFiles(['a_out.fas', 'b_out.fas', 'log.txt']),
    );

    final WorkflowProgress supermatrix = suggestions.workflows.firstWhere(
        (progress) => progress.workflow.title.contains('supermatrix'));
    expect(supermatrix.stepIndex, 1);
    expect(supermatrix.next!.tool, concatenationTool);
    expect(supermatrix.next!.isFromOutput, true);
    expect(names(supermatrix.next!.inputs.single.files),
        ['a_out.fas', 'b_out.fas']);

    final WorkflowProgress loci = suggestions.workflows.firstWhere(
        (progress) => progress.workflow.title.contains('genome alignments'));
    expect(loci.isComplete, true);

    final List<HomeTool> tools = [
      for (final step in suggestions.tools) step.tool,
    ];
    expect(tools, isNot(contains(filterTool)));
    // Already offered as the workflow's next step.
    expect(tools, isNot(contains(concatenationTool)));
    expect(tools, contains(alignmentSummaryTool));
    expect(tools, contains(removalTool));
    expect(tools, isNot(contains(readSummaryTool)));
    expect(tools, isNot(contains(partitionTool)));
  });

  test('Summaries pass their input to the next step', () {
    final WorkbenchSuggestions suggestions = WorkbenchSuggestions.after(
      tool: alignmentSummaryTool,
      inputFiles: writeFiles(['a.nex', 'b.nex']),
      outputFiles: writeFiles(['summary.csv']),
    );

    final WorkbenchStep next = suggestions.workflows
        .firstWhere((progress) => progress.next?.tool == filterTool)
        .next!;
    expect(next.isFromOutput, false);
    expect(names(next.inputs.single.files), ['a.nex', 'b.nex']);
  });

  test('Split gets one alignment and its partition', () {
    final WorkbenchSuggestions suggestions = WorkbenchSuggestions.after(
      tool: concatenationTool,
      inputFiles: writeFiles(['a.nex', 'b.nex']),
      outputFiles: writeFiles(['concat.nex', 'concat_partition.txt']),
    );

    final WorkbenchStep split =
        suggestions.tools.firstWhere((step) => step.tool == splitTool);
    expect(split.inputs.map((input) => input.group),
        [sequenceTypeGroup, partitionTypeGroup]);
    expect(names(split.inputs.first.files), ['concat.nex']);
    expect(names(split.inputs.last.files), ['concat_partition.txt']);

    final WorkbenchStep summary = suggestions.tools
        .firstWhere((step) => step.tool == alignmentSummaryTool);
    expect(names(summary.inputs.single.files), ['concat.nex']);
  });

  test('Steps whose data does not match open without files', () {
    final WorkbenchSuggestions suggestions = WorkbenchSuggestions.after(
      tool: readSummaryTool,
      inputFiles: writeFiles(['a_R1.fastq.gz']),
      outputFiles: writeFiles(['reads.csv']),
    );

    final WorkbenchStep next = suggestions.workflows.single.next!;
    expect(next.tool, contigSummaryTool);
    expect(next.inputs, isEmpty);
    expect(stepInputCaption(next), 'Opens without input files');
    expect(suggestions.tools, isEmpty);
  });

  group('Last run', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [settingProvider.overrideWithValue(preferences)],
      );
      container.read(tabSelectionProvider.notifier).setTab(2);
      container
          .read(alignmentOperationSelectionProvider.notifier)
          .setOperation(AlignmentOperationType.filter);
    });

    tearDown(() => container.dispose());

    test('Keeps settings until the input or tool changes', () async {
      final keep = container.listen(lastRunProvider, (_, __) {});
      addTearDown(keep.close);
      await container.read(fileInputProvider.notifier).addFiles([
        XFile(writeFiles(['a.nex']).single.path)
      ], sequenceTypeGroup);
      expect(container.read(workbenchSuggestionsProvider), isNull);

      container.read(lastRunProvider.notifier).record(const [
        RunParameter('Filter by', 'Minimum length'),
        RunParameter('Output prefix', ''),
      ]);
      final ToolRun run = container.read(lastRunProvider)!;
      expect(run.tool, filterTool);
      expect(run.parameters.map((e) => e.label), ['Filter by']);
      expect(container.read(workbenchSuggestionsProvider), isNotNull);

      await container.read(fileInputProvider.notifier).clearAll();
      expect(container.read(lastRunProvider), isNull);

      container.read(lastRunProvider.notifier).record(const []);
      container
          .read(alignmentOperationSelectionProvider.notifier)
          .setOperation(AlignmentOperationType.trimming);
      expect(container.read(lastRunProvider), isNull);
    });

    test('Opening a step switches tools and sets its input', () async {
      final WorkbenchStep step = WorkbenchStep(
        tool: contigSummaryTool,
        inputs: [
          ChainInput(
            group: genomicContigTypeGroup,
            files: writeFiles(['a.fasta', 'b.fasta']),
          ),
        ],
        isFromOutput: true,
      );
      await container.read(workbenchNavigatorProvider).open(step);

      expect(container.read(tabSelectionProvider), 1);
      expect(container.read(genomicOperationSelectionProvider),
          GenomicOperationType.contigSummary);
      final List<SegulInputFile> input =
          container.read(fileInputProvider).value!;
      expect(input.map((e) => p.basename(e.file.path)), ['a.fasta', 'b.fasta']);
      expect(input.map((e) => e.type).toSet(), {SegulType.genomicContig});
    });
  });

  testWidgets('Workbench shows parameters and next steps after a run',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    container.read(tabSelectionProvider.notifier).setTab(2);
    container
        .read(alignmentOperationSelectionProvider.notifier)
        .setOperation(AlignmentOperationType.filter);
    tester.view.physicalSize = const Size(1600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: const Scaffold(body: AlignmentPage()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(NextStepsHint), findsOneWidget);
    expect(find.text('Suggested workflows'), findsNothing);

    final Directory outputDir = Directory(p.join(dir.path, 'out'))
      ..createSync();
    await tester.runAsync(() async {
      await container.read(fileInputProvider.notifier).addFiles([
        for (final file in writeFiles(['a.nex', 'b.nex'])) XFile(file.path)
      ], sequenceTypeGroup);
      await container.read(fileOutputProvider.notifier).add(outputDir);
      for (final name in ['a.fas', 'b.fas']) {
        File(p.join(outputDir.path, name)).writeAsStringSync('ACGT');
      }
      container.read(lastRunProvider.notifier).record(const [
        RunParameter('Filter by', 'Minimum length'),
        RunParameter('Value', '800'),
      ]);
      await container.read(fileOutputProvider.notifier).refresh();
    });
    await tester.pumpAndSettle();

    expect(find.byType(NextStepsHint), findsNothing);
    expect(find.byType(RunParametersCard), findsOneWidget);
    expect(find.text('Minimum length'), findsOneWidget);
    expect(find.text('Suggested workflows'), findsOneWidget);
    expect(find.byType(WorkflowProgressCard), findsNWidgets(2));
    expect(find.text('Next: Concatenate alignments'), findsOneWidget);
    expect(find.text('Uses 2 output files'), findsWidgets);
    expect(find.text('Other compatible tools'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await container.read(fileInputProvider.future);
    });
    await tester.pumpAndSettle();
    expect(container.read(alignmentOperationSelectionProvider),
        AlignmentOperationType.concatenation);
    expect(
      container
          .read(fileInputProvider)
          .value!
          .map((e) => p.basename(e.file.path)),
      unorderedEquals(['a.fas', 'b.fas']),
    );
    // The new tool has not run yet.
    expect(find.byType(NextStepsHint), findsOneWidget);
  });
}
