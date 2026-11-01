import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/settings/colors.dart';
import 'package:segui/services/colors.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_contrast_test.dart' show contrastRatio;

/// Stands in for the Rust color library, which widget tests do not load.
class FakeColorLibrary extends ColorLibraryServices {
  const FakeColorLibrary();

  static const PaletteChoice okabeIto = PaletteChoice(
    name: 'okabe-ito',
    label: 'Okabe-Ito',
    colorblindSafe: 8,
    fills: ChartPalette.series,
    lines: ChartPalette.series,
  );

  static const PaletteChoice set1 = PaletteChoice(
    name: 'set1',
    label: 'ColorBrewer Set1',
    colorblindSafe: 0,
    fills: [Color(0xFFE41A1C), Color(0xFFFFFF33)],
    lines: [Color(0xFFE41A1C), Color(0xFF8A8A1B)],
  );

  @override
  SeguiColors load({
    required ColorPreferences settings,
    required Brightness brightness,
    required Color surface,
  }) {
    final SeguiColors colors = SeguiColors.fallback(brightness);
    return settings.palette == set1.name
        ? colors.copyWith(series: set1.fills, seriesLines: set1.lines)
        : colors;
  }

  @override
  ColorChoices choices({
    required Brightness brightness,
    required Color surface,
  }) {
    return ColorChoices(
      palettes: const [okabeIto, set1],
      colormaps: const [
        ColormapChoice(
          name: 'viridis',
          label: 'Viridis',
          isDiverging: false,
          stops: [Color(0xFF440154), Color(0xFFFDE725)],
        ),
      ],
      residueSchemes: ColorChoices.fallback(brightness).residueSchemes,
      cvdKinds: const [('deuteranopia', 'Deuteranopia')],
    );
  }

  @override
  SeguiColors simulateAll(SeguiColors colors, String cvd) => colors;

  @override
  ContrastSummary summarize(SeguiColors colors, ColorScheme scheme) {
    return const ContrastSummary(text: 6.3, lines: 3.1);
  }
}

void main() {
  for (final ThemeData theme in [
    SeguiTheme.lightTheme(),
    SeguiTheme.darkTheme(),
  ]) {
    final ColorScheme c = theme.colorScheme;
    final String mode = c.brightness.name;
    final SeguiColors colors = SeguiColors.fallback(c.brightness);

    void expectContrast(String name, Color fg, Color bg, double minimum) {
      final double ratio = contrastRatio(fg, bg);
      expect(
        ratio,
        greaterThanOrEqualTo(minimum),
        reason: '$mode $name is ${ratio.toStringAsFixed(2)}:1, '
            'needs $minimum:1',
      );
    }

    test('$mode residue letters meet WCAG AA', () {
      for (final ResiduePalette p in [colors.nucleotide, colors.aminoAcid]) {
        for (final Color cell in {...p.colors.values, p.fallback, p.gap}) {
          expectContrast('letter on $cell', p.onResidue, cell, textContrast);
        }
      }
      expectContrast(
        'identity letter',
        c.onSurfaceVariant,
        c.surfaceContainer,
        textContrast,
      );
    });

    test('$mode table numbers over data bars meet WCAG AA', () {
      for (final Color bar in [c.primary, ...ChartPalette.series]) {
        final Color cell = Color.alphaBlend(
          bar.withValues(alpha: SeguiTableLayout.dataBarAlpha),
          c.surface,
        );
        expectContrast('number over $bar', c.onSurface, cell, textContrast);
      }
    });

    test('$mode chart tooltips and base lines meet WCAG', () {
      expectContrast(
        'tooltip',
        c.onInverseSurface,
        c.inverseSurface,
        textContrast,
      );
      for (final Color line in colors.nucleotideLines.colors.values) {
        expectContrast('base line $line', line, c.surface, nonTextContrast);
      }
    });
  }

  test('Line colors and heatmap stops come from the library colors', () {
    final SeguiColors colors = SeguiColors.fallback(Brightness.light).copyWith(
      series: const [Color(0xFFF0E442)],
      seriesLines: const [Color(0xFF8A8226)],
      heatmap: const [Color(0xFF000000), Color(0xFFFFFFFF)],
    );
    expect(colors.lineFor(const Color(0xFFF0E442)), const Color(0xFF8A8226));
    expect(colors.lineFor(const Color(0xFF123456)), const Color(0xFF123456));
    expect(colors.heatmapAt(0), const Color(0xFF000000));
    expect(colors.heatmapAt(2), const Color(0xFFFFFFFF));
    expect(SeguiColors.fallback(Brightness.light).heatmapAt(0.5), isNull);
  });

  test('Color settings are saved', () async {
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(colorSettingsProvider), const ColorPreferences());
    await container.read(chartPaletteProvider.notifier).set('dark2');
    await container.read(heatmapColormapProvider.notifier).set('magma');
    await container
        .read(tableBarColorProvider.notifier)
        .set(TableBarColor.palette);
    await container
        .read(alignmentColorModeProvider.notifier)
        .set(AlignmentColorMode.mono);
    expect(prefs.getString('chartPalette'), 'dark2');
    expect(prefs.getString('heatmapColormap'), 'magma');
    expect(prefs.getString('tableBarColor'), 'palette');
    expect(prefs.getString('alignmentColorMode'), 'mono');
    expect(
      container.read(colorSettingsProvider),
      const ColorPreferences(
        palette: 'dark2',
        colormap: 'magma',
        tableBar: TableBarColor.palette,
      ),
    );
  });

  testWidgets('Color settings pick from previews and show contrast',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        settingProvider.overrideWithValue(prefs),
        colorLibraryProvider.overrideWithValue(const FakeColorLibrary()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: SeguiTheme.lightTheme(
              colors: ref.watch(seguiColorsProvider(Brightness.light)),
            ),
            home: const Scaffold(body: ColorSettingView()),
          ),
        ),
      ),
    );

    expect(find.text('Okabe-Ito'), findsOneWidget);
    expect(find.text('Not colorblind safe'), findsOneWidget);
    expect(find.text('1 adjusted for lines'), findsOneWidget);
    expect(find.text('Viridis'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Text contrast 6.3')), findsOneWidget);

    await tester.tap(find.text('ColorBrewer Set1'));
    await tester.pumpAndSettle();
    expect(container.read(chartPaletteProvider), 'set1');
    final BuildContext context = tester.element(find.byType(ColorSettingView));
    expect(SeguiColors.of(context).seriesAt(1), const Color(0xFFFFFF33));
    expect(SeguiColors.of(context).lineAt(1), const Color(0xFF8A8A1B));

    await tester.tap(find.text('Mono'));
    await tester.pumpAndSettle();
    expect(container.read(alignmentColorModeProvider), AlignmentColorMode.mono);
  });
}
