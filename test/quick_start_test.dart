import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/home/components/quick_start.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/quick_start.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  /// Asset keys use POSIX separators; build a host path from them.
  File assetFile(String asset) => File(p.joinAll(p.posix.split(asset)));

  test('Every tool has a gull scene and feature diagrams', () {
    for (final tool in homeTools) {
      expect(assetFile(tool.sceneAsset).existsSync(), isTrue,
          reason: tool.title);
      expect(tool.diagramAssets, isNotEmpty, reason: tool.title);
      for (final asset in tool.diagramAssets) {
        final File file = assetFile(asset);
        expect(file.existsSync(), isTrue, reason: asset);
        // Flutter ignores CSS, so the export must resolve every class.
        expect(file.readAsStringSync(), isNot(contains('class=')),
            reason: asset);
      }
    }
    expect(homeTools.map((tool) => tool.scene).toSet(),
        hasLength(homeTools.length));
  });

  test('Feature guides filter by category', () {
    expect(featureGuidesFor(null), homeTools);
    for (final category in ToolCategory.values) {
      expect(featureGuidesFor(category).every((t) => t.category == category),
          isTrue);
    }
    expect(quickStartSteps, hasLength(5));
  });

  Future<ProviderContainer> pumpQuickStart(
      WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuickStartPage()),
                ),
                child: const Text('Open quick start'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open quick start'));
    await tester.pumpAndSettle();
    return container;
  }

  for (final size in const [Size(1400, 1000), Size(390, 844)]) {
    testWidgets('Quick start renders at ${size.width.toInt()} px wide',
        (tester) async {
      await pumpQuickStart(tester, size);
      expect(find.byType(QuickStartStepCard), findsNWidgets(5));
      expect(find.byType(FeatureGuideCard), findsNWidgets(homeTools.length));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Quick start filters guides and opens a tool', (tester) async {
    final container = await pumpQuickStart(tester, const Size(1400, 1000));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Genomics (4)'));
    await tester.pumpAndSettle();
    expect(find.byType(FeatureGuideCard), findsNWidgets(4));

    final viewGuide = find.descendant(
      of: find.widgetWithText(FeatureGuideCard, mafSummaryTool.title),
      matching: find.text('View guide'),
    );
    await tester.ensureVisible(viewGuide);
    await tester.tap(viewGuide);
    await tester.pumpAndSettle();
    expect(find.byType(FeatureGuidePage), findsOneWidget);
    expect(find.text(mafSummaryTool.about), findsOneWidget);

    final openTool = find.widgetWithText(FilledButton, 'Open tool');
    await tester.ensureVisible(openTool);
    await tester.tap(openTool);
    await tester.pumpAndSettle();
    expect(find.byType(QuickStartPage), findsNothing);
    expect(container.read(tabSelectionProvider), 1);
    expect(container.read(genomicOperationSelectionProvider),
        GenomicOperationType.mafSummary);
    expect(tester.takeException(), isNull);
  });

  test('Every platform has input guidelines', () {
    for (final platform in InputPlatform.values) {
      expect(inputGuidelinesFor(platform), isNotEmpty, reason: platform.name);
    }
    final List<String> ios =
        inputGuidelinesFor(InputPlatform.ios).map((e) => e.title).toList();
    expect(ios, contains('SEGUI folder'));
    final List<String> desktop =
        inputGuidelinesFor(InputPlatform.desktop).map((e) => e.title).toList();
    expect(desktop, isNot(contains('SEGUI folder')));
    expect(desktop, isNot(contains('Use shared files')));
  });

  for (final platform in InputPlatform.values) {
    testWidgets('Input guide shows ${platform.name} guidelines',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: QuickStartInputGuide(platform: platform),
          ),
        ),
      ));

      expect(find.text(platform.label), findsOneWidget);
      expect(find.byType(InputGuidelineCard),
          findsNWidgets(inputGuidelinesFor(platform).length));
      expect(find.byType(MobileInputTip),
          platform.isMobile ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
