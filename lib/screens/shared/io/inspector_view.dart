import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/summary_view.dart';
import 'package:segui/screens/shared/io/workbench_view.dart';
import 'package:segui/screens/viewers/common.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/providers/inspector.dart';
import 'package:segui/services/viewers/inspector.dart';
import 'package:segui/services/workbench.dart';
import 'package:segui/styles/design_tokens.dart';

/// Picks an input or output file and shows what it holds, such as its
/// sequence and site counts, with a button to open it in its viewer.
class FileInspectorCard extends ConsumerWidget {
  const FileInspectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InspectorSource source = ref.watch(inspectorSourceProvider);
    final List<File> files = ref.watch(inspectorFilesProvider(source));
    final File? selected = ref.watch(inspectedFileProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return WorkbenchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PanelCardHeader(
            icon: Icons.manage_search_outlined,
            title: 'Inspector',
          ),
          SegmentedButton<InspectorSource>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              for (final value in InspectorSource.values)
                ButtonSegment(value: value, label: Text(value.label)),
            ],
            selected: {source},
            onSelectionChanged: (value) {
              ref.read(inspectorSourceProvider.notifier).show(value.first);
            },
          ),
          const SizedBox(height: SeguiSpacing.md),
          if (files.isEmpty)
            Text(
              source == InspectorSource.input
                  ? 'No input files to inspect.'
                  : 'No new output files to inspect.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            )
          else ...[
            InspectorFileButton(file: selected, files: files),
            if (selected != null) ...[
              const SizedBox(height: SeguiSpacing.md),
              FileInspectionDetails(file: selected, siblings: files),
            ],
            if (files.any(isAlignmentViewable)) ...[
              const SizedBox(height: SeguiSpacing.md),
              ViewAllSequencesButton(files: files),
            ],
          ],
        ],
      ),
    );
  }
}

/// Opens the alignment viewer on every sequence file in [files], so the
/// viewer can switch between them.
class ViewAllSequencesButton extends ConsumerWidget {
  const ViewAllSequencesButton({super.key, required this.files});

  final List<File> files;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _open(context, ref),
      icon: const Icon(Icons.view_list_outlined),
      label: const Text('View all sequences'),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool isOpened = await openAllSequences(
      context,
      files,
      order: ref.read(fileOrderProvider),
    );
    if (!isOpened && context.mounted) {
      messenger.showSnackBar(
        showSharedSnackBar(context, 'No sequence files to view.'),
      );
    }
  }
}

/// Shows the inspected file, or a prompt, and opens the file list.
class InspectorFileButton extends ConsumerWidget {
  const InspectorFileButton({
    super.key,
    required this.file,
    required this.files,
  });

  final File? file;
  final List<File> files;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final File? current = file;
    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(SeguiRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _choose(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: SeguiSpacing.lg, vertical: SeguiSpacing.md),
          child: Row(
            children: [
              if (current == null)
                Icon(
                  Icons.description_outlined,
                  size: SeguiControlSize.iconMedium,
                  color: colors.onSurfaceVariant,
                )
              else
                FormatIcon(file: current),
              const SizedBox(width: SeguiSpacing.md),
              Expanded(
                child: Text(
                  current == null
                      ? 'Choose a file (${files.length})'
                      : p.basename(current.path),
                  style: textTheme.bodyMedium?.copyWith(
                    color: current == null ? colors.onSurfaceVariant : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                size: SeguiControlSize.iconMedium,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final InspectedFile inspected = ref.read(inspectedFileProvider.notifier);
    final File? picked = await showResponsiveSheet<File>(
      context: context,
      builder: (context) => InspectorFileSheet(files: files, selected: file),
    );
    if (picked != null) {
      inspected.select(picked);
    }
  }
}

/// Searchable list of files to inspect.
class InspectorFileSheet extends StatefulWidget {
  const InspectorFileSheet({
    super.key,
    required this.files,
    required this.selected,
  });

  final List<File> files;
  final File? selected;

  @override
  State<InspectorFileSheet> createState() => _InspectorFileSheetState();
}

class _InspectorFileSheetState extends State<InspectorFileSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final String needle = _query.trim().toLowerCase();
    final List<File> matches = [
      for (final file in widget.files)
        if (p.basename(file.path).toLowerCase().contains(needle)) file,
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: SeguiContentWidth.dialog),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            SeguiSpacing.xl, SeguiSpacing.xl, SeguiSpacing.xl, SeguiSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Inspect a file',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: SeguiSpacing.lg),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search files',
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: SeguiSpacing.md),
            Flexible(
              child: matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(SeguiSpacing.xl),
                      child: Text(
                        'No files match.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final File file = matches[index];
                        return ListTile(
                          dense: true,
                          leading: FormatIcon(file: file),
                          title: Text(
                            p.basename(file.path),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            p.basename(p.dirname(file.path)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: file.path == widget.selected?.path,
                          onTap: () => Navigator.of(context).pop(file),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Format icon of [file], matched by its extension.
class FormatIcon extends StatelessWidget {
  const FormatIcon({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      FileIconType.fromFileName(p.basename(file.path)).assetPath,
      width: SeguiControlSize.iconMedium,
      height: SeguiControlSize.iconMedium,
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.tertiary,
        BlendMode.srcIn,
      ),
    );
  }
}

/// Kind, size, and content counts of [file], with a button to open it.
class FileInspectionDetails extends ConsumerWidget {
  const FileInspectionDetails({
    super.key,
    required this.file,
    required this.siblings,
  });

  final File file;

  /// Files listed with [file], which the viewer can switch between.
  final List<File> siblings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle? muted = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: colors.onSurfaceVariant);
    return ref.watch(fileInspectionProvider(file.path)).when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: SeguiSpacing.md),
            child: LinearProgressIndicator(),
          ),
          error: (error, _) =>
              Text('Could not inspect the file.', style: muted),
          data: (inspection) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final detail in inspection.details)
                RunParameterRow(
                  parameter: RunParameter(detail.label, detail.value),
                ),
              if (inspection.note != null) ...[
                const SizedBox(height: SeguiSpacing.sm),
                Text(inspection.note!, style: muted),
              ],
              if (inspection.kind != FileContentKind.other) ...[
                const SizedBox(height: SeguiSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: () =>
                        openFileView(context, file, siblings: siblings),
                    icon: const Icon(Icons.open_in_full_rounded),
                    label: const Text('Open'),
                  ),
                ),
              ],
            ],
          ),
        );
  }
}
