import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/viewers/alignment/alignment_axes.dart';
import 'package:segui/screens/viewers/alignment/alignment_files.dart';
import 'package:segui/screens/viewers/alignment/alignment_grid.dart';
import 'package:segui/screens/viewers/alignment/alignment_overview.dart';
import 'package:segui/screens/viewers/alignment/alignment_partitions.dart';
import 'package:segui/screens/viewers/alignment/alignment_toolbar.dart';
import 'package:segui/screens/viewers/alignment/window_sidebar.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/keyboard.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/services/viewers/alignment_files.dart';
import 'package:segui/src/rust/api/alignment_view.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

final NumberFormat _siteFormat = NumberFormat('#,###');

/// How long the display settings take to open or close.
const Duration _settingsDuration = Duration(milliseconds: 200);

/// Colored, zoomable view of a FASTA, NEXUS, or PHYLIP file. With
/// [siblings], such as the other files of the list it was opened from, the
/// app bar steps between them and a file list can be shown beside the
/// viewer. Display settings carry over between files.
class AlignmentFileView extends ConsumerStatefulWidget {
  const AlignmentFileView({
    super.key,
    required this.file,
    this.siblings = const [],
  });

  final File file;
  final Iterable<File> siblings;

  @override
  ConsumerState<AlignmentFileView> createState() => _AlignmentFileViewState();
}

class _AlignmentFileViewState extends ConsumerState<AlignmentFileView> {
  late final AlignmentFileList _files = AlignmentFileList(
    widget.file,
    widget.siblings,
    order: ref.read(fileOrderProvider),
  );
  late int _index = _files.indexOf(widget.file);

  @override
  Widget build(BuildContext context) {
    // Watching keeps the settings alive while the next file loads.
    final AlignmentViewSettings settings =
        ref.watch(alignmentViewSettingsProvider);
    final File file = _files.files[_index];
    final bool hasOtherFiles = _files.length > 1;
    final bool isCompact = isPhoneScreen(context);
    final bool showFileList =
        hasOtherFiles && settings.showFileList && !isCompact;
    return CallbackShortcuts(
      bindings: {
        alignmentSettingsShortcut:
            ref.read(alignmentViewSettingsProvider.notifier).toggleSettings,
        if (hasOtherFiles) ...{
          const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): () =>
              _select(_files.step(_index, -1)),
          const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): () =>
              _select(_files.step(_index, 1)),
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(p.basename(file.path)),
            backgroundColor: getSEGULBackgroundColor(context),
            actions: [
              InfoButton(file: file),
            ],
          ),
          backgroundColor: getSEGULBackgroundColor(context),
          body: SafeArea(
            child: Padding(
              // Phones keep more of the screen for the grid.
              padding:
                  EdgeInsets.all(isCompact ? SeguiSpacing.sm : SeguiSpacing.xl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showFileList) ...[
                    SizedBox(
                      width: SeguiAlignmentLayout.fileList,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            // A Material panel, so list tiles keep their ink
                            // and color.
                            child: OutlinedPanel(
                              child: AlignmentFileRail(
                                files: _files,
                                index: _index,
                                onSelected: _select,
                              ),
                            ),
                          ),
                          // Ends level with the status line under the grid.
                          const AlignmentFileHint(),
                        ],
                      ),
                    ),
                    const SizedBox(width: SeguiSpacing.md),
                  ],
                  Expanded(
                    child: AlignmentViewBody(
                      key: ValueKey(file.path),
                      path: file.path,
                      leading: hasOtherFiles
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: AlignmentFileSwitcher(
                                    files: _files,
                                    index: _index,
                                    onSelected: _select,
                                  ),
                                ),
                                const SizedBox(
                                  height: SeguiControlSize.iconMedium,
                                  child: VerticalDivider(
                                    width: SeguiSpacing.sm,
                                  ),
                                ),
                                IconButton(
                                  tooltip: settings.showFileList && !isCompact
                                      ? 'Hide file list'
                                      : 'Show file list',
                                  visualDensity: controlDensity(context),
                                  isSelected: showFileList,
                                  icon: const Icon(Icons.list_rounded),
                                  selectedIcon:
                                      const Icon(Icons.playlist_play_rounded),
                                  onPressed: isCompact
                                      ? _showFileSheet
                                      : ref
                                          .read(alignmentViewSettingsProvider
                                              .notifier)
                                          .toggleFileList,
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the file at [index]. Sequence selections and the window belong
  /// to one file, so they reset.
  void _select(int index) {
    if (index == _index) return;
    ref.read(alignmentRowSelectionProvider.notifier).clear();
    ref.read(alignmentViewSettingsProvider.notifier).setWindow(0);
    setState(() => _index = index);
  }

  // Narrow screens show the file list as a sheet that closes on a pick.
  Future<void> _showFileSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: SeguiSheetLayout.listHeight,
        child: SafeArea(
          top: false,
          child: AlignmentFileRail(
            files: _files,
            index: _index,
            width: double.infinity,
            onSelected: (index) {
              Navigator.of(context).pop();
              _select(index);
            },
          ),
        ),
      ),
    );
  }
}

