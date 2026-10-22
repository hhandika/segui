import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/settings/about.dart';
import 'package:segui/screens/settings/themes.dart';
import 'package:segui/screens/shared/motion.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  void setWindowSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  test('About art is bundled', () {
    // Asset keys always use POSIX separators.
    final List<String> parts = p.posix.split(AboutGull.asset);
    expect(File(p.joinAll(parts)).existsSync(), isTrue);
  });

  for (final (name, size, isCompact) in [
    ('phone', const Size(360, 1400), true),
    ('desktop', const Size(1000, 900), false),
  ]) {
    testWidgets('Theme choices fit and save on $name', (tester) async {
      setWindowSize(tester, size);
      final ProviderContainer container = ProviderContainer(
        overrides: [settingProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: SeguiTheme.lightTheme(),
          home: const ThemeSettings(),
        ),
      ));
      await tester.pumpAndSettle();

      final Iterable<ThemeChoiceCard> cards =
          tester.widgetList(find.byType(ThemeChoiceCard));
      expect(cards.length, ThemeChoice.values.length);
      expect(cards.every((card) => card.isCompact == isCompact), isTrue);
      expect(
        cards.singleWhere((card) => card.isSelected).choice,
        ThemeChoice.system,
      );

      await tester.tap(find.text(ThemeChoice.dark.title));
      await tester.pumpAndSettle();
      expect(container.read(themeSettingProvider).value, ThemeMode.dark);
      expect(preferences.getString('themeMode'), 'dark');
      expect(
        tester
            .widgetList<ThemeChoiceCard>(find.byType(ThemeChoiceCard))
            .singleWhere((card) => card.isSelected)
            .choice,
        ThemeChoice.dark,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final (name, size, isSheet) in [
    ('phone', const Size(360, 800), true),
    ('desktop', const Size(1000, 800), false),
  ]) {
    for (final theme in [SeguiTheme.lightTheme(), SeguiTheme.darkTheme()]) {
      testWidgets(
          'About opens as a ${isSheet ? 'bottom sheet' : 'dialog'} on $name '
          'in ${theme.brightness.name} mode', (tester) async {
        setWindowSize(tester, size);
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppAbout(
                  context,
                  loadVersion: () async => SegulVersion(
                    name: 'segui',
                    version: '1.2.3',
                    buildNumber: '45',
                    apiVersion: '0.9.0',
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(AboutGull), findsOneWidget);
        expect(
            find.byType(BottomSheet), isSheet ? findsOneWidget : findsNothing);
        expect(find.byType(Dialog), isSheet ? findsNothing : findsOneWidget);
        expect(find.text('v1.2.3'), findsOneWidget);
        expect(find.text('45'), findsOneWidget);
        expect(find.text('v0.9.0'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(AboutSheet), findsNothing);
      });
    }
  }

  testWidgets('About shows dashes when versions cannot be read',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AboutSheet(loadVersion: () => Future.error(StateError('none'))),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('—'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduce motion saves and turns off animations', (tester) async {
    setWindowSize(tester, const Size(1000, 1400));
    final ProviderContainer container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    bool? disabled;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        builder: (context, child) => ReduceMotionScope(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              const Expanded(child: ThemeSettingView()),
              Builder(builder: (context) {
                disabled = MediaQuery.disableAnimationsOf(context);
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    ));
    expect(disabled, isFalse);
    await tester.scrollUntilVisible(find.text('Reduce motion'), 200);
    await tester.tap(find.text('Reduce motion'));
    await tester.pumpAndSettle();
    expect(disabled, isTrue);
    expect(preferences.getBool('reduceMotion'), isTrue);
    expect(container.read(reduceMotionProvider), isTrue);
  });

  testWidgets('Reduce motion follows the device setting', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    setWindowSize(tester, const Size(1000, 1400));
    await tester.pumpWidget(ProviderScope(
      overrides: [settingProvider.overrideWithValue(preferences)],
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: const Scaffold(body: ThemeSettingView()),
      ),
    ));
    await tester.scrollUntilVisible(find.text('Reduce motion'), 200);
    final SwitchListTile tile = tester.widget(find.byType(SwitchListTile));
    expect(tile.value, isTrue);
    expect(tile.onChanged, isNull);
    expect(find.textContaining('Your device reduces motion'), findsOneWidget);
  });
}
