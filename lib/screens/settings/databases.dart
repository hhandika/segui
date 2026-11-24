import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/settings/settings_layout.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

class DatabaseSettings extends StatelessWidget {
  const DatabaseSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Databases'),
        backgroundColor: getSEGULBackgroundColor(context),
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: const SafeArea(child: DatabaseSettingsView()),
    );
  }
}

/// Settings for sequence database searches and downloads.
class DatabaseSettingsView extends ConsumerStatefulWidget {
  const DatabaseSettingsView({super.key});

  @override
  ConsumerState<DatabaseSettingsView> createState() =>
      _DatabaseSettingsViewState();
}

class _DatabaseSettingsViewState extends ConsumerState<DatabaseSettingsView> {
  static final Uri _ncbiKeyUri =
      Uri.parse('https://account.ncbi.nlm.nih.gov/settings/');

  late final TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(ncbiApiKeyProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String savedKey = ref.watch(ncbiApiKeyProvider);
    final DownloadConcurrency concurrency =
        ref.watch(downloadConcurrencyProvider);
    final bool hasSaved = savedKey.isNotEmpty;
    final bool hasInput = _controller.text.trim().isNotEmpty;
    final bool isDirty = _controller.text.trim() != savedKey;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SeguiSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: SeguiContentWidth.form),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsPageHeader(
                title: 'Databases',
                detail: 'Settings for GenBank and ENA.',
              ),
              const SizedBox(height: SeguiSpacing.xl),
              FormCard(
                children: [
                  TextField(
                    controller: _controller,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: 'NCBI API key',
                      helperText:
                          'Optional. Raises GenBank limit from 3 to 10 requests '
                          'per second.',
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show key' : 'Hide key',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (hasSaved)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: SeguiControlSize.iconSmall,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: SeguiSpacing.xs),
                        Text(
                          'Saved on this device',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  Wrap(
                    spacing: SeguiSpacing.md,
                    runSpacing: SeguiSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.tonal(
                        onPressed: isDirty ? _save : null,
                        child: const Text('Save'),
                      ),
                      if (hasSaved || hasInput)
                        TextButton(
                          onPressed: _clear,
                          child: const Text('Clear'),
                        ),
                      TextButton.icon(
                        onPressed: _openNcbiSettings,
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Get an NCBI API key'),
                      ),
                    ],
                  ),
                  Text(
                    'Stored only on this device and sent only to NCBI.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SeguiSpacing.lg),
              FormCard(
                children: [
                  Text(
                    'Concurrent downloads',
                    style: theme.textTheme.titleSmall,
                  ),
                  SegmentedButton<DownloadConcurrency>(
                    segments: const [
                      ButtonSegment(
                        value: DownloadConcurrency.auto,
                        label: Text('Auto'),
                      ),
                      ButtonSegment(
                        value: DownloadConcurrency.conservative,
                        label: Text('Conservative'),
                      ),
                      ButtonSegment(
                        value: DownloadConcurrency.single,
                        label: Text('Single'),
                      ),
                    ],
                    selected: {concurrency},
                    onSelectionChanged: (selected) {
                      ref
                          .read(downloadConcurrencyProvider.notifier)
                          .set(selected.first);
                    },
                  ),
                  Text(
                    switch (concurrency) {
                      DownloadConcurrency.auto =>
                        'Uses the fastest safe limit for each archive and '
                            'slows down automatically if busy.',
                      DownloadConcurrency.conservative =>
                        'Uses fewer parallel connections for slower or shared '
                            'networks.',
                      DownloadConcurrency.single =>
                        'Downloads one file or batch at a time.',
                    },
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    await ref.read(ncbiApiKeyProvider.notifier).set(_controller.text);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      showSharedSnackBar(
        context,
        _controller.text.trim().isEmpty
            ? 'NCBI API key cleared'
            : 'NCBI API key saved',
      ),
    );
  }

  Future<void> _clear() async {
    _controller.clear();
    await ref.read(ncbiApiKeyProvider.notifier).clear();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      showSharedSnackBar(context, 'NCBI API key cleared'),
    );
  }

  Future<void> _openNcbiSettings() async {
    await launchUrl(_ncbiKeyUri, mode: LaunchMode.externalApplication);
  }
}
