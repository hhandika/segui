import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/alignment/entry_page.dart';
import 'package:segui/screens/sequence/entry_page.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/picker_widget.dart';
import 'package:segui/screens/shared/io/summary_view.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/screens/shared/tool_search.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/summary.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/segui_icons.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    Size size, {
    Widget page = const AlignmentPage(),
    ProviderContainer? container,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final Widget app = MaterialApp(
      theme: SeguiTheme.lightTheme(),
      home: Scaffold(body: page),
    );
    await tester.pumpWidget(container == null
        ? ProviderScope(
            overrides: [settingProvider.overrideWithValue(preferences)],
            child: app,
          )
        : UncontrolledProviderScope(container: container, child: app));
    await tester.pumpAndSettle();
  }

  testWidgets('Wide tool page shows the tool list, form, and file panel',
      (tester) async {
    await pumpPage(tester, const Size(1600, 1000));

    expect(find.byType(ToolListPanel), findsOneWidget);
    expect(find.byType(ToolSwitcherButton), findsNothing);
    expect(find.byType(FileSidePanel), findsOneWidget);
    expect(find.byType(FilesButton), findsNothing);
    expect(find.byType(StepBadge), findsNWidgets(2));
    expect(find.byType(ToolRunBar), findsOneWidget);
    expect(find.byType(ExecutionButton), findsOneWidget);
    // Outlined like the home screen on wide layouts.
    expect(
      find.ancestor(
        of: find.byType(ToolListPanel),
        matching: find.byType(OutlinedPanel),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Medium tool page swaps the tool list for a switcher',
      (tester) async {
    await pumpPage(tester, const Size(1000, 900));

    expect(find.byType(ToolListPanel), findsNothing);
    expect(find.byType(ToolSwitcherButton), findsOneWidget);
    expect(find.byType(FileSidePanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compact tool page opens files from the header', (tester) async {
    await pumpPage(tester, const Size(390, 844));

    expect(find.byType(FileSidePanel), findsNothing);
    expect(find.byType(ToolSwitcherButton), findsOneWidget);
    expect(find.byType(ToolRunBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(FilesButton));
    await tester.pumpAndSettle();
    expect(find.byType(FilesPage), findsOneWidget);
    expect(find.text('No input files selected.'), findsOneWidget);
  });

  testWidgets('Short option lists render as segmented buttons', (tester) async {
    await pumpPage(tester, const Size(1600, 1000));

    // Concatenate shows input format, data type, output format, and
    // partition format as segments.
    expect(find.byType(SegmentedField), findsNWidgets(4));
  });

  testWidgets('Tool list opens the tapped tool', (tester) async {
    final container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    await pumpPage(
      tester,
      const Size(1600, 1000),
      page: const SequencePage(),
      container: container,
    );

    await tester.tap(find.text(translationTool.title));
    await tester.pumpAndSettle();
    expect(
      container.read(sequenceOperationSelectionProvider),
      SequenceOperationType.translation,
    );
    expect(find.text(translationTool.about), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tool list has no search field', (tester) async {
    await pumpPage(tester, const Size(1600, 1000));

    expect(
      find.descendant(
        of: find.byType(ToolListPanel),
        matching: find.byType(SearchBar),
      ),
      findsNothing,
    );
  });

  testWidgets('Tool list shows the full description on hover', (tester) async {
    await pumpPage(tester, const Size(1600, 1000));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.text(filterTool.title)));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text(filterTool.about), findsOneWidget);
  });

  test('File panel grows into space the form does not need', () {
    expect(filePanelWidth(1200, hasToolList: true), minFilePanelWidth);
    expect(filePanelWidth(1600, hasToolList: true), 496);
    expect(filePanelWidth(2400, hasToolList: true), maxFilePanelWidth);
    expect(filePanelWidth(1300, hasToolList: false), 476);
  });

  testWidgets('Wide file panel uses the extra width', (tester) async {
    await pumpPage(tester, const Size(1800, 1000));

    final double width = tester.getSize(find.byType(FileSidePanel)).width;
    expect(width, filePanelWidth(1784, hasToolList: true));
    expect(width, greaterThan(minFilePanelWidth));
  });

  test('File panel shows output after a run and summary after new files',
      () async {
    final container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    final Directory dir = await Directory.systemTemp.createTemp('segui-run-');
    addTearDown(() => dir.delete(recursive: true));

    expect(container.read(filePanelViewProvider), FilePanelView.summary);
    await container.read(fileOutputProvider.notifier).add(dir);
    await File(p.join(dir.path, 'concat.nex')).writeAsString('#NEXUS\n');
    await container.read(fileOutputProvider.notifier).refresh();
    expect(container.read(filePanelViewProvider), FilePanelView.output);

    await container.read(fileInputProvider.notifier).clearAll();
    expect(container.read(filePanelViewProvider), FilePanelView.summary);
  });

  testWidgets('New tool page resets the file panel without a build error',
      (tester) async {
    final container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    final panel = container.listen(filePanelViewProvider, (_, __) {});
    addTearDown(panel.close);
    container.read(fileInputProvider);
    container.read(filePanelViewProvider.notifier).show(FilePanelView.output);
    expect(panel.read(), FilePanelView.output);
    container.invalidate(fileInputProvider);

    // The page's first build rebuilds the invalidated input files.
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          ref.watch(fileInputProvider);
          return Text(ref.watch(filePanelViewProvider).name);
        }),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('summary'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('Global search opens any tool', (tester) async {
    final container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: Scaffold(
          appBar: AppBar(actions: const [GlobalToolSearch()]),
        ),
      ),
    ));

    await tester.tap(find.byType(SearchBar));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'translate');
    await tester.pumpAndSettle();
    expect(find.byType(ToolSearchResult), findsOneWidget);

    await tester.tap(find.byType(ToolSearchResult));
    await tester.pumpAndSettle();
    expect(container.read(tabSelectionProvider), 3);
    expect(
      container.read(sequenceOperationSelectionProvider),
      SequenceOperationType.translation,
    );
  });

  testWidgets('Input picker switches from drop zone to selection card',
      (tester) async {
    final container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    container.read(tabSelectionProvider.notifier).setTab(2);
    final Directory dir = Directory.systemTemp.createTempSync('segui-pick-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final List<XFile> files = ['locus.nex', 'locus.fasta'].map((name) {
      final file = File(p.join(dir.path, name))..writeAsStringSync('x');
      return XFile(file.path);
    }).toList();
    await pumpPage(tester, const Size(1600, 1000), container: container);

    Finder pickerIcon(Type picker, IconData icon) => find.descendant(
          of: find.byType(picker),
          matching: find.byIcon(icon),
        );
    expect(
        pickerIcon(PickerDropZone, Icons.upload_file_outlined), findsOneWidget);
    expect(find.text('Browse files'), findsOneWidget);
    expect(find.text('Browse folder'), findsOneWidget);
    expect(find.byType(PickerSelectionCard), findsNothing);

    await tester.runAsync(() => container
        .read(fileInputProvider.notifier)
        .addFiles(files, sequenceTypeGroup));
    await tester.pump();
    expect(pickerIcon(PickerSelectionCard, SeguiIcons.concatenateFilled),
        findsOneWidget);
    expect(find.text('2 files selected'), findsOneWidget);
    expect(
        pickerIcon(PickerDropZone, Icons.upload_file_outlined), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Edit'));
    await tester.pumpAndSettle();
    // Wide windows list the actions in a dialog.
    expect(find.byType(PickerActionDialog), findsOneWidget);
    expect(find.byType(PickerActionSheet), findsNothing);
    expect(find.text('Add files'), findsOneWidget);
    expect(find.text('Add folder'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PickerActionDialog),
        matching: find.byType(Divider),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Clear files'));
    await tester.pumpAndSettle();
    expect(find.byType(PickerActionDialog), findsNothing);
    expect(container.read(fileInputProvider).value, isEmpty);
  });

  testWidgets('Compact window lists picker actions in a bottom sheet',
      (tester) async {
    final container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    container.read(tabSelectionProvider.notifier).setTab(2);
    final Directory dir = Directory.systemTemp.createTempSync('segui-sheet-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final XFile file = XFile(
        (File(p.join(dir.path, 'locus.nex'))..writeAsStringSync('x')).path);
    await pumpPage(tester, const Size(390, 900), container: container);
    expect(find.byType(PickerDropZoneRow), findsWidgets);

    await tester.runAsync(() => container
        .read(fileInputProvider.notifier)
        .addFiles([file], sequenceTypeGroup));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Edit').first);
    await tester.pumpAndSettle();
    expect(find.byType(PickerActionSheet), findsOneWidget);
    expect(find.byType(PickerActionDialog), findsNothing);
  });

  testWidgets('iPad portrait window lists picker actions in a dialog',
      (tester) async {
    final container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    container.read(tabSelectionProvider.notifier).setTab(2);
    final Directory dir = Directory.systemTemp.createTempSync('segui-dialog-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final XFile file = XFile(
        (File(p.join(dir.path, 'locus.nex'))..writeAsStringSync('x')).path);
    await pumpPage(tester, const Size(768, 1024), container: container);

    await tester.runAsync(() => container
        .read(fileInputProvider.notifier)
        .addFiles([file], sequenceTypeGroup));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Edit').first);
    await tester.pumpAndSettle();
    expect(find.byType(PickerActionDialog), findsOneWidget);
    expect(find.byType(PickerActionSheet), findsNothing);
  });

  testWidgets('File panel opens on the input and output summary',
      (tester) async {
    final container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    container.read(tabSelectionProvider.notifier).setTab(2);
    final Directory dir = Directory.systemTemp.createTempSync('segui-sum-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final List<XFile> files = [
      for (final name in ['a.nex', 'b.nex', 'c.fasta'])
        XFile((File(p.join(dir.path, name))..writeAsStringSync('ACGT')).path),
    ];
    await pumpPage(tester, const Size(1600, 1000), container: container);

    expect(find.byType(FileSummaryView), findsOneWidget);
    expect(find.byType(FileSummaryCard), findsNWidgets(2));
    expect(find.byIcon(SeguiIcons.inputFolderFilled), findsOneWidget);
    expect(find.byIcon(SeguiIcons.outputFolderFilled), findsOneWidget);
    expect(find.text('No input files selected.'), findsOneWidget);
    expect(find.text('No output folder selected.'), findsOneWidget);

    await tester.runAsync(() async {
      await container
          .read(fileInputProvider.notifier)
          .addFiles(files, sequenceTypeGroup);
      await container.read(inputSummaryProvider.future);
    });
    await tester.pumpAndSettle();
    final Finder inputCard = find.byType(FileSummaryCard).first;
    Finder inInput(Finder finder) =>
        find.descendant(of: inputCard, matching: finder);
    expect(inInput(find.text('3')), findsOneWidget);
    expect(inInput(find.text('files')), findsOneWidget);
    expect(inInput(find.text('0.01 Kb')), findsOneWidget);
    expect(inInput(find.text('NEXUS')), findsOneWidget);
    expect(inInput(find.text('2')), findsOneWidget);
    expect(inInput(find.text('FASTA')), findsOneWidget);

    await tester.tap(find.text('View input files'));
    await tester.pumpAndSettle();
    expect(container.read(filePanelViewProvider), FilePanelView.input);
  });

  test('Summary counts files, size, and formats', () async {
    final Directory dir = await Directory.systemTemp.createTemp('segui-sum-');
    addTearDown(() => dir.delete(recursive: true));
    final List<File> files = [
      for (final name in ['a.nex', 'b.nex', 'c.csv'])
        await File(p.join(dir.path, name)).writeAsString('1234'),
    ];
    final FileSetSummary summary = await FileSetSummary.fromFiles(files);

    expect(summary.fileCount, 3);
    expect(summary.totalBytes, 12);
    expect(summary.formatCounts, [
      (format: FileIconType.nexus, count: 2),
      (format: FileIconType.csv, count: 1),
    ]);
  });
}
