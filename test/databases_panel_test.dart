import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/database/panel.dart';
import 'package:segui/screens/shared/io/picker_widget.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/providers/databases.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'databases_fake.dart';

const Size desktop = Size(1400, 1000);
const Size phone = Size(390, 844);

FakeDatabaseClient proteinClient() {
  return FakeDatabaseClient((url, form) {
    if (url.path.endsWith('esearch.fcgi')) {
      return ok(jsonEncode({
        'esearchresult': {
          'count': '1',
          'webenv': 'W',
          'querykey': '1',
          'idlist': ['34538610'],
        },
      }));
    }
    if (url.path.endsWith('esummary.fcgi')) {
      return ok(jsonEncode({
        'result': {
          'uids': ['34538610'],
          '34538610': {
            'accessionversion': 'NP_904340.1',
            'organism': 'Mus musculus',
            'title': 'cytochrome b (mitochondrion) [Mus musculus]',
            'slen': 381,
          },
        },
      }));
    }
    return ok('>NP_904340.1 cytochrome b [Mus musculus]\nMTNMRKTHPL\n');
  });
}

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('segui-panel-');
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required Size size,
    required SupportedTask task,
    XTypeGroup group = sequenceTypeGroup,
    FakeDatabaseClient? client,
    IOController? controller,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      settingProvider.overrideWithValue(preferences),
      databaseClientProvider.overrideWithValue(client ?? proteinClient()),
      downloadsDirProvider.overrideWithValue(() async => root),
      // The Rust library that reads free space is not loaded in tests.
      downloadSpaceProvider.overrideWith((ref) async => 2 * 1024 * 1024 * 1024),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: brightness == Brightness.light
            ? SeguiTheme.lightTheme()
            : SeguiTheme.darkTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: controller == null
                ? SharedFilePicker(
                    label: 'Select files',
                    allowMultiple: true,
                    xTypeGroup: group,
                    hasSecondaryPicker: false,
                    task: task,
                    allowDirectorySelection: true,
                  )
                : SharedSequenceInputForm(
                    ctr: controller,
                    xTypeGroup: group,
                    task: task,
                  ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> openPanel(WidgetTester tester, Size size) async {
    if (size == phone) {
      await tester.tap(find.text('Browse'));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Search databases'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search databases'));
    await tester.pumpAndSettle();
  }

  for (final task in [
    SupportedTask.alignmentConcatenation,
    SupportedTask.alignmentDistance,
    SupportedTask.alignmentFiltering,
    SupportedTask.alignmentSplitting,
    SupportedTask.alignmentSummary,
    SupportedTask.alignmentTrimming,
    SupportedTask.alignmentUnalignment,
  ]) {
    testWidgets('$task shows a note instead of the search', (tester) async {
      await pump(tester, size: desktop, task: task);
      expect(find.text('Search databases'), findsNothing);
      expect(find.textContaining('Needs aligned sequences'), findsOneWidget);
    });
  }

  for (final (task, group) in [
    (SupportedTask.sequenceTranslation, sequenceTypeGroup),
    (SupportedTask.sequenceFiltering, sequenceTypeGroup),
    (SupportedTask.alignmentConversion, sequenceTypeGroup),
    (SupportedTask.sequenceAddition, destinationSequenceTypeGroup),
    (SupportedTask.genomicRawReadSummary, genomicRawReadTypeGroup),
    (SupportedTask.genomicContigSummary, genomicContigTypeGroup),
  ]) {
    testWidgets('$task ${group.label} offers the search', (tester) async {
      await pump(tester, size: desktop, task: task, group: group);
      expect(find.text('Search databases'), findsOneWidget);
      expect(find.textContaining('Needs aligned sequences'), findsNothing);
    });
  }

  testWidgets('Tools outside the archives show neither', (tester) async {
    await pump(
      tester,
      size: desktop,
      task: SupportedTask.genomicMafSummary,
      group: mafTypeGroup,
    );
    expect(find.text('Search databases'), findsNothing);
    expect(find.textContaining('Needs aligned sequences'), findsNothing);
  });

  testWidgets('Reads hide GenBank', (tester) async {
    await pump(
      tester,
      size: desktop,
      task: SupportedTask.genomicRawReadSummary,
      group: genomicRawReadTypeGroup,
    );
    await openPanel(tester, desktop);
    expect(find.text('GenBank'), findsNothing);
    expect(find.text('Gene'), findsNothing);
  });

  testWidgets('ENA does not offer proteins', (tester) async {
    await pump(tester, size: desktop, task: SupportedTask.sequenceFiltering);
    await openPanel(tester, desktop);
    await tester.tap(find.text('ENA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Whole record'));
    await tester.pumpAndSettle();
    expect(find.text('Protein'), findsNothing);
    expect(find.text('Coding sequence'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    for (final (name, size) in [
      ('desktop', desktop),
      ('phone', phone),
      ('short phone', const Size(568, 320)),
    ]) {
      testWidgets('Panel fits a $name in ${brightness.name}', (tester) async {
        await pump(
          tester,
          size: size,
          task: SupportedTask.sequenceFiltering,
          brightness: brightness,
        );
        await openPanel(tester, size.width < 600 ? phone : size);
        expect(tester.takeException(), isNull);
        expect(
          tester
              .getSize(find.descendant(
                of: find.byType(DatabasePanel),
                matching: find.byType(Scaffold),
              ))
              .width,
          size.width < 600 ? size.width : SeguiContentWidth.databasePanel,
        );
      });
    }
  }

  testWidgets('Picker actions scroll in a short wide window', (tester) async {
    await pump(
      tester,
      size: const Size(844, 320),
      task: SupportedTask.sequenceFiltering,
    );
    showPickerActions(
      tester.element(find.byType(SharedFilePicker)),
      title: 'Select files',
      actions: [
        for (int i = 0; i < 7; i++)
          PickerAction(
            label: 'Action $i',
            icon: Icons.add,
            onSelected: () {},
          ),
      ],
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('An empty search explains what to enter', (tester) async {
    await pump(tester, size: desktop, task: SupportedTask.sequenceFiltering);
    await openPanel(tester, desktop);
    final button = find.widgetWithText(FilledButton, 'Search');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(
      find.text('Enter an organism, gene, or keyword.').hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('A search scrolls its results into view', (tester) async {
    const size = Size(1400, 760);
    await pump(tester, size: size, task: SupportedTask.sequenceFiltering);
    await openPanel(tester, size);
    await tester.enterText(find.widgetWithText(TextField, 'Organism'), 'Mu');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Mus musculus').hitTestable(), findsOneWidget);
    expect(find.textContaining('2.00 Gb free'), findsOneWidget);
  });

  testWidgets('A download becomes input and sets the form', (tester) async {
    final controller = IOController.empty();
    addTearDown(controller.dispose);
    final container = await pump(
      tester,
      size: desktop,
      task: SupportedTask.sequenceUniqueId,
      controller: controller,
    );
    await openPanel(tester, desktop);
    await tester.tap(find.text('Whole record'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Protein').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paste accessions'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Accessions'),
      'NP_904340.1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Find'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Download and add'));
    // File IO ends in real time, and the widgets in fake time.
    for (int i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      if (find.byType(DatabasePanel).evaluate().isEmpty) break;
    }
    expect(find.byType(DatabasePanel), findsNothing);
    final inputs = container.read(fileInputProvider).value!;
    expect(inputs.single.file.readAsLinesSync().first,
        '>Mus_musculus_NP_904340.1');
    expect(controller.inputFormatController, 'FASTA');
    expect(controller.dataTypeController, 'AA');
    expect(find.text('1 file selected'), findsOneWidget);
  });
}
