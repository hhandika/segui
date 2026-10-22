import 'dart:io';
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/providers/io.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/io/archive_input.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/drop.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/io/mobile_io.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/segui_icons.dart';
import 'package:segui/styles/design_tokens.dart';

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

/// Where a file picker gets its files.
enum InputSource { files, folder, archive, seguiFolder, shared }

class SharedFilePickerState extends ConsumerState<SharedFilePicker> {
  bool _isLoading = false;
  InputCopyProgress? _progress;

  @override
  Widget build(BuildContext context) {
    final type = matchTypeByXTypeGroup(widget.xTypeGroup);
    final int sharedCount = ref.watch(sharedInputProvider);
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
                    hint: _progressLabel ?? _dropHint(sharedCount),
                    isDragging: isDragging,
                    isLoading: _isLoading,
                    progress: _progress?.fraction,
                    onCancel: _cancelAction,
                    actions: _emptyActions(sharedCount),
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
                  subtitle: _progressLabel ?? _selectedHint(sharedCount),
                  isDragging: isDragging,
                  isLoading: _isLoading,
                  progress: _progress?.fraction,
                  onCancel: _cancelAction,
                  sheetTitle: _selectionLabel(files),
                  actions: _selectedActions(files, sharedCount),
                );
              },
            );
          },
          loading: () => const SharedProgressIndicator(),
          error: (err, stack) => Text(err.toString()),
        );
  }

  bool get _canSelectDirectory => widget.allowDirectorySelection;

  /// Archives hold many files, so they serve pickers that take many
  /// files. Raw reads stay gzipped and are added as regular files.
  bool get _canSelectArchive {
    return widget.allowMultiple && acceptsArchiveInput(widget.xTypeGroup);
  }

  bool get _canSelectSeguiFolder {
    return Platform.isIOS && widget.allowDirectorySelection;
  }

  /// Only an Android folder copy reports progress and can stop.
  VoidCallback? get _cancelAction {
    if (_progress == null || _progress!.isCounting || !Platform.isAndroid) {
      return null;
    }
    return () => MobileIoChannel.instance.cancelCopy();
  }

  String? get _progressLabel {
    final InputCopyProgress? progress = _progress;
    if (!_isLoading || progress == null) {
      return null;
    }
    if (progress.isCounting) {
      return 'Copying files into SEGUI…';
    }
    final format = NumberFormat.decimalPattern();
    return 'Copying ${format.format(progress.copied)} / '
        '${format.format(progress.total)}';
  }

  String _dropHint(int sharedCount) {
    if (sharedCount > 0) {
      return _sharedLabel(sharedCount);
    }
    if (!isFileDropSupported) {
      return _canSelectArchive
          ? '${widget.xTypeGroup.label} files, a folder, or an archive'
          : '${widget.xTypeGroup.label} files';
    }
    if (!widget.allowMultiple) {
      return 'Drop a file here, or browse.';
    }
    return _canSelectDirectory
        ? 'Drop files or a folder here, or browse.'
        : 'Drop files here, or browse.';
  }

  String _selectedHint(int sharedCount) {
    if (sharedCount > 0) {
      return _sharedLabel(sharedCount);
    }
    if (!isFileDropSupported) {
      return '${widget.xTypeGroup.label} files';
    }
    return widget.allowMultiple
        ? 'Drop more files to add them'
        : 'Drop a file to replace it';
  }

  String _sharedLabel(int count) {
    return count == 1 ? '1 shared file ready' : '$count shared files ready';
  }

  List<PickerAction> _emptyActions(int sharedCount) {
    return [
      if (sharedCount > 0)
        PickerAction(
          label: 'Use shared files',
          icon: Icons.move_to_inbox_outlined,
          onSelected: () => _addFrom(const [], InputSource.shared),
        ),
      PickerAction(
        label: widget.allowMultiple ? 'Browse files' : 'Browse file',
        icon: Icons.note_add_outlined,
        onSelected: () => _addFiles(InputSource.files),
      ),
      if (_canSelectDirectory)
        PickerAction(
          label: 'Browse folder',
          icon: Icons.create_new_folder_outlined,
          onSelected: () => _addFiles(InputSource.folder),
        ),
      if (_canSelectArchive)
        PickerAction(
          label: 'Open archive',
          icon: Icons.folder_zip_outlined,
          onSelected: () => _addFrom(const [], InputSource.archive),
        ),
      if (_canSelectSeguiFolder)
        PickerAction(
          label: 'SEGUI folder',
          icon: Icons.snippet_folder_outlined,
          onSelected: () => _addFrom(const [], InputSource.seguiFolder),
        ),
    ];
  }

  List<PickerAction> _selectedActions(
    List<SegulInputFile> files,
    int sharedCount,
  ) {
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
      if (sharedCount > 0)
        PickerAction(
          label: 'Use shared files',
          icon: Icons.move_to_inbox_outlined,
          onSelected: () => _addFrom(files, InputSource.shared),
        ),
      PickerAction(
        label: 'Add files',
        icon: Icons.note_add_outlined,
        onSelected: () => _addFrom(files, InputSource.files),
      ),
      if (_canSelectDirectory)
        PickerAction(
          label: 'Add folder',
          icon: Icons.create_new_folder_outlined,
          onSelected: () => _addFrom(files, InputSource.folder),
        ),
      if (_canSelectArchive)
        PickerAction(
          label: 'Add archive',
          icon: Icons.folder_zip_outlined,
          onSelected: () => _addFrom(files, InputSource.archive),
        ),
      if (_canSelectSeguiFolder)
        PickerAction(
          label: 'Add from SEGUI folder',
          icon: Icons.snippet_folder_outlined,
          onSelected: () => _addFrom(files, InputSource.seguiFolder),
        ),
      PickerAction(
        label: 'Clear files',
        icon: Icons.clear_rounded,
        isDestructive: true,
        onSelected: () => notifier.removeType(type),
      ),
    ];
  }

  /// Starts a new selection from [source], which replaces all inputs
  /// unless other pickers share them.
  Future<void> _addFiles(InputSource source) async {
    if (widget.hasSecondaryPicker) {
      // A new selection would also clear the files of other pickers.
      await _addFrom(const [], source);
      return;
    }
    _startLoading();
    try {
      final selection = _getFileSelection();
      final InputAddResult result = source == InputSource.folder
          ? await selection.addDirectory()
          : await selection.selectFiles();
      _showSkipped(result);
    } catch (e) {
      _showError(e.toString());
    }

    _stopLoading();
  }

  /// Adds files from [source] to [currentFiles].
  Future<void> _addFrom(
    List<SegulInputFile> currentFiles,
    InputSource source,
  ) async {
    _startLoading();
    final selection = _getFileSelection();
    final files = currentFiles.map((e) => e.file).toList();
    try {
      final InputAddResult result = switch (source) {
        InputSource.files => await selection.addMoreFiles(files),
        InputSource.folder => await selection.addMoreDirectory(files),
        InputSource.archive => await selection.addArchive(files),
        InputSource.seguiFolder => await selection.addSeguiFolder(files),
        InputSource.shared => await _addShared(selection, files),
      };
      _showSkipped(result);
    } catch (e) {
      _showError(e.toString());
    }
    _stopLoading();
  }

  Future<InputAddResult> _addShared(
    FileInputServices selection,
    List<File> files,
  ) async {
    try {
      return await selection.addSharedFiles(files);
    } finally {
      ref.read(sharedInputProvider.notifier).clear();
    }
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
      onProgress: _setProgress,
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
      _progress = null;
    });
  }

  void _setProgress(InputCopyProgress progress) {
    if (!mounted) {
      return;
    }
    setState(() {
      _progress = progress;
    });
  }

  void _showSkipped(InputAddResult result) {
    if (result.skipped > 0) {
      _showError('Skipping ${result.skipped} file'
          '${result.skipped > 1 ? 's' : ''} in other formats.');
    } else {
      _showDuplicates(result.duplicates);
    }
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
      _progress = null;
    });
  }
}

