import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/file_list.dart';
import 'package:segui/screens/viewers/alignment/selected_row_mark.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/keyboard.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/viewers/alignment_files.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

/// File switcher above the viewer toolbar. Steps through the files with
/// arrows, or picks one from a searchable list.
class AlignmentFileSwitcher extends StatelessWidget {
  const AlignmentFileSwitcher({
    super.key,
    required this.files,
    required this.index,
    required this.onSelected,
  });

  final AlignmentFileList files;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final File file = files.files[index];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous file (${PlatformKeys.altLabel} + ↑)',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
          onPressed: () => onSelected(files.step(index, -1)),
        ),
        Flexible(
          child: SearchAnchor(
            viewHintText: 'Filter ${files.length} files',
            isFullScreen: isPhoneScreen(context),
            viewBackgroundColor: theme.colorScheme.surface,
            viewConstraints: const BoxConstraints(
              minWidth: SeguiContentWidth.searchViewMin,
              maxWidth: SeguiContentWidth.dialog,
              maxHeight: SeguiControlSize.searchViewMax,
            ),
            builder: (context, controller) => TextButton(
              onPressed: controller.openView,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CostumFileIcon(
                    file: file,
                    iconColor: getIconColor(context),
                    iconSize: SeguiControlSize.iconMedium,
                  ),
                  const SizedBox(width: SeguiSpacing.sm),
                  Flexible(
                    // The name keeps most of the room when space is short.
                    flex: 3,
                    child: Text(
                      p.basename(file.path),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  // Phones keep the room for the name.
                  if (!isPhoneScreen(context)) ...[
                    const SizedBox(width: SeguiSpacing.sm),
                    // Gives way to the name when space runs short.
                    Flexible(
                      child: Text(
                        '${index + 1} of ${files.length}',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: theme.textTheme.labelMedium!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  const Icon(Icons.arrow_drop_down_rounded),
                ],
              ),
            ),
            suggestionsBuilder: (context, controller) {
              final List<int> matches = files.view(query: controller.text);
              if (matches.isEmpty) {
                return const [
                  ListTile(title: Text('No files match.')),
                ];
              }
              return [
                for (final int i in matches)
                  _FileTile(
                    file: files.files[i],
                    isSelected: i == index,
                    onTap: () {
                      controller.closeView(null);
                      onSelected(i);
                    },
                  ),
              ];
            },
          ),
        ),
        IconButton(
          tooltip: 'Next file (${PlatformKeys.altLabel} + ↓)',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => onSelected(files.step(index, 1)),
        ),
      ],
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.file,
    required this.isSelected,
    required this.onTap,
    this.size,
  });

  final File file;
  final bool isSelected;
  final VoidCallback onTap;

  /// Shown under the name when known, in bytes.
  final int? size;

  @override
  Widget build(BuildContext context) {
    final int? size = this.size;
    final String folder = p.basename(p.dirname(file.path));
    // Inset row marked on its left when selected; content stays
    // SeguiSpacing.lg from the panel edge.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SeguiSpacing.sm,
        vertical: SeguiSpacing.xxs,
      ),
      child: SelectedRowMark(
        isSelected: isSelected,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SeguiRadius.md),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: SeguiSpacing.sm,
          ),
          leading: FileIconTile(icon: FileIcon(file: file)),
          title: Text(p.basename(file.path), overflow: TextOverflow.ellipsis),
          subtitle: Text(
            size == null ? folder : '$folder · ${FileUtils().formatSize(size)}',
            overflow: TextOverflow.ellipsis,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Every file the viewer can switch to, with a filter, a sort order, and
/// arrows that step through the files as listed.
class AlignmentFileRail extends ConsumerStatefulWidget {
  const AlignmentFileRail({
    super.key,
    required this.files,
    required this.index,
    required this.onSelected,
  });

  final AlignmentFileList files;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  ConsumerState<AlignmentFileRail> createState() => _AlignmentFileRailState();
}

class _AlignmentFileRailState extends ConsumerState<AlignmentFileRail> {
  final TextEditingController _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AlignmentViewSettings settings =
        ref.watch(alignmentViewSettingsProvider);
    final AlignmentFileSort sort = settings.fileSort;
    final Map<String, int> sizes =
        ref.watch(alignmentFileSizesProvider(widget.files)).value ?? const {};
    final List<int> view = widget.files.view(
      query: _query.text,
      sort: sort,
      ascending: settings.fileSortAscending,
      sizes: sizes,
    );
    final int largest = sizes.values.fold(0, (a, b) => a > b ? a : b);
    final int position = view.indexOf(widget.index);
    return SizedBox(
      width: SeguiAlignmentLayout.fileList,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(SeguiSpacing.lg),
            child: FormFieldTheme(
              child: TextField(
                controller: _query,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Filter files',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: SeguiControlSize.iconSmall,
                  ),
                  suffixIcon: _FileSortButton(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.lg),
            child: Text(
              '${view.length} of ${widget.files.length} files',
              style: theme.textTheme.labelSmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: SeguiSpacing.xs),
          Expanded(
            child: ListView.builder(
              itemCount: view.length,
              itemBuilder: (context, i) {
                final File file = widget.files.files[view[i]];
                final int? size = sizes[file.path];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FileTile(
                      file: file,
                      size: size,
                      isSelected: view[i] == widget.index,
                      onTap: () => widget.onSelected(view[i]),
                    ),
                    if (size != null && largest > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SeguiSpacing.lg,
                        ),
                        child: LinearProgressIndicator(
                          value: size / largest,
                          minHeight: SeguiStroke.regular,
                          color: theme.colorScheme.primary,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          semanticsLabel: 'Relative file size',
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: SeguiStroke.thin),
          // Icon buttons carry their own padding, which with this inset
          // lines their icons up with the content above.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.xs),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous file in list',
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  onPressed: view.isEmpty ? null : () => _step(view, -1),
                ),
                Expanded(
                  child: Text(
                    position < 0
                        ? 'Not in list'
                        : '${position + 1} of ${view.length}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Next file in list',
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onPressed: view.isEmpty ? null : () => _step(view, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Steps through the filtered, sorted list, starting at its first file
  // when the open file is filtered out.
  void _step(List<int> view, int delta) {
    final int position = view.indexOf(widget.index);
    final int next = position < 0
        ? (delta > 0 ? 0 : view.length - 1)
        : (position + delta) % view.length;
    widget.onSelected(view[next]);
  }
}

/// Sort order and direction of the file list, inside the filter field.
/// Opens a menu on larger screens and a bottom sheet on phones.
class _FileSortButton extends ConsumerWidget {
  const _FileSortButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Phones skip the menu entirely, so no overlay lingers in the sheet.
    if (isPhoneScreen(context)) {
      return IconButton(
        tooltip: 'Sort files',
        icon: const Icon(Icons.sort_rounded),
        visualDensity: VisualDensity.compact,
        onPressed: () => showResponsiveSheet<void>(
          context: context,
          builder: (context) => SheetContent(
            title: 'Sort files',
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
            child: const _FileSortChoices(),
          ),
        ),
      );
    }
    final AlignmentViewSettings settings =
        ref.watch(alignmentViewSettingsProvider);
    final AlignmentViewSettingsNotifier notifier =
        ref.read(alignmentViewSettingsProvider.notifier);
    final AlignmentFileSort sort = settings.fileSort;
    return MenuAnchor(
      menuChildren: [
        for (final AlignmentFileSort option in AlignmentFileSort.values)
          MenuItemButton(
            leadingIcon: _Check(isOn: option == sort),
            onPressed: () => notifier.setFileSort(option),
            child: Text('Sort by ${option.label.toLowerCase()}'),
          ),
        const Divider(height: SeguiStroke.thin),
        for (final bool ascending in const [true, false])
          MenuItemButton(
            leadingIcon: _Check(isOn: ascending == settings.fileSortAscending),
            onPressed: () => notifier.setFileSortAscending(ascending),
            child: Text(ascending ? sort.ascending : sort.descending),
          ),
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: 'Sort files',
        icon: const Icon(Icons.sort_rounded),
        visualDensity: VisualDensity.compact,
        onPressed: controller.isOpen ? controller.close : controller.open,
      ),
    );
  }
}

/// Sort and direction choices for the phone sheet. Choices apply right
/// away, so the sheet can stay open while both are set.
class _FileSortChoices extends ConsumerWidget {
  const _FileSortChoices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AlignmentViewSettings settings =
        ref.watch(alignmentViewSettingsProvider);
    final AlignmentViewSettingsNotifier notifier =
        ref.read(alignmentViewSettingsProvider.notifier);
    final AlignmentFileSort sort = settings.fileSort;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final AlignmentFileSort option in AlignmentFileSort.values)
          ListTile(
            title: Text('Sort by ${option.label.toLowerCase()}'),
            trailing: _Check(isOn: option == sort),
            onTap: () => notifier.setFileSort(option),
          ),
        const Divider(),
        for (final bool ascending in const [true, false])
          ListTile(
            title: Text(ascending ? sort.ascending : sort.descending),
            trailing: _Check(isOn: ascending == settings.fileSortAscending),
            onTap: () => notifier.setFileSortAscending(ascending),
          ),
      ],
    );
  }
}

/// A check mark that keeps its space when off, so labels stay aligned.
class _Check extends StatelessWidget {
  const _Check({required this.isOn});

  final bool isOn;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.check_rounded,
      color: isOn ? null : Colors.transparent,
      semanticLabel: isOn ? 'Selected' : null,
    );
  }
}

/// Keyboard hint under the file list, styled like the status line under
/// the grid so the two read as one line.
class AlignmentFileHint extends StatelessWidget {
  const AlignmentFileHint({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SeguiSpacing.lg,
        SeguiSpacing.xs,
        SeguiSpacing.lg,
        0,
      ),
      child: Text(
        '${PlatformKeys.altLabel} + ↑ / ↓ to switch files',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
