import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/drop.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/segui_icons.dart';

class SelectDirField extends ConsumerWidget {
  const SelectDirField({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(fileOutputProvider).when(
        data: (data) {
          return FileDropTarget(
            onDropped: (items) => _addDropped(context, ref, items),
            builder: (context, isDragging, _) {
              if (data.directory == null) {
                return PickerDropZone(
                  compact: true,
                  icon: SeguiIcons.outputFolderOutlined,
                  title: label,
                  hint: isFileDropSupported
                      ? 'Drop a folder here, or browse.'
                      : 'Choose where to save the results.',
                  isDragging: isDragging,
                  actions: [
                    PickerAction(
                      label: 'Choose folder',
                      icon: Icons.folder_open_outlined,
                      onSelected: () =>
                          DirectorySelectionServices(ref).addOutputDir(),
                    ),
                  ],
                );
              }
              return PickerSelectionCard(
                icon: SeguiIcons.outputFolderFilled,
                title: PathTextWithOverflow(path: data.directory!.path),
                subtitle: isFileDropSupported
                    ? 'Drop a folder to change it'
                    : 'Output directory',
                isDragging: isDragging,
                sheetTitle: 'Output directory',
                actions: [
                  PickerAction(
                    label: 'Change folder',
                    icon: Icons.folder_open_outlined,
                    onSelected: () =>
                        DirectorySelectionServices(ref).addOutputDir(),
                  ),
                  PickerAction(
                    label: 'Clear folder',
                    icon: Icons.clear_rounded,
                    isDestructive: true,
                    onSelected: () => ref.invalidate(fileOutputProvider),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (err, stack) {
          return Column(
            children: [
              Text(
                err.toString(),
              ),
              IconButton(
                tooltip: 'Retry',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(fileOutputProvider);
                },
              ),
            ],
          );
        });
  }

  Future<void> _addDropped(
    BuildContext context,
    WidgetRef ref,
    List<DropItem> items,
  ) async {
    final List<String> paths = await openDroppedItems(items);
    final bool isAdded =
        DirectorySelectionServices(ref).addDroppedOutputDir(paths);
    if (!isAdded && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        showSharedSnackBar(context, 'Drop a folder to save the results in.'),
      );
    }
  }
}

class SharedFilePicker extends ConsumerStatefulWidget {
  const SharedFilePicker({
    super.key,
    required this.label,
    required this.allowMultiple,
    required this.xTypeGroup,
    required this.hasSecondaryPicker,
    required this.task,
    required this.allowDirectorySelection,
  });

  final String label;
  final bool allowMultiple;
  final XTypeGroup xTypeGroup;
  final bool hasSecondaryPicker;
  final SupportedTask task;
  final bool allowDirectorySelection;

  @override
  SharedFilePickerState createState() => SharedFilePickerState();
}

class SharedFilePickerState extends ConsumerState<SharedFilePicker> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final type = matchTypeByXTypeGroup(widget.xTypeGroup);
    return ref.watch(fileInputProvider).when(
          data: (data) {
            final files = data.where((e) => e.type == type).toList();
            return FileDropTarget(
              onDropped: (items) => _addDropped(items, files),
              builder: (context, isDragging, _) {
                if (files.isEmpty) {
                  return PickerDropZone(
                    compact: !widget.allowMultiple,
                    icon: Icons.upload_file_outlined,
                    title: widget.label,
                    hint: _dropHint,
                    isDragging: isDragging,
                    isLoading: _isLoading,
                    actions: _emptyActions,
                  );
                }
                return PickerSelectionCard(
                  // One tool reads several formats, so the tool icon
                  // stands for the selected files.
                  icon: ref.watch(currentToolProvider)?.filledIcon ??
                      Icons.file_present_outlined,
                  title: Text(
                    _selectionLabel(files),
                    style: Theme.of(context).textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: _selectedHint,
                  isDragging: isDragging,
                  isLoading: _isLoading,
                  sheetTitle: _selectionLabel(files),
                  actions: _selectedActions(files),
                );
              },
            );
          },
          loading: () => const SharedProgressIndicator(),
          error: (err, stack) => Text(err.toString()),
        );
  }

  bool get _canSelectDirectory {
    return widget.allowDirectorySelection && isFileDropSupported;
  }

  String get _dropHint {
    if (!isFileDropSupported) {
      return '${widget.xTypeGroup.label} files';
    }
    if (!widget.allowMultiple) {
      return 'Drop a file here, or browse.';
    }
    return _canSelectDirectory
        ? 'Drop files or a folder here, or browse.'
        : 'Drop files here, or browse.';
  }

  String get _selectedHint {
    if (!isFileDropSupported) {
      return '${widget.xTypeGroup.label} files';
    }
    return widget.allowMultiple
        ? 'Drop more files to add them'
        : 'Drop a file to replace it';
  }

  List<PickerAction> get _emptyActions {
    return [
      PickerAction(
        label: widget.allowMultiple ? 'Browse files' : 'Browse file',
        icon: Icons.note_add_outlined,
        onSelected: () => _addFiles(isDir: false),
      ),
      if (_canSelectDirectory)
        PickerAction(
          label: 'Browse folder',
          icon: Icons.create_new_folder_outlined,
          onSelected: () => _addFiles(isDir: true),
        ),
    ];
  }

  List<PickerAction> _selectedActions(List<SegulInputFile> files) {
    final type = matchTypeByXTypeGroup(widget.xTypeGroup);
    final notifier = ref.read(fileInputProvider.notifier);
    if (!widget.allowMultiple) {
      return [
        PickerAction(
          label: 'Choose another file',
          icon: Icons.swap_horiz_rounded,
          onSelected: _replaceFile,
        ),
        PickerAction(
          label: 'Remove file',
          icon: Icons.clear_rounded,
          isDestructive: true,
          onSelected: () => notifier.removeType(type),
        ),
      ];
    }
    return [
      PickerAction(
        label: 'Add files',
        icon: Icons.note_add_outlined,
        onSelected: () => _addMoreFiles(files, isDir: false),
      ),
      if (_canSelectDirectory)
        PickerAction(
          label: 'Add folder',
          icon: Icons.create_new_folder_outlined,
          onSelected: () => _addMoreFiles(files, isDir: true),
        ),
      PickerAction(
        label: 'Clear files',
        icon: Icons.clear_rounded,
        isDestructive: true,
        onSelected: () => notifier.removeType(type),
      ),
    ];
  }

  Future<void> _addFiles({required bool isDir}) async {
    if (widget.hasSecondaryPicker) {
      // A new selection would also clear the files of other pickers.
      await _addMoreFiles(const [], isDir: isDir);
      return;
    }
    _startLoading();
    try {
      final selection = _getFileSelection();
      if (isDir) {
        await selection.addDirectory();
      } else {
        await selection.selectFiles();
      }
    } catch (e) {
      _showError(e.toString());
    }

    _stopLoading();
  }

  Future<void> _addMoreFiles(List<SegulInputFile> currentFiles,
      {required bool isDir}) async {
    _startLoading();
    final selection = _getFileSelection();
    final files = currentFiles.map((e) => e.file).toList();
    try {
      int duplicates = 0;
      if (isDir) {
        duplicates = await selection.addMoreDirectory(files);
      } else {
        duplicates = await selection.addMoreFiles(files);
      }
      _showDuplicates(duplicates);
    } catch (e) {
      _showError(e.toString());
    }
    _stopLoading();
  }

  Future<void> _replaceFile() async {
    _startLoading();
    try {
      await _getFileSelection().replaceFile();
    } catch (e) {
      _showError(e.toString());
    }
    _stopLoading();
  }

  Future<void> _addDropped(
    List<DropItem> items,
    List<SegulInputFile> currentFiles,
  ) async {
    _startLoading();
    try {
      final List<String> paths = await openDroppedItems(items);
      final result = await _getFileSelection().addDropped(
        paths,
        currentFiles: currentFiles.map((e) => e.file).toList(),
        allowDirectory: widget.allowDirectorySelection,
      );
      if (result.skipped > 0) {
        _showError('Skipping ${result.skipped} unsupported '
            'item${result.skipped > 1 ? 's' : ''}.');
      } else {
        _showDuplicates(result.duplicates);
      }
    } catch (e) {
      _showError(e.toString());
    }
    _stopLoading();
  }

  FileInputServices _getFileSelection() {
    final selection = FileInputServices(
      ref,
      allowedExtension: widget.xTypeGroup,
      allowMultiple: widget.allowMultiple,
    );
    return selection;
  }

  String _selectionLabel(List<SegulInputFile> files) {
    if (!widget.allowMultiple) {
      return p.basename(files.first.file.path);
    }
    return files.length == 1
        ? '1 file selected'
        : '${files.length} files selected';
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void _showDuplicates(int duplicates) {
    if (duplicates > 0) {
      _showError(
          'Skipping $duplicates duplicate file${duplicates > 1 ? 's' : ''}. 🙈');
    }
  }

  void _showError(String error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      showSharedSnackBar(context, error),
    );
  }

  void _stopLoading() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
  }
}

/// An action offered by a file picker, as a button or a bottom sheet item.
@immutable
class PickerAction {
  const PickerAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool isDestructive;
}

/// Accepts files dragged from the system file manager on desktop.
///
/// Passes whether files are dragging over the target to [builder].
class FileDropTarget extends StatefulWidget {
  const FileDropTarget({
    super.key,
    required this.onDropped,
    required this.builder,
  });

  final ValueChanged<List<DropItem>> onDropped;
  final ValueWidgetBuilder<bool> builder;

  @override
  State<FileDropTarget> createState() => _FileDropTargetState();
}

class _FileDropTargetState extends State<FileDropTarget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    // Matches the vertical padding of the form fields.
    final Widget child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: widget.builder(context, _isDragging, null),
    );
    if (!isFileDropSupported) {
      return child;
    }
    return DropTarget(
      // Hidden targets still get drops, so only the visible route's
      // targets listen.
      enable: TickerMode.valuesOf(context).enabled &&
          (ModalRoute.isCurrentOf(context) ?? true),
      onDragEntered: (_) => _setDragging(true),
      onDragExited: (_) => _setDragging(false),
      onDragDone: (details) {
        _setDragging(false);
        widget.onDropped(details.files);
      },
      child: child,
    );
  }

