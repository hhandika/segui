import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/home/home.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/types.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('Home lists every operation exactly once', () {
    final operations = homeTools.map((tool) => tool.operation).toSet();
    expect(operations, {
      ...GenomicOperationType.values,
      ...AlignmentOperationType.values,
      ...SequenceOperationType.values,
    });
    expect(operations.length, homeTools.length);
  });

  test('Workflow steps come from the home tool list', () {
    for (final workflow in homeWorkflows) {
      expect(workflow.steps.length, greaterThan(1));
      expect(homeTools, containsAll(workflow.steps));
    }
  });

  test('Tool search matches titles, descriptions, and categories', () {
    expect(filterHomeTools(ToolCategory.alignment, ''), hasLength(6));
    expect(
      filterHomeTools(ToolCategory.alignment, ' phylip ').map((t) => t.title),
      ['Convert alignments'],
    );
    expect(filterHomeTools(ToolCategory.sequence, 'sequences'), hasLength(5));
    expect(filterHomeTools(ToolCategory.genomics, 'translate'), isEmpty);
  });

  test('Opening a tool selects its page and operation', () {
    final navigator = container.read(homeToolNavigatorProvider);
    navigator.open(translationTool);
    expect(container.read(tabSelectionProvider), 3);
    expect(
      container.read(sequenceOperationSelectionProvider),
      SequenceOperationType.translation,
    );

    navigator.open(contigSummaryTool);
    expect(container.read(tabSelectionProvider), 1);
    expect(
      container.read(genomicOperationSelectionProvider),
      GenomicOperationType.contigSummary,
    );

    navigator.open(splitTool);
    expect(container.read(tabSelectionProvider), 2);
    expect(
      container.read(alignmentOperationSelectionProvider),
      AlignmentOperationType.split,
    );
  });

  test('Home view defaults to tools and persists the choice', () async {
    expect(container.read(homeViewProvider), HomeView.tools);
    await container.read(homeViewProvider.notifier).setView(HomeView.workflows);
    expect(preferences.getString('homeView'), 'workflows');

    final restored = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(restored.dispose);
    expect(restored.read(homeViewProvider), HomeView.workflows);
  });

  testWidgets('Home toggles between tools and workflows', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: HomePage())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Translate sequences'), findsOneWidget);
    expect(find.text('Common workflows'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nexus');
    await tester.pumpAndSettle();
    expect(find.text('Translate sequences'), findsNothing);
    expect(find.text('Convert alignments'), findsOneWidget);

    await tester.tap(find.text('Workflows'));
    await tester.pumpAndSettle();
    expect(find.text('Common workflows'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(container.read(homeViewProvider), HomeView.workflows);

    await tester.tap(find.widgetWithText(ActionChip, 'Translate sequences'));
    await tester.pumpAndSettle();
    expect(container.read(tabSelectionProvider), 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home fills the screen height when content is short',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await preferences.setString('homeView', 'workflows');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: Center(child: HomePage()))),
    ));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(HomePage)).height, 2400);
    expect(tester.getBottomLeft(find.text('Documentation')).dy,
        greaterThan(2400 - 100));
  });
}
