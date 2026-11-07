import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/home/components/navigation.dart';
import 'package:segui/screens/home/large_screen.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<void> pumpAt(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LargeScreenView()),
    ));
    await tester.pumpAndSettle();
  }

  for (final double width in [1000, 1200, 1599]) {
    testWidgets('Navigation is a rail at $width px', (tester) async {
      await pumpAt(tester, width);
      expect(find.byType(MediumScreenRail), findsOneWidget);
      expect(find.byType(ExpandedScreenDrawer), findsNothing);
    });
  }

  testWidgets('Navigation is a drawer on extra-large windows', (tester) async {
    await pumpAt(tester, 1600);
    expect(find.byType(ExpandedScreenDrawer), findsOneWidget);
    expect(find.byType(MediumScreenRail), findsNothing);
  });

  testWidgets('Menu button expands the rail on a large window', (tester) async {
    await pumpAt(tester, 1200);
    await tester.tap(find.byIcon(Icons.menu_open_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(ExpandedScreenDrawer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
