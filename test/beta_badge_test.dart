import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/home/components/tool_catalog.dart';
import 'package:segui/screens/shared/badges.dart';
import 'package:segui/services/home_features.dart';

void main() {
  test('Only MAF and genetic distance tools are in beta', () {
    expect(
      homeTools.where((tool) => tool.isBeta).toSet(),
      {
        mafConversionTool,
        mafSummaryTool,
        distanceTool,
      },
    );
  });

  testWidgets('Tool cards show a beta badge only for beta tools',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ToolCard(tool: distanceTool),
                ToolCard(tool: concatenationTool),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(BetaBadge), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(ToolCard, distanceTool.title),
        matching: find.text('Beta'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Beta title truncates long text beside the badge',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: BetaTitle(
              text: 'A very long tool title that cannot fit',
              isBeta: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(BetaBadge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
