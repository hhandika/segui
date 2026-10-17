import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/home/components/illustration.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

/// Shows [AboutSheet] as a dialog on larger screens and a bottom sheet on
/// phones.
Future<void> showAppAbout(
  BuildContext context, {
  Future<SegulVersion> Function() loadVersion = AboutSheet.segulVersion,
}) {
  return showResponsiveSheet<void>(
    context: context,
    builder: (context) => AboutSheet(loadVersion: loadVersion),
  );
}

class AboutButton extends StatelessWidget {
  const AboutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => showAppAbout(context),
      child: Text(
        'About',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

/// App name, authors, versions, and links, under the waving gull.
class AboutSheet extends StatefulWidget {
  const AboutSheet({super.key, this.loadVersion = AboutSheet.segulVersion});

  /// Reads the app and SEGUL API versions; replaced in tests.
  final Future<SegulVersion> Function() loadVersion;

  static Future<SegulVersion> segulVersion() async {
    final SegulVersion version = SegulVersion.empty();
    await version.getVersions();
    return version;
  }

  @override
  State<AboutSheet> createState() => _AboutSheetState();
}

class _AboutSheetState extends State<AboutSheet> {
  late final Future<SegulVersion> _version = widget.loadVersion();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isCompact = isPhoneScreen(context);
    return FutureBuilder<SegulVersion>(
      future: _version,
      builder: (context, snapshot) {
        final SegulVersion? version = snapshot.data;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            SeguiSpacing.xxl,
            isCompact ? 0 : SeguiSpacing.xxl,
            SeguiSpacing.xxl,
            SeguiSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const AboutBanner(),
                      const SizedBox(height: SeguiSpacing.xl),
                      Text('SEGUI', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: SeguiSpacing.xs),
                      Text(
                        'A GUI version of the SEGUL genomic tool',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Heru Handika & Jacob A. Esselstyn',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: SeguiSpacing.xl),
                      AboutVersions(version: version),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SeguiSpacing.xl),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: SeguiSpacing.md,
                runSpacing: SeguiSpacing.md,
                children: [
                  TextButton(
                    onPressed: launchSegulDocUrl,
                    child: const Text('Documentation'),
                  ),
                  TextButton(
                    onPressed: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'SEGUI',
                        applicationVersion: version?.version,
                      );
                    },
                    child: const Text('Licenses'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The waving gull on a tinted panel.
class AboutBanner extends StatelessWidget {
  const AboutBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: getSEGULBackgroundColor(context),
        borderRadius: BorderRadius.circular(SeguiRadius.xl),
      ),
      child: const Padding(
        padding: EdgeInsets.all(SeguiSpacing.xl),
        child: Center(child: AboutGull()),
      ),
    );
  }
}

/// The SEGUL gull waving from a sequence alignment, drawn in theme colors.
class AboutGull extends StatelessWidget {
  const AboutGull({super.key});

  static const String asset = 'assets/images/about_gull.svg';

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture(
        SvgAssetLoader(
          asset,
          colorMapper: HomeIllustrationColors.scene(
            Theme.of(context).colorScheme,
          ),
        ),
        height: SeguiControlSize.aboutArt,
      ),
    );
  }
}

/// App version, build number, and SEGUL API version side by side. Shows a
/// dash for each while loading or when a version cannot be read.
class AboutVersions extends StatelessWidget {
  const AboutVersions({super.key, required this.version});

  final SegulVersion? version;

  @override
  Widget build(BuildContext context) {
    final SegulVersion? version = this.version;
    return OutlinedPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: SeguiSpacing.md,
        vertical: SeguiSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: AboutVersionItem(
              label: 'App version',
              value: version == null ? null : 'v${version.version}',
            ),
          ),
          Expanded(
            child: AboutVersionItem(
              label: 'Build',
              value: version?.buildNumber,
            ),
          ),
          Expanded(
            child: AboutVersionItem(
              label: 'SEGUL API',
              value: version == null ? null : 'v${version.apiVersion}',
            ),
          ),
        ],
      ),
    );
  }
}

class AboutVersionItem extends StatelessWidget {
  const AboutVersionItem({super.key, required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value ?? '—',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
