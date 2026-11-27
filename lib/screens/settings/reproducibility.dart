import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/settings/settings_layout.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

class ReproducibilitySettings extends StatelessWidget {
  const ReproducibilitySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reproducibility'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: const SafeArea(child: ReproducibilitySettingsView()),
    );
  }
}

/// Reproducibility settings: SHA-256 report checksums for verification.
class ReproducibilitySettingsView extends ConsumerWidget {
  const ReproducibilitySettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChecksumModeSetting mode = ref.watch(checksumModeProvider);
    final ThemeData theme = Theme.of(context);
    final bool isPhone = isPhoneScreen(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SeguiContentWidth.form),
        child: ListView(
          padding: EdgeInsets.all(
            isPhone ? SeguiPageMargin.compact : SeguiPageMargin.regular,
          ),
          children: [
            if (!isPhone) ...[
              const SettingsPageHeader(
                title: 'Reproducibility',
                detail: 'Verification metadata recorded in run reports.',
              ),
              const SizedBox(height: SeguiSpacing.xl),
            ],
            FormCard(
              children: [
                Text(
                  'Report checksums',
                  style: theme.textTheme.titleSmall,
                ),
                SegmentedButton<ChecksumModeSetting>(
                  showSelectedIcon: false,
                  segments: [
                    for (final option in ChecksumModeSetting.values)
                      ButtonSegment<ChecksumModeSetting>(
                        value: option,
                        label: Text(option.label),
                      ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (selection) {
                    ref
                        .read(checksumModeProvider.notifier)
                        .setMode(selection.first);
                  },
                ),
                Text(
                  mode.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
