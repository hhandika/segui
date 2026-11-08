import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/home/more_page.dart';
import 'package:segui/screens/settings/themes.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/providers/viewer.dart';
import 'package:segui/services/viewers/viewer_files.dart';
import 'package:segui/styles/themes.dart';
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

  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: const Scaffold(body: MorePage()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('More shows shortcuts, quick settings, and settings pages',
      (tester) async {
    await pump(tester);
    for (final String title in ['Viewer', 'Colors', 'Logs', 'Guide']) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Open files to view'), findsOneWidget);
    expect(find.byType(ReduceMotionTile), findsOneWidget);
    expect(find.text('Data usage'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    // Colors sits next to Viewer in the first row.
    expect(
      tester.getTopLeft(find.text('Colors')).dy,
      tester.getTopLeft(find.text('Viewer')).dy,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('The viewer shortcut counts recent files', (tester) async {
    container
        .read(viewerRecentsProvider.notifier)
        .record(const ViewerRecent(path: 'a.fas', isFolder: false));
    await pump(tester);
    expect(find.text('1 recent'), findsOneWidget);
  });

  testWidgets('Theme changes in place', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(container.read(themeSettingProvider).value, ThemeMode.dark);
  });

  testWidgets('Reduce motion switches in place', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Reduce motion'));
    await tester.pumpAndSettle();
    expect(container.read(reduceMotionProvider), isTrue);
  });
}