  void _setDragging(bool isDragging) {
    if (mounted && _isDragging != isDragging) {
      setState(() {
        _isDragging = isDragging;
      });
    }
  }
}

/// Dashed area that asks for files before any are selected.
///
/// Shows every action as a button on wide screens. On phones, and when
/// [compact], tapping the area runs the action, or opens a bottom sheet
/// when there are several.
class PickerDropZone extends StatelessWidget {
  const PickerDropZone({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.actions,
    this.compact = false,
    this.isDragging = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String hint;
  final List<PickerAction> actions;
  final bool compact;
  final bool isDragging;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isCompact = compact || isPhoneScreen(context);
    return CustomPaint(
      foregroundPainter: DashedBorderPainter(
        color: isDragging ? colors.primary : colors.outline,
        strokeWidth: isDragging ? 2 : 1,
      ),
      child: Material(
        color: isDragging
            ? colors.primaryContainer.withValues(alpha: 0.4)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(pickerRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : () => _onTap(context),
          child: isCompact
              ? PickerDropZoneRow(
                  icon: icon,
                  title: isDragging ? 'Release to add' : title,
                  hint: hint,
                  isLoading: isLoading,
                  onBrowse: () => _onTap(context),
                )
              : PickerDropZoneColumn(
                  icon: icon,
                  title: isDragging ? 'Release to add' : title,
                  hint: hint,
                  isLoading: isLoading,
                  actions: actions,
                ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    if (actions.length == 1) {
      actions.first.onSelected();
      return;
    }
    PickerActionSheet.show(context, title: title, actions: actions);
  }
}

/// Wide drop zone content with a button for each action.
class PickerDropZoneColumn extends StatelessWidget {
  const PickerDropZoneColumn({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.isLoading,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool isLoading;
  final List<PickerAction> actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (int i, PickerAction action) in actions.indexed)
                  i == 0
                      ? FilledButton.tonalIcon(
                          onPressed: action.onSelected,
                          icon: Icon(action.icon),
                          label: Text(action.label),
                        )
                      : OutlinedButton.icon(
                          onPressed: action.onSelected,
                          icon: Icon(action.icon),
                          label: Text(action.label),
                        ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Single-line drop zone content for phones and secondary pickers.
class PickerDropZoneRow extends StatelessWidget {
  const PickerDropZoneRow({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.isLoading,
    required this.onBrowse,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool isLoading;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: PickerText(title: Text(title), subtitle: hint),
          ),
          const SizedBox(width: 8),
          isLoading
              ? const PickerProgress()
              : FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onBrowse,
                  child: const Text('Browse'),
                ),
        ],
      ),
    );
  }
}

/// Summary of the selected files with an edit button that opens the
/// picker actions in a bottom sheet.
class PickerSelectionCard extends StatelessWidget {
  const PickerSelectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.sheetTitle,
    required this.actions,
    this.isDragging = false,
    this.isLoading = false,
  });

  final IconData icon;
  final Widget title;
  final String subtitle;
  final String sheetTitle;
  final List<PickerAction> actions;
  final bool isDragging;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: isDragging
          ? colors.primaryContainer.withValues(alpha: 0.4)
          : colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pickerRadius),
        side: BorderSide(
          color: isDragging ? colors.primary : colors.outlineVariant,
          width: isDragging ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: PickerText(
                title: title,
                subtitle: isDragging ? 'Release to add' : subtitle,
              ),
            ),
            const SizedBox(width: 8),
            isLoading
                ? const PickerProgress()
                : TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => PickerActionSheet.show(
                      context,
                      title: sheetTitle,
                      actions: actions,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
          ],
        ),
      ),
    );
  }
}

