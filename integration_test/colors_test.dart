// Checks the color settings against the SEGUL color library. Run on a
// native target:
//
//   flutter test integration_test/colors_test.dart -d linux
//
// Pass --dart-define=SCREENSHOT_DIR=<folder> to save captures of the page.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/settings/colors.dart';
import 'package:segui/services/colors.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/src/rust/frb_generated.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _outputDir = String.fromEnvironment('SCREENSHOT_DIR');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => RustLib.init());

  for (final Brightness brightness in Brightness.values) {
    testWidgets('Color settings use the SEGUL library (${brightness.name})',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(1280, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ProviderContainer container = ProviderContainer(
        overrides: [settingProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final GlobalKey boundary = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final SeguiColors colors =
                  ref.watch(seguiColorsProvider(brightness));
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: brightness == Brightness.light
                    ? SeguiTheme.lightTheme(colors: colors)
                    : SeguiTheme.darkTheme(colors: colors),
                home: RepaintBoundary(
                  key: boundary,
                  child: const ColorSettings(),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ColorChoices choices =
          container.read(colorChoicesProvider(brightness));
      expect(choices.palettes.length, 7);
      expect(choices.colormaps.length, 12);
      expect(choices.residueSchemes.length, 2);
      expect(choices.palettes.first.name, defaultChartPalette);
      expect(choices.palettes.first.fills.first, const Color(0xFF1B9E77));
      expect(find.text('ColorBrewer Dark2'), findsOneWidget);
      expect(find.text('Viridis'), findsOneWidget);

      final BuildContext context =
          tester.element(find.byType(ColorSettingView));
      final ThemeData theme = Theme.of(context);
      final ContrastSummary contrast = container
          .read(colorLibraryProvider)
          .summarize(SeguiColors.of(context), theme.colorScheme);
      expect(contrast.text, greaterThanOrEqualTo(textContrast));
      expect(contrast.lines, greaterThanOrEqualTo(nonTextContrast));

      await _capture(boundary, 'colors-${brightness.name}');

      await tester.tap(find.text('Okabe-Ito'));
      await tester.pumpAndSettle();
      expect(prefs.getString('chartPalette'), 'okabe-ito');
      expect(
        SeguiColors.of(tester.element(find.byType(ColorSettingView)))
            .seriesAt(0),
        const Color(0xFF0072B2),
      );
    });
  }
}

Future<void> _capture(GlobalKey key, String name) async {
  if (_outputDir.isEmpty) return;
  final RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ui.Image image = await boundary.toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final File file = File(p.join(_outputDir, '$name.png'));
  await file.writeAsBytes(data!.buffer.asUint8List());
  // ignore: avoid_print
  print('Saved ${file.path}');
}