/// An action offered by a file picker, as a button or a sheet or dialog item.
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
    final Widget child = widget.builder(context, _isDragging, null);
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
/// [compact], tapping the area runs the action, or lists them with
/// [showPickerActions] when there are several.
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
    this.progress,
    this.onCancel,
  });

  final IconData icon;
  final String title;
  final String hint;
  final List<PickerAction> actions;
  final bool compact;
  final bool isDragging;
  final bool isLoading;

  /// Fraction of files copied, or null while the total is unknown.
  final double? progress;

  /// Stops the running copy, when it can stop.
  final VoidCallback? onCancel;

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
                  progress: progress,
                  onCancel: onCancel,
                  onBrowse: () => _onTap(context),
                )
              : PickerDropZoneColumn(
                  icon: icon,
                  title: isDragging ? 'Release to add' : title,
                  hint: hint,
                  isLoading: isLoading,
                  progress: progress,
                  onCancel: onCancel,
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
    showPickerActions(context, title: title, actions: actions);
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
    this.progress,
    this.onCancel,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool isLoading;
  final List<PickerAction> actions;
  final double? progress;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(SeguiSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon,
              size: SeguiControlSize.iconLarge,
              color: theme.colorScheme.primary),
          const SizedBox(height: SeguiSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SeguiSpacing.xxs),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SeguiSpacing.lg),
          if (isLoading)
            Center(
              child: PickerProgress(value: progress, onCancel: onCancel),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: SeguiSpacing.md,
              runSpacing: SeguiSpacing.md,
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
    this.progress,
    this.onCancel,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool isLoading;
  final VoidCallback onBrowse;
  final double? progress;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          SeguiSpacing.lg, SeguiSpacing.md, SeguiSpacing.md, SeguiSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: SeguiSpacing.lg),
          Expanded(
            child: PickerText(title: Text(title), subtitle: hint),
          ),
          const SizedBox(width: SeguiSpacing.md),
          isLoading
              ? PickerProgress(value: progress, onCancel: onCancel)
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

