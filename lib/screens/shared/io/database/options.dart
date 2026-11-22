import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/database/search_fields.dart';
import 'package:segui/services/databases/types.dart';
import 'package:segui/services/providers/databases.dart';
import 'package:segui/styles/design_tokens.dart';

/// How the selected sequences are cut, named, and split into files.
class DatabaseDownloadOptions extends ConsumerWidget {
  const DatabaseDownloadOptions({
    super.key,
    required this.target,
    required this.input,
    required this.allowMultiple,
  });

  final DatabaseTarget target;
  final DatabaseSearchInput input;

  /// Whether the picker takes more than one file.
  final bool allowMultiple;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DatabaseState state = ref.watch(databaseSessionProvider(target));
    final DatabaseSession session =
        ref.read(databaseSessionProvider(target).notifier);
    final DownloadOptions options = state.options;
    final bool isSingle = options.grouping == SequenceGrouping.singleFile;
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.xs),
      childrenPadding: const EdgeInsets.only(bottom: SeguiSpacing.md),
      shape: const Border(),
      title: const Text('Download options'),
      subtitle: Text([
        options.grouping.label,
        options.naming.label,
        if (state.content == DownloadContent.coding && options.gene.isNotEmpty)
          options.gene,
      ].join(' · ')),
      children: [
        FormCard(
          children: [
            if (state.content == DownloadContent.coding)
              TextFormField(
                // Starts from the gene of the last search.
                key: ValueKey(state.page),
                initialValue: options.gene,
                decoration: const InputDecoration(
                  labelText: 'Keep only gene',
                  hintText: 'CYTB',
                  helperText: 'Leave empty to keep every coding sequence.',
                ),
                onChanged: (value) =>
                    session.setOptions(options.copyWith(gene: value)),
              ),
            if (allowMultiple)
              SharedMapDropdownField(
                label: 'Files',
                value: options.grouping.name,
                items: {
                  for (final item in SequenceGrouping.values)
                    item.name: item.label,
                },
                onChanged: (name) {
                  if (name != null) {
                    session.setOptions(options.copyWith(
                      grouping: SequenceGrouping.values.byName(name),
                    ));
                  }
                },
              ),
            if (isSingle)
              TextField(
                controller: input.fileName,
                decoration: const InputDecoration(
                  labelText: 'File name',
                  hintText: 'sequences',
                ),
                onChanged: (value) =>
                    session.setOptions(options.copyWith(fileName: value)),
              ),
            SharedMapDropdownField(
              label: 'Sequence names',
              value: options.naming.name,
              items: {
                for (final item in SequenceNaming.values) item.name: item.label,
              },
              onChanged: (name) {
                if (name != null) {
                  session.setOptions(options.copyWith(
                    naming: SequenceNaming.values.byName(name),
                  ));
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