class AlignmentViewBody extends ConsumerWidget {
  const AlignmentViewBody({super.key, required this.path, this.leading});

  final String path;

  /// Shown at the start of the header, such as the file switcher. Stays in
  /// place while the file loads.
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AlignmentViewData> data =
        ref.watch(alignmentDataProvider(path));
    return data.when(
      data: (data) => data.rowCount == 0
          ? const Center(child: Text('This file has no sequences.'))
          : AlignmentExplorer(
              fileName: p.basename(path),
              data: data,
              leading: leading,
            ),
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Keeps the file switcher in place while the file loads.
          if (leading != null)
            Container(
              decoration: getContainerDecoration(context),
              padding: const EdgeInsets.all(SeguiSpacing.lg),
              alignment: Alignment.centerLeft,
              child: leading,
            ),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
      error: (error, _) => Center(
        child: Text(
          'Could not open this file as an alignment. $error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Toolbars, overview, window list, and grid of a loaded alignment.
class AlignmentExplorer extends ConsumerStatefulWidget {
  const AlignmentExplorer({
    super.key,
    required this.fileName,
    required this.data,
    this.leading,
  });

  final String fileName;
  final AlignmentViewData data;

  /// Shown at the start of the header in place of the file name.
  final Widget? leading;

  @override
  ConsumerState<AlignmentExplorer> createState() => _AlignmentExplorerState();
}

class _AlignmentExplorerState extends ConsumerState<AlignmentExplorer> {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  final ValueNotifier<AlignmentCell?> _hover = ValueNotifier(null);
  final ValueNotifier<AlignmentCell?> _selection = ValueNotifier(null);
  final TextEditingController _siteController = TextEditingController();

  /// Partition at the left edge of the grid, or the last one before it.
  final ValueNotifier<int?> _partition = ValueNotifier(null);
  _ScrollTarget? _pending;
  RowSelection? _orderSelection;

  /// Cell size when the current pinch began.
  double _pinchStartSize = SeguiAlignmentLayout.cellDefault;
  List<int> _order = const [];

  @override
  void initState() {
    super.initState();
    _horizontal.addListener(_syncWindow);
    if (widget.data.hasPartitions) _partition.value = 0;
  }

  @override
  void didUpdateWidget(AlignmentExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      _orderSelection = null;
    }
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    _hover.dispose();
    _selection.dispose();
    _siteController.dispose();
    _partition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AlignmentViewSettings settings =
        ref.watch(alignmentViewSettingsProvider);
    ref.listen(alignmentViewSettingsProvider, _keepCenter);
    final RowSelection rowSelection = ref.watch(alignmentRowSelectionProvider);
    final AlignmentViewData data = widget.data;
    final List<int> order = _orderOf(rowSelection);
    final AlignmentSiteRange siteRange = _siteRangeOf(settings);
    final bool isCompact = isPhoneScreen(context);
    final bool showWindowList = settings.showWindowList && !isCompact;
    final double nameWidth = settings.nameWidth ??
        (isCompact
            ? SeguiAlignmentLayout.nameColumnCompact
            : SeguiAlignmentLayout.nameColumn);
    final AlignmentOverview overview = AlignmentOverview(
      data: data,
      rowOrder: order,
      selectedRows: rowSelection.rows,
      siteRange: siteRange,
      cellSize: settings.cellSize,
      rowHeight: settings.rowHeight,
      horizontalController: _horizontal,
      verticalController: _vertical,
      onJump: (site, row) => _goToSite(site, row: row),
      height: isCompact
          ? SeguiAlignmentLayout.overviewCompact
          : SeguiAlignmentLayout.overview,
    );
    final AlignmentStatusBar status = AlignmentStatusBar(
      data: data,
      siteRange: siteRange,
      cellSize: settings.cellSize,
      horizontalController: _horizontal,
      hover: _hover,
      selection: _selection,
      isTouch: isCompact,
    );
    final WindowSidebar windowList = WindowSidebar(
      data: data,
      windowSize: settings.windowSize,
      currentWindow: settings.window,
      onSelected: _goToWindow,
    );
    final Widget gridPanel = Container(
      decoration: getContainerDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showWindowList) ...[
            AlignmentSideList(
              data: data,
              windows: windowList,
              partitions: PartitionSidebar(
                data: data,
                current: _partition,
                onSelected: _goToPartition,
              ),
            ),
            const VerticalDivider(width: SeguiStroke.thin),
          ],
          Expanded(
            child: Column(
              children: [
                if (data.hasPartitions)
                  Row(
                    children: [
                      SizedBox(
                        width: nameWidth + SeguiAlignmentLayout.nameDivider,
                        child: Padding(
                          padding: const EdgeInsets.only(left: SeguiSpacing.sm),
                          child: Text(
                            'Partitions',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: AlignmentPartitionTrack(
                          index: data.partitionIndex,
                          controller: _horizontal,
                          siteRange: siteRange,
                          cellSize: settings.cellSize,
                          current: _partition,
                          onSelected: _goToPartition,
                        ),
                      ),
                      const SizedBox(width: SeguiControlSize.scrollbarGutter),
                    ],
                  ),
                Row(
                  children: [
                    SizedBox(
                      width: nameWidth + SeguiAlignmentLayout.nameDivider,
                    ),
                    Expanded(
                      child: AlignmentRuler(
                        controller: _horizontal,
                        siteRange: siteRange,
                        cellSize: settings.cellSize,
                      ),
                    ),
                    // Above the grid's scrollbar lane.
                    const SizedBox(width: SeguiControlSize.scrollbarGutter),
                  ],
                ),
                const Divider(height: SeguiStroke.thin),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ends level with the grid, above its scrollbar lane.
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: SeguiControlSize.scrollbarGutter,
                        ),
                        child: AlignmentNames(
                          names: data.names,
                          rowOrder: order,
                          selectedRows: rowSelection.rows,
                          controller: _vertical,
                          rowHeight: settings.rowHeight,
                          width: nameWidth,
                          selection: _selection,
                          onRowTap: (row, {required extend, required toggle}) =>
                              _rowSelectionNotifier.tap(
                            row,
                            order,
                            extend: extend,
                            // Phones have no keys to hold, so taps add
                            // and remove names.
                            toggle: toggle || isCompact,
                          ),
                        ),
                      ),
                      AlignmentNameDivider(
                        onDrag: (dx) => _notifier.setNameWidth(nameWidth + dx),
                        onReset: _notifier.resetNameWidth,
                      ),
                      Expanded(
                        child: AlignmentGrid(
                          data: data,
                          rowOrder: order,
                          selectedRows: rowSelection.rows,
                          siteRange: siteRange,
                          cellSize: settings.cellSize,
                          rowHeight: settings.rowHeight,
                          colorMode: settings.colorMode,
                          showLetters: settings.showLetters,
                          windowSize: settings.windowSize,
                          showWindowBoundaries: true,
                          partitionStarts: data.partitionIndex.starts,
                          horizontalController: _horizontal,
                          verticalController: _vertical,
                          hover: _hover,
                          selection: _selection,
                          onZoom: _zoom,
                          onPinchStart: () =>
                              _pinchStartSize = _settings.cellSize,
                          onPinch: (scale) =>
                              _notifier.setCellSize(_pinchStartSize * scale),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (isCompact) {
      // Nothing outside the grid scrolls, so every drag moves the residues.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: getContainerDecoration(context),
            padding: const EdgeInsets.fromLTRB(
              SeguiSpacing.md,
              SeguiSpacing.xs,
              SeguiSpacing.xs,
              SeguiSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AlignmentPhoneHeader(
                  leading: widget.leading,
                  onShowWindows: _showWindowSheet,
                  onShowSettings: _showSettingsSheet,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: SeguiSpacing.sm),
                  child: overview,
                ),
              ],
            ),
          ),
          const SizedBox(height: SeguiSpacing.sm),
          Expanded(child: gridPanel),
          Padding(
            padding: const EdgeInsets.only(left: SeguiSpacing.md),
            child: SizedBox(
              height: SeguiControlSize.touchTarget,
              child: Row(
                children: [
                  Expanded(child: status),
                  if (!rowSelection.isEmpty)
                    TextButton.icon(
                      icon: const Icon(
                        Icons.checklist_rounded,
                        size: SeguiControlSize.iconSmall,
                      ),
                      label: Text(
                        '${_siteFormat.format(rowSelection.rows.length)} '
                        'selected',
                      ),
                      onPressed: _showSelectionSheet,
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return CustomScrollView(
      // The grid and window list scroll on their own. This only scrolls the
      // header away when the window is too short for it and the grid, so it
      // draws no scrollbar over the grid's own.
      primary: false,
      scrollBehavior:
          ScrollConfiguration.of(context).copyWith(scrollbars: false),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: getContainerDecoration(context),
            padding: const EdgeInsets.all(SeguiSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AlignmentHeaderBar(
                  fileName: widget.fileName,
                  data: data,
                  leading: widget.leading,
                  canShowWindowList: true,
                  siteController: _siteController,
                  onGoToSite: _goToText,
                  onGoToPartition: _goToPartition,
                  partitionNavigator: data.hasPartitions
                      ? AlignmentPartitionNavigator(
                          data: data,
                          current: _partition,
                          onSelected: _goToPartition,
                        )
                      : null,
                ),
                // Hiding the settings leaves the grid more room.
                AnimatedSize(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : _settingsDuration,
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: settings.showSettings
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: SeguiSpacing.md),
                            const Divider(height: SeguiStroke.thin),
                            const SizedBox(height: SeguiSpacing.md),
                            AlignmentToolbar(
                              data: data,
                              onPrevious: () =>
                                  _goToWindow(settings.window - 1),
                              onNext: () => _goToWindow(settings.window + 1),
                            ),
                            const SizedBox(height: SeguiSpacing.lg),
                            overview,
                            const SizedBox(height: SeguiSpacing.sm),
                            AlignmentLegend(isDna: data.isDna),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
        SliverLayoutBuilder(
          builder: (context, constraints) => SliverToBoxAdapter(
            child: SizedBox(
              height: math.max(
                SeguiAlignmentLayout.gridMin,
                constraints.viewportMainAxisExtent -
                    constraints.precedingScrollExtent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: SeguiSpacing.md),
                  Expanded(child: gridPanel),
                  // The text sits at the bottom, level with the file list's
                  // bottom edge, inset like the panels' content.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SeguiSpacing.lg,
                      SeguiSpacing.xs,
                      SeguiSpacing.lg,
                      0,
                    ),
                    child: Wrap(
                      spacing: SeguiSpacing.lg,
                      runSpacing: SeguiSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        status,
                        if (!rowSelection.isEmpty)
                          AlignmentSelectionBar(data: data),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Phones show the display settings in a sheet.
  Future<void> _showSettingsSheet() {
    return showResponsiveSheet<void>(
      context: context,
      builder: (context) => SheetContent(
        title: 'View settings',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
        child: AlignmentSettingsSheet(
          data: widget.data,
          siteController: _siteController,
          onPrevious: () => _goToWindow(_settings.window - 1),
          onNext: () => _goToWindow(_settings.window + 1),
          onGoToSite: _goToText,
          onGoToPartition: _goToPartition,
        ),
      ),
    );
  }

  /// Phones show the window list in a sheet that closes on a pick.
  Future<void> _showWindowSheet() {
    final AlignmentViewSettings settings = _settings;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: SeguiAlignmentLayout.windowSheetHeight,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SeguiSpacing.xxl,
                  0,
                  SeguiSpacing.xxl,
                  SeguiSpacing.md,
                ),
                child: Text(
                  widget.data.hasPartitions
                      ? 'Windows and partitions'
                      : 'Windows',
                  style: Theme.of(sheetContext).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: AlignmentSideList(
                  data: widget.data,
                  width: double.infinity,
                  windows: WindowSidebar(
                    data: widget.data,
                    width: double.infinity,
                    windowSize: settings.windowSize,
                    currentWindow: _windowsOf(settings).clamp(settings.window),
                    onSelected: (window) {
                      Navigator.of(sheetContext).pop();
                      _goToWindow(window);
                    },
                  ),
                  partitions: PartitionSidebar(
                    data: widget.data,
                    width: double.infinity,
                    current: _partition,
                    onSelected: (index) {
                      Navigator.of(sheetContext).pop();
                      _goToPartition(index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Phones show what to do with selected sequences in a sheet.
  Future<void> _showSelectionSheet() {
    return showResponsiveSheet<void>(
      context: context,
      builder: (sheetContext) => SheetContent(
        title: 'Selected sequences',
        child: AlignmentSelectionSheet(
          onCopy: () {
            Navigator.of(sheetContext).pop();
            _copySequences(
              context,
              widget.data,
              ref.read(alignmentRowSelectionProvider),
            );
          },
        ),
      ),
    );
  }

  AlignmentViewSettings get _settings =>
      ref.read(alignmentViewSettingsProvider);

  AlignmentViewSettingsNotifier get _notifier =>
      ref.read(alignmentViewSettingsProvider.notifier);

  AlignmentRowSelectionNotifier get _rowSelectionNotifier =>
      ref.read(alignmentRowSelectionProvider.notifier);

  /// Display order for [selection], kept while the selection is unchanged
  /// so the grid and overview are not rebuilt.
  List<int> _orderOf(RowSelection selection) {
    if (!identical(selection, _orderSelection)) {
      _orderSelection = selection;
      _order = selection.orderOf(widget.data.rowCount);
    }
    return _order;
  }

  AlignmentWindows _windowsOf(AlignmentViewSettings settings) {
    return AlignmentWindows(
        length: widget.data.length, size: settings.windowSize);
  }

  AlignmentSiteRange _siteRangeOf(AlignmentViewSettings settings) {
    return AlignmentSiteRange(0, widget.data.length);
  }

  double _viewportOf(ScrollController controller) {
    if (!controller.hasClients || !controller.position.hasViewportDimension) {
      return 0;
    }
    return controller.position.viewportDimension;
  }

  double _offsetOf(ScrollController controller) {
    return controller.hasClients ? controller.offset : 0;
  }

  /// Zero-based site at the middle of the grid.
  int _centerSite(AlignmentViewSettings settings) {
    final double x = _offsetOf(_horizontal) + _viewportOf(_horizontal) / 2;
    return (_siteRangeOf(settings).start + x ~/ settings.cellSize)
        .clamp(0, widget.data.length - 1);
  }

  int _centerRow(AlignmentViewSettings settings) {
    final double y = _offsetOf(_vertical) + _viewportOf(_vertical) / 2;
    final int rows = _order.isEmpty ? 1 : _order.length;
    return (y ~/ settings.rowHeight).clamp(0, rows - 1);
  }

  // Zoom changes the grid size; keep the same site in the middle.
  void _keepCenter(
      AlignmentViewSettings? previous, AlignmentViewSettings next) {
    if (previous == null) return;
    if (previous.cellSize == next.cellSize) return;
    // A scroll still waiting for layout has not moved the grid yet.
    final _ScrollTarget? pending = _pending;
    final int site = pending == null || pending.alignStart
        ? _centerSite(previous)
        : pending.site;
    final int row = pending?.row ?? _centerRow(previous);
    _scrollAfterLayout(site: site, row: row);
  }

  // The window follows the middle of the grid, and the current partition
  // its left edge.
  void _syncWindow() {
    final AlignmentViewSettings settings = _settings;
    if (widget.data.hasPartitions) {
      final int left = _siteRangeOf(settings).start +
          _offsetOf(_horizontal) ~/ settings.cellSize;
      _partition.value = widget.data.partitionIndex.nearest(left) ?? 0;
    }
    final int window = _windowsOf(settings).windowOf(_centerSite(settings));
    if (window != settings.window) _notifier.setWindow(window);
  }

  void _zoom(int direction) {
    direction > 0 ? _notifier.zoomIn() : _notifier.zoomOut();
  }

  void _goToWindow(int window) {
    final AlignmentWindows windows = _windowsOf(_settings);
    final int target = windows.clamp(window);
    _notifier.setWindow(target);
    _scrollAfterLayout(site: windows.startOf(target), alignStart: true);
  }

  /// Shows partition [index] from its first site.
  void _goToPartition(int index) {
    final List<AlignmentPartition> partitions = widget.data.partitions;
    if (partitions.isEmpty) return;
    final int target = index.clamp(0, partitions.length - 1);
    final int site = partitions[target].start;
    _partition.value = target;
    _scrollAfterLayout(site: site, alignStart: true);
  }

  void _goToSite(int site, {int? row}) {
    final int dataRow = row != null && row < _order.length
        ? _order[row]
        : _selection.value?.row ?? _order.first;
    _selection.value = AlignmentCell(dataRow, site);
    _scrollAfterLayout(site: site, row: row);
  }

  /// Goes to a site, partition, `partition:site`, or taxon.
  void _goToText(String text) {
    final GoToTarget target = parseGoTo(widget.data, text);
    final String? error = target.error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    final int? partition = target.partition;
    if (partition != null) {
      _goToPartition(partition);
      return;
    }
    final int? dataRow = target.row;
    // A hidden sequence keeps the current row.
    final int? row = dataRow == null ? null : _order.indexOf(dataRow);
    final int site = target.site ?? _selection.value?.site ?? 0;
    _goToSite(site, row: row == null || row < 0 ? null : row);
  }

  /// Scrolls to [site] and [row] once the grid has laid out with the latest
  /// settings. Sites are centered unless [alignStart] is true. A later call
  /// before that layout replaces the target.
  void _scrollAfterLayout({
    required int site,
    int? row,
    bool alignStart = false,
  }) {
    final bool isScheduled = _pending != null;
    _pending = _ScrollTarget(site, row, alignStart);
    if (isScheduled) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final _ScrollTarget? target = _pending;
      _pending = null;
      if (!mounted || target == null) return;
      final AlignmentViewSettings settings = _settings;
      final AlignmentSiteRange siteRange = _siteRangeOf(settings);
      final double cellX = (target.site - siteRange.start) * settings.cellSize;
      _jump(
        _horizontal,
        target.alignStart
            ? cellX
            : cellX + settings.cellSize / 2 - _viewportOf(_horizontal) / 2,
      );
      final int? row = target.row;
      if (row != null) {
        _jump(
          _vertical,
          (row + 0.5) * settings.rowHeight - _viewportOf(_vertical) / 2,
        );
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _jump(ScrollController controller, double offset) {
    if (!controller.hasClients) return;
    final ScrollPosition position = controller.position;
    position.jumpTo(
      offset.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }
}

/// Count of selected sequences and what to do with them.
class AlignmentSelectionBar extends ConsumerWidget {
  const AlignmentSelectionBar({super.key, required this.data});

  final AlignmentViewData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RowSelection selection = ref.watch(alignmentRowSelectionProvider);
    final AlignmentRowSelectionNotifier notifier =
        ref.read(alignmentRowSelectionProvider.notifier);
    final int count = selection.rows.length;
    return Wrap(
      spacing: SeguiSpacing.sm,
      runSpacing: SeguiSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${_siteFormat.format(count)} selected',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        TextButton.icon(
          icon:
              const Icon(Icons.copy_rounded, size: SeguiControlSize.iconSmall),
          label: const Text('Copy as FASTA'),
          onPressed: () => _copySequences(context, data, selection),
        ),
        FilterChip(
          label: const Text('Only selected'),
          visualDensity: controlDensity(context),
          selected: selection.showOnlySelected,
          onSelected: notifier.setShowOnlySelected,
        ),
        FilterChip(
          label: const Text('Pin to top'),
          visualDensity: controlDensity(context),
          selected: selection.pinSelected,
          onSelected: notifier.setPinSelected,
        ),
        TextButton(onPressed: notifier.clear, child: const Text('Clear')),
      ],
    );
  }
}

/// What to do with selected sequences, in a sheet on phones.
class AlignmentSelectionSheet extends ConsumerWidget {
  const AlignmentSelectionSheet({super.key, required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RowSelection selection = ref.watch(alignmentRowSelectionProvider);
    final AlignmentRowSelectionNotifier notifier =
        ref.read(alignmentRowSelectionProvider.notifier);
    final int count = selection.rows.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.copy_rounded),
          title: Text(
            'Copy ${_siteFormat.format(count)} as FASTA',
          ),
          onTap: onCopy,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.filter_list_rounded),
          title: const Text('Only selected'),
          value: selection.showOnlySelected,
          onChanged: notifier.setShowOnlySelected,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.vertical_align_top_rounded),
          title: const Text('Pin to top'),
          value: selection.pinSelected,
          onChanged: notifier.setPinSelected,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.clear_rounded),
          title: const Text('Clear selection'),
          onTap: () {
            Navigator.of(context).pop();
            notifier.clear();
          },
        ),
      ],
    );
  }
}

/// Copies the [selection] of [data] as FASTA and confirms with a snack bar.
Future<void> _copySequences(
  BuildContext context,
  AlignmentViewData data,
  RowSelection selection,
) async {
  final String fasta = await data.residues.fasta(selection.rows);
  await Clipboard.setData(ClipboardData(text: fasta));
  if (!context.mounted) return;
  final int count = selection.rows.length;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(
      'Copied ${_siteFormat.format(count)} '
      '${count == 1 ? 'sequence' : 'sequences'}',
    ),
  ));
}

/// Where to scroll once the grid lays out.
class _ScrollTarget {
  const _ScrollTarget(this.site, this.row, this.alignStart);

  final int site;
  final int? row;
  final bool alignStart;
}

/// Taxon, site, residue, and partition under the pointer or selection,
/// otherwise the sites in view.
class AlignmentStatusBar extends StatelessWidget {
  const AlignmentStatusBar({
    super.key,
    required this.data,
    required this.siteRange,
    required this.cellSize,
    required this.horizontalController,
    required this.hover,
    required this.selection,
    this.isTouch = false,
  });

  final AlignmentViewData data;
  final AlignmentSiteRange siteRange;
  final double cellSize;
  final ScrollController horizontalController;
  final ValueNotifier<AlignmentCell?> hover;
  final ValueNotifier<AlignmentCell?> selection;

  /// Hints at pinching instead of scrolling with a key to zoom.
  final bool isTouch;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(
        [hover, selection, horizontalController, data.residues],
      ),
      builder: (context, _) => Text(
        _status(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _status() {
    final AlignmentCell? cell = hover.value ?? selection.value;
    if (cell != null && cell.row < data.rowCount) {
      final int? code = data.residueAt(cell.row, cell.site);
      final String residue = code == null ? '' : String.fromCharCode(code);
      final int? position = data.residues.ungappedPosition(cell.row, cell.site);
      return '${data.names[cell.row]} · site ${_siteFormat.format(cell.site + 1)}'
          ' · ${position == null ? 'gap' : 'ungapped ${_siteFormat.format(position)}'}'
          '${residue.isEmpty ? '' : ' · $residue'}'
          '${_partitionStatus(cell.site)}';
    }
    final double offset =
        horizontalController.hasClients ? horizontalController.offset : 0;
    final double extent = horizontalController.hasClients &&
            horizontalController.position.hasViewportDimension
        ? horizontalController.position.viewportDimension
        : 0;
    final VisibleRange cols = VisibleRange.of(
      offset: offset,
      extent: extent,
      itemSize: cellSize,
      count: siteRange.length,
    );
    final String zoomHint = isTouch
        ? 'Pinch to zoom'
        : '${PlatformKeys.primaryLabel} + scroll to zoom';
    if (cols.length == 0) return zoomHint;
    if (data.partitionError != null) return data.partitionError!;
    return 'Showing sites ${_siteFormat.format(siteRange.start + cols.first + 1)}–'
        '${_siteFormat.format(siteRange.start + cols.last)} of '
        '${_siteFormat.format(data.length)} · $zoomHint';
  }

  // Partition at [site] and the site within it, such as
  // ` · locus_08 (8/42) site 13 of 650`.
  String _partitionStatus(int site) {
    final int? index = data.partitionIndex.indexAt(site);
    if (index == null) return '';
    final AlignmentPartition partition = data.partitions[index];
    return ' · ${data.partitionNameAt(site)} '
        '(${_siteFormat.format(index + 1)}/${_siteFormat.format(data.partitions.length)})'
        ' site ${_siteFormat.format(site - partition.start + 1)} of '
        '${_siteFormat.format(partition.end - partition.start)}';
  }
}