/// Title over a muted subtitle in a picker row.
class PickerText extends StatelessWidget {
  const PickerText({super.key, required this.title, required this.subtitle});

  final Widget title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle.merge(
          style: theme.textTheme.labelLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: title,
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Progress indicator sized to sit in place of a picker button.
class PickerProgress extends StatelessWidget {
  const PickerProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// Bottom sheet listing the actions of a file picker.
class PickerActionSheet extends StatelessWidget {
  const PickerActionSheet({
    super.key,
    required this.title,
    required this.actions,
  });

  final String title;
  final List<PickerAction> actions;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<PickerAction> actions,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      barrierLabel: title,
      builder: (context) => PickerActionSheet(title: title, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                title,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final PickerAction action in actions)
              PickerActionTile(action: action),
          ],
        ),
      ),
    );
  }
}

class PickerActionTile extends StatelessWidget {
  const PickerActionTile({super.key, required this.action});

  final PickerAction action;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color? color = action.isDestructive ? colors.error : null;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pickerRadius),
      ),
      leading: Icon(action.icon, color: color),
      title: Text(action.label, style: TextStyle(color: color)),
      onTap: () {
        Navigator.of(context).pop();
        action.onSelected();
      },
    );
  }
}

/// Corner radius of picker zones and cards, matching the form fields.
const double pickerRadius = 12;

/// Paints a dashed rounded border around a drop zone.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.dashLength = 6,
    this.gapLength = 4,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final RRect rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      const Radius.circular(pickerRadius),
    );
    final Path border = Path()..addRRect(rect);
    for (final ui.PathMetric metric in border.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashLength),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}
