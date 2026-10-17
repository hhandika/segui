import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/home/components/illustration.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/styles/decoration.dart';

/// A feature diagram from the website, recolored with the active theme.
///
/// The SVGs in `assets/images/features/` are exported by
/// `scripts/illustrations/export_feature_diagrams.py`.
class FeatureDiagram extends StatelessWidget {
  const FeatureDiagram({
    super.key,
    required this.asset,
    this.semanticsLabel,
  });

  final String asset;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SvgPicture(
      SvgAssetLoader(
        asset,
        colorMapper: FeatureDiagramColors(
          text: colors.onSurface,
          muted: colors.onSurfaceVariant,
          accent: colors.primary,
          accentContainer: colors.primaryContainer,
          panel: colors.surfaceContainerLowest,
          outline: colors.outlineVariant,
          gap: colors.outline,
        ),
      ),
      fit: BoxFit.contain,
      semanticsLabel: semanticsLabel,
    );
  }
}

/// Swaps the placeholder colors of the exported feature diagrams for theme
/// colors. Keep the keys in sync with the export script.
class FeatureDiagramColors extends ColorMapper {
  const FeatureDiagramColors({
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentContainer,
    required this.panel,
    required this.outline,
    required this.gap,
  });

  static const Color textKey = Color(0xFF010203);
  static const Color mutedKey = Color(0xFF040506);
  static const Color accentKey = Color(0xFF070809);
  static const Color accentContainerKey = Color(0xFF0A0B0C);
  static const Color panelKey = Color(0xFF0D0E0F);
  static const Color outlineKey = Color(0xFF101112);
  static const Color gapKey = Color(0xFF131415);

  final Color text;
  final Color muted;
  final Color accent;
  final Color accentContainer;
  final Color panel;
  final Color outline;
  final Color gap;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    // Compare without alpha so translucent fills keep their opacity.
    final Color opaque = color.withAlpha(0xFF);
    final Color? swapped = switch (opaque) {
      textKey => text,
      mutedKey => muted,
      accentKey => accent,
      accentContainerKey => accentContainer,
      panelKey => panel,
      outlineKey => outline,
      gapKey => gap,
      _ => null,
    };
    if (swapped == null) {
      return color;
    }
    return swapped.withValues(alpha: color.a * swapped.a);
  }

  @override
  bool operator ==(Object other) {
    return other is FeatureDiagramColors &&
        other.text == text &&
        other.muted == muted &&
        other.accent == accent &&
        other.accentContainer == accentContainer &&
        other.panel == panel &&
        other.outline == outline &&
        other.gap == gap;
  }

  @override
  int get hashCode =>
      Object.hash(text, muted, accent, accentContainer, panel, outline, gap);
}

/// The gull scene for the open tool, drawn along the bottom of the page.
///
/// Uses the low-contrast colors of the home illustration so it stays in the
/// background. Draws nothing on pages without a tool.
class ToolScene extends ConsumerWidget {
  const ToolScene({super.key});

  /// Aspect ratio of the scene view box.
  static const double aspectRatio = 1200 / 160;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeTool? tool = ref.watch(currentToolProvider);
    if (tool == null) {
      return const SizedBox.shrink();
    }
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: largeScreenSize),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: ShaderMask(
              // Fade both ends into the page, like the home illustration.
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0x00000000),
                  Color(0xFF000000),
                  Color(0xFF000000),
                  Color(0x00000000),
                ],
                stops: [0, 0.06, 0.94, 1],
              ).createShader(bounds),
              child: SvgPicture(
                SvgAssetLoader(
                  tool.sceneAsset,
                  colorMapper: HomeIllustrationColors(
                    line: colors.outlineVariant,
                    accent: colors.tertiaryContainer,
                    fill: colors.surface,
                  ),
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
