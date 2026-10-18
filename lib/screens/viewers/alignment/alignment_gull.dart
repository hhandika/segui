import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/home/components/illustration.dart';
import 'package:segui/styles/design_tokens.dart';

/// Shared view box of the gull layers, in SVG units.
const double _viewLeft = 0;
const double _viewTop = 28;
const double _viewWidth = 122;
const double _viewHeight = 38;

/// The panel edge the gull stands on, and the feet it leans from.
const double _edgeY = 64;
const double _pivotX = 91;

/// Tile rest position by the beak and its slot in the top row.
const double _tileTravel = -11;

/// Lean of the gull while nudging, in radians. Negative tips the head
/// forward, toward the rows.
const double _lean = -6 * math.pi / 180;

const Duration _cycle = Duration(milliseconds: 3600);

/// The SEGUL gull at work above the alignment viewer toolbar, nudging a
/// residue tile into the empty slot of a small alignment. Stands still when
/// the platform asks to reduce motion.
class AlignmentGull extends StatefulWidget {
  const AlignmentGull({super.key});

  static const String gullAsset = 'assets/images/alignment_gull.svg';
  static const String rowsAsset = 'assets/images/alignment_gull_rows.svg';
  static const String tileAsset = 'assets/images/alignment_gull_tile.svg';

  /// Height of the art above the panel edge, which the panel below should
  /// leave free so the gull's feet meet its top border.
  static double get standingHeight =>
      SeguiAlignmentLayout.mascot * (_edgeY - _viewTop) / _viewHeight;

  @override
  State<AlignmentGull> createState() => _AlignmentGullState();
}

class _AlignmentGullState extends State<AlignmentGull>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _cycle);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0;
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HomeIllustrationColors colors =
        HomeIllustrationColors.scene(Theme.of(context).colorScheme);
    const double height = SeguiAlignmentLayout.mascot;
    const double width = height * _viewWidth / _viewHeight;
    const double scale = height / _viewHeight;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final _GullPose pose = _GullPose.at(_controller.value);
            return Stack(
              fit: StackFit.expand,
              children: [
                _GullLayer(asset: AlignmentGull.rowsAsset, colors: colors),
                Transform.translate(
                  offset: Offset(_tileTravel * pose.tile * scale, 0),
                  child: Opacity(
                    opacity: pose.tileOpacity,
                    child: _GullLayer(
                      asset: AlignmentGull.tileAsset,
                      colors: colors,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _lean * pose.lean,
                  alignment: const Alignment(
                    (_pivotX - _viewLeft) / _viewWidth * 2 - 1,
                    (_edgeY - _viewTop) / _viewHeight * 2 - 1,
                  ),
                  child: _GullLayer(
                    asset: AlignmentGull.gullAsset,
                    colors: colors,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GullLayer extends StatelessWidget {
  const _GullLayer({required this.asset, required this.colors});

  final String asset;
  final HomeIllustrationColors colors;

  @override
  Widget build(BuildContext context) {
    return SvgPicture(SvgAssetLoader(asset, colorMapper: colors));
  }
}

/// Lean, tile travel, and tile opacity over one nudge cycle: rest, lean in
/// and slide the tile into its slot, lean back, then the tile fades and a
/// new one appears by the beak.
class _GullPose {
  const _GullPose(this.lean, this.tile, this.tileOpacity);

  factory _GullPose.at(double t) {
    final double push = _phase(t, 0.15, 0.35);
    final double back = _phase(t, 0.5, 0.65);
    final double fadeOut = _phase(t, 0.68, 0.8);
    final double fadeIn = _phase(t, 0.82, 0.92);
    final bool isReset = t >= 0.82;
    return _GullPose(
      push - back,
      isReset ? 0 : push,
      isReset ? fadeIn : 1 - fadeOut,
    );
  }

  /// 0 to 1 eased across [start, end].
  static double _phase(double t, double start, double end) {
    return Curves.easeInOut.transform(
      ((t - start) / (end - start)).clamp(0.0, 1.0),
    );
  }

  final double lean;
  final double tile;
  final double tileOpacity;
}
