import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/themes.dart';

/// WCAG 2.2 contrast ratio between two opaque colors.
double contrastRatio(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// WCAG AA minimum for body text (1.4.3).
const double textContrast = 4.5;

/// WCAG AA minimum for icons and other graphics (1.4.11).
const double graphicContrast = 3;

void main() {
  for (final theme in [SeguiTheme.lightTheme(), SeguiTheme.darkTheme()]) {
    final ColorScheme c = theme.colorScheme;
    final String mode = c.brightness.name;

    void expectContrast(String name, Color fg, Color bg, double minimum) {
      final double ratio = contrastRatio(fg, bg);
      expect(
        ratio,
        greaterThanOrEqualTo(minimum),
        reason: '$mode $name is ${ratio.toStringAsFixed(2)}:1, '
            'needs $minimum:1',
      );
    }

    test('$mode color roles meet WCAG AA text contrast', () {
      final Map<String, (Color, Color)> pairs = {
        'onPrimary/primary': (c.onPrimary, c.primary),
        'onPrimaryContainer/primaryContainer': (
          c.onPrimaryContainer,
          c.primaryContainer
        ),
        'onSecondary/secondary': (c.onSecondary, c.secondary),
        'onSecondaryContainer/secondaryContainer': (
          c.onSecondaryContainer,
          c.secondaryContainer
        ),
        'onTertiary/tertiary': (c.onTertiary, c.tertiary),
        'onTertiaryContainer/tertiaryContainer': (
          c.onTertiaryContainer,
          c.tertiaryContainer
        ),
        'onError/error': (c.onError, c.error),
        'onErrorContainer/errorContainer': (
          c.onErrorContainer,
          c.errorContainer
        ),
        'primary/surface': (c.primary, c.surface),
        'secondary/surface': (c.secondary, c.surface),
        'tertiary/surface': (c.tertiary, c.surface),
        'error/surface': (c.error, c.surface),
      };
      for (final surface in {
        'surface': c.surface,
        'surfaceContainerLow': c.surfaceContainerLow,
        'surfaceContainer': c.surfaceContainer,
        'surfaceContainerHigh': c.surfaceContainerHigh,
        'surfaceContainerHighest': c.surfaceContainerHighest,
      }.entries) {
        pairs['onSurface/${surface.key}'] = (c.onSurface, surface.value);
        pairs['onSurfaceVariant/${surface.key}'] =
            (c.onSurfaceVariant, surface.value);
      }
      pairs.forEach((name, pair) {
        expectContrast(name, pair.$1, pair.$2, textContrast);
      });
    });

    test('$mode outline meets WCAG AA graphic contrast', () {
      expectContrast('outline/surface', c.outline, c.surface, graphicContrast);
    });

    testWidgets('$mode SEGUI decorations meet WCAG AA', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Builder(builder: (ctx) {
          context = ctx;
          return const SizedBox();
        }),
      ));

      final Color background = getSEGULBackgroundColor(context)!;
      expectContrast(
          'onSurface/app background', c.onSurface, background, textContrast);
      expectContrast('onSurfaceVariant/app background', c.onSurfaceVariant,
          background, textContrast);

      // Selected navigation items sit on the translucent indicator.
      final Color indicator =
          Color.alphaBlend(getIndicatorColor(context), background);
      expectContrast('onSecondaryContainer/navigation indicator',
          c.onSecondaryContainer, indicator, textContrast);
      expectContrast('onSurface/navigation indicator', c.onSurface, indicator,
          textContrast);

      // CommonCard tints its background 10% toward primary or tertiary.
      for (final tint
          in {'primary': c.primary, 'tertiary': c.tertiary}.entries) {
        final Color card = Color.lerp(tint.value, c.surface, 0.9)!;
        expectContrast(
            'onSurface/${tint.key} card', c.onSurface, card, textContrast);
      }

      for (final surface in {
        'surface': c.surface,
        'app background': background,
      }.entries) {
        final Color icon =
            Color.alphaBlend(getIconColor(context), surface.value);
        expectContrast(
            'icon color/${surface.key}', icon, surface.value, graphicContrast);
      }
    });
  }
}