/// Summary of the selected files with an edit button that lists the
/// picker actions with [showPickerActions].
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
    this.progress,
    this.onCancel,
  });

  final IconData icon;
  final Widget title;
  final String subtitle;
  final String sheetTitle;
  final List<PickerAction> actions;
  final bool isDragging;
  final bool isLoading;
  final double? progress;
  final VoidCallback? onCancel;

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
        padding: const EdgeInsets.fromLTRB(
            SeguiSpacing.lg, SeguiSpacing.md, SeguiSpacing.md, SeguiSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: SeguiSpacing.lg),
            Expanded(
              child: PickerText(
                title: title,
                subtitle: isDragging ? 'Release to add' : subtitle,
              ),
            ),
            const SizedBox(width: SeguiSpacing.md),
            isLoading
                ? PickerProgress(value: progress, onCancel: onCancel)
                : TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => showPickerActions(
                      context,
                      title: sheetTitle,
                      actions: actions,
                    ),
                    icon: const Icon(Icons.edit_outlined,
                        size: SeguiControlSize.iconSmall),
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

/// Progress indicator sized to sit in place of a picker button, with a
/// cancel button when [onCancel] is set.
class PickerProgress extends StatelessWidget {
  const PickerProgress({super.key, this.value, this.onCancel});

  /// Fraction done, or null for an indeterminate indicator.
  final double? value;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final Widget indicator = SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: SeguiStroke.regular,
      ),
    );
    if (onCancel == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: SeguiSpacing.xl),
        child: indicator,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        IconButton(
          tooltip: 'Stop copying',
          onPressed: onCancel,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

/// Shows the actions of a file picker in a bottom sheet on compact windows,
/// such as phones, and in a dialog on medium and wider windows, from an iPad
/// in portrait up.
Future<void> showPickerActions(
  BuildContext context, {
  required String title,
  required List<PickerAction> actions,
}) {
  if (WindowSizeClass.of(context).isAtLeast(WindowSizeClass.medium)) {
    return showDialog<void>(
      context: context,
      barrierLabel: title,
      builder: (context) => PickerActionDialog(title: title, actions: actions),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    barrierLabel: title,
    builder: (context) => PickerActionSheet(title: title, actions: actions),
  );
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            SeguiSpacing.xl, 0, SeguiSpacing.xl, SeguiSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  SeguiSpacing.xl, 0, SeguiSpacing.xl, SeguiSpacing.md),
              child: Text(
                title,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final (int i, PickerAction action) in actions.indexed) ...[
              if (_startsDestructiveGroup(actions, i))
                const Divider(height: SeguiSpacing.xl),
              PickerActionTile(action: action),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialog listing the actions of a file picker.
class PickerActionDialog extends StatelessWidget {
  const PickerActionDialog({
    super.key,
    required this.title,
    required this.actions,
  });

  final String title;
  final List<PickerAction> actions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      contentPadding: const EdgeInsets.fromLTRB(
          SeguiSpacing.lg, SeguiSpacing.xl, SeguiSpacing.lg, 0),
      content: SizedBox(
        width: pickerDialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (int i, PickerAction action) in actions.indexed) ...[
              if (_startsDestructiveGroup(actions, i))
                const Divider(height: SeguiSpacing.xl),
              PickerActionTile(action: action),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Content width of the picker action dialog, within the 280 to 560 dp
/// range of Material dialogs.
const double pickerDialogWidth = 360;

/// Whether the action at [index] is the first destructive action after
/// other actions, so a divider sets it apart.
bool _startsDestructiveGroup(List<PickerAction> actions, int index) {
  return index > 0 &&
      actions[index].isDestructive &&
      !actions[index - 1].isDestructive;
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
