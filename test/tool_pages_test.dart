import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/alignment/entry_page.dart';
import 'package:segui/screens/genomics/entry_page.dart';
import 'package:segui/screens/sequence/entry_page.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/illustrations.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Widget pageFor(ToolCategory category) {
    switch (category) {
      case ToolCategory.genomics:
        return const GenomicPage();
      case ToolCategory.alignment:
        return const AlignmentPage();
      case ToolCategory.sequence:
        return const SequencePage();
    }
  }

  for (final size in const [Size(1600, 1000), Size(390, 844)]) {
    testWidgets('Every tool page renders at ${size.width.toInt()} px wide',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final tool in homeTools) {
        final container = ProviderContainer(
          overrides: [settingProvider.overrideWithValue(preferences)],
        );
        addTearDown(container.dispose);
        container.read(homeToolNavigatorProvider).open(tool);

        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: SeguiTheme.lightTheme(),
            home: Scaffold(body: pageFor(tool.category)),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(ExecutionButton), findsOneWidget,
            reason: tool.title);
        expect(find.byType(ToolScene), findsOneWidget, reason: tool.title);
        expect(tester.takeException(), isNull, reason: tool.title);
      }
    });
  }
}
