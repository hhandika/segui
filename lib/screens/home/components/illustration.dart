import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/decoration.dart';

const String homeIllustrationAsset = 'assets/images/home_field_sketch.svg';

/// Decorative field sketch with the SEGUL gull, recolored from the theme.
///
/// Drawn in low-contrast outline and container tones so it stays in the
/// background and does not compete with the tools above it.
class HomeIllustration extends StatelessWidget {
  const HomeIllustration({super.key});

  /// Aspect ratio of the SVG view box.
  static const double _aspectRatio = 1200 / 196;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    // Scale with the width so the whole sketch always shows, up to a cap
    // that keeps it short on wide monitors. Faded ends blend the centered
    // sketch into the empty space beside it.
    return ExcludeSemantics(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: largeScreenSize),
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: ShaderMask(
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
                  homeIllustrationAsset,
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

/// Swaps the illustration's placeholder colors for theme colors.
class HomeIllustrationColors extends ColorMapper {
  const HomeIllustrationColors({
    required this.line,
    required this.accent,
    required this.fill,
  });

  static const Color lineKey = Color(0xFF005224);
  static const Color accentKey = Color(0xFFFFD64F);
  static const Color fillKey = Color(0xFFFFFFFF);

  final Color line;
  final Color accent;
  final Color fill;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color == lineKey) return line;
    if (color == accentKey) return accent;
    if (color == fillKey) return fill;
    return color;
  }

  @override
  bool operator ==(Object other) {
    return other is HomeIllustrationColors &&
        other.line == line &&
        other.accent == accent &&
        other.fill == fill;
  }

  @override
  int get hashCode => Object.hash(line, accent, fill);
}
