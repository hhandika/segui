import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/home/components/illustration.dart';
import 'package:segui/services/utils.dart';

/// The SEGUL gull greeting scene for [time].
///
/// Plays once when shown: the sun rises or the moon and stars fade in, the
/// gull glides onto its post, and it flaps twice. Tapping the gull replays the
/// flap. With reduced motion the scene shows its final pose and stays still.
class GreetingIllustration extends StatefulWidget {
  const GreetingIllustration({super.key, required this.time, this.size = 56});

  static const Duration duration = Duration(milliseconds: 1400);

  /// Point in the entrance where the gull has landed and starts flapping.
  static const double flapStart = 0.6;

  /// Side of the square view box every greeting layer shares.
  static const double viewBox = 96;

  final GreetingTime time;
  final double size;

  @override
  State<GreetingIllustration> createState() => _GreetingIllustrationState();
}

class _GreetingIllustrationState extends State<GreetingIllustration>
    with SingleTickerProviderStateMixin {
  // View box points the animation pivots around.
  static const Offset _wingShoulder = Offset(62, 50);
  static const Offset _afternoonSun = Offset(24, 24);
  static const double _horizon = 70;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: GreetingIllustration.duration,
  );
  bool _reduceMotion = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.value = 1;
    } else if (!_started) {
      _controller.forward();
    }
    _started = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ColorMapper mapper = HomeIllustrationColors(
      line: colors.onSurface,
      // Container tones go muddy in dark mode, so the sun stays bright there.
      accent: colors.brightness == Brightness.dark
          ? colors.tertiary
          : colors.tertiaryContainer,
      fill: colors.surface,
    );
    final GreetingTime time = widget.time;
    // Built once per build so animation frames reuse the same widgets.
    final Widget sky = GreetingLayer(asset: time.skyAsset, colorMapper: mapper);
    final Widget? stars = time.starsAsset == null
        ? null
        : GreetingLayer(asset: time.starsAsset!, colorMapper: mapper);
    final Widget scene =
        GreetingLayer(asset: time.sceneAsset, colorMapper: mapper);
    final Widget post =
        GreetingLayer(asset: GreetingTime.postAsset, colorMapper: mapper);
    final Widget body =
        GreetingLayer(asset: GreetingTime.gullBodyAsset, colorMapper: mapper);
    final Widget wing =
        GreetingLayer(asset: GreetingTime.gullWingAsset, colorMapper: mapper);

    return ExcludeSemantics(
      child: MouseRegion(
        cursor: _reduceMotion ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _flap,
          child: SizedBox.square(
            dimension: widget.size,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double v = _controller.value;
                final double unit = widget.size / GreetingIllustration.viewBox;
                final double skyIn = _ease(v, 0, 0.5);
                final double gullIn =
                    _ease(v, 0, GreetingIllustration.flapStart);
                // A small dip as the gull's weight lands on the post.
                final double dip = v > 0.55 && v < 0.75
                    ? math.sin(math.pi * (v - 0.55) / 0.2) * 2.5
                    : 0;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    switch (time) {
                      GreetingTime.morning => ClipRect(
                          clipper: const GreetingHorizonClipper(
                            _horizon / GreetingIllustration.viewBox,
                          ),
                          child: Transform.translate(
                            offset: Offset(0, (1 - skyIn) * 24 * unit),
                            child: sky,
                          ),
                        ),
                      GreetingTime.afternoon => Opacity(
                          opacity: skyIn,
                          child: Transform.scale(
                            scale: 0.5 + 0.5 * skyIn,
                            alignment: _fraction(_afternoonSun),
                            child: sky,
                          ),
                        ),
                      GreetingTime.evening => Opacity(
                          opacity: skyIn,
                          child: sky,
                        ),
                    },
                    if (stars != null)
                      Opacity(opacity: _ease(v, 0.25, 0.75), child: stars),
                    scene,
                    post,
                    Opacity(
                      opacity: _ease(v, 0, 0.25),
                      child: Transform.translate(
                        offset: Offset(
                          -36 * (1 - gullIn) * unit,
                          (-28 * (1 - gullIn) + dip) * unit,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            body,
                            Transform.rotate(
                              angle: _wingAngle(v),
                              alignment: _fraction(_wingShoulder),
                              child: wing,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Replays the flap once the gull has landed.
  void _flap() {
    if (_reduceMotion || _controller.value < GreetingIllustration.flapStart) {
      return;
    }
    _controller.forward(from: GreetingIllustration.flapStart);
  }

  /// Eased progress of [v] through the [begin]-[end] part of the entrance.
  double _ease(double v, double begin, double end) {
    return Interval(begin, end, curve: Curves.easeOutCubic).transform(v);
  }

  /// Wing rotation in radians; positive raises the wing tip.
  double _wingAngle(double v) {
    const double flapStart = GreetingIllustration.flapStart;
    if (v < flapStart) {
      // Flapping in flight, settling as the gull lands.
      final double u = v / flapStart;
      return 0.7 * math.sin(3 * math.pi * u).abs() * (1 - u);
    }
    // Two full flaps after landing.
    final double t = (v - flapStart) / (1 - flapStart);
    return 0.6 * math.sin(2 * math.pi * t).abs();
  }

  FractionalOffset _fraction(Offset point) {
    return FractionalOffset(
      point.dx / GreetingIllustration.viewBox,
      point.dy / GreetingIllustration.viewBox,
    );
  }
}

/// One themed SVG layer of the greeting scene.
class GreetingLayer extends StatelessWidget {
  const GreetingLayer({
    super.key,
    required this.asset,
    required this.colorMapper,
  });

  final String asset;
  final ColorMapper colorMapper;

  @override
  Widget build(BuildContext context) {
    return SvgPicture(
      SvgAssetLoader(asset, colorMapper: colorMapper),
      fit: BoxFit.contain,
    );
  }
}

/// Clips to the part of the scene above the horizon, so the morning sun
/// rises from behind it.
class GreetingHorizonClipper extends CustomClipper<Rect> {
  const GreetingHorizonClipper(this.horizonFraction);

  /// Horizon height as a fraction of the scene height.
  final double horizonFraction;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, size.height * horizonFraction);
  }

  @override
  bool shouldReclip(GreetingHorizonClipper oldClipper) {
    return oldClipper.horizonFraction != horizonFraction;
  }
}
