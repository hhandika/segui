import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/alignment/entry_page.dart';
import 'package:segui/screens/sequence/entry_page.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/screens/shared/tool_search.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/types.dart';
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

  test('File panel shows output after a run and input after new files',
      () async {
    final container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    final Directory dir = await Directory.systemTemp.createTemp('segui-run-');
    addTearDown(() => dir.delete(recursive: true));

    expect(container.read(filePanelViewProvider), FilePanelView.input);
    await container.read(fileOutputProvider.notifier).add(dir);
    await File(p.join(dir.path, 'concat.nex')).writeAsString('#NEXUS\n');
    await container.read(fileOutputProvider.notifier).refresh();
    expect(container.read(filePanelViewProvider), FilePanelView.output);

    await container.read(fileInputProvider.notifier).clearAll();
    expect(container.read(filePanelViewProvider), FilePanelView.input);
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
}
