import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/viewers/alignment/alignment_axes.dart';
import 'package:segui/screens/viewers/alignment/alignment_grid.dart';
import 'package:segui/screens/viewers/alignment/alignment_gull.dart';
import 'package:segui/screens/viewers/alignment/alignment_overview.dart';
import 'package:segui/screens/viewers/alignment/alignment_toolbar.dart';
import 'package:segui/screens/viewers/alignment/chunk_sidebar.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/src/rust/api/alignment_view.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

final NumberFormat _siteFormat = NumberFormat('#,###');

/// Colored, zoomable view of a FASTA, NEXUS, or PHYLIP file.
class AlignmentFileView extends StatelessWidget {
  const AlignmentFileView({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(file.path)),
        backgroundColor: getSEGULBackgroundColor(context),
        actions: [
          InfoButton(file: file),
        ],
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: Padding(
        padding: const EdgeInsets.all(SeguiSpacing.xl),
        child: AlignmentViewBody(path: file.path),
      ),
    );
  }
}

class AlignmentViewBody extends ConsumerWidget {
  const AlignmentViewBody({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AlignmentViewData> data =
        ref.watch(alignmentDataProvider(path));
    return data.when(
      data: (data) => data.sequences.isEmpty
          ? const Center(child: Text('This file has no sequences.'))
          : AlignmentExplorer(fileName: p.basename(path), data: data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Could not open this file as an alignment. $error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Toolbars, overview, chunk list, and grid of a loaded alignment.
class AlignmentExplorer extends ConsumerStatefulWidget {
  const AlignmentExplorer({
    super.key,
    required this.fileName,
    required this.data,
  });

  final String fileName;
  final AlignmentViewData data;

  @override
  ConsumerState<AlignmentExplorer> createState() => _AlignmentExplorerState();
}

class _AlignmentExplorerState extends ConsumerState<AlignmentExplorer> {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  final ValueNotifier<AlignmentCell?> _hover = ValueNotifier(null);
  final ValueNotifier<AlignmentCell?> _selection = ValueNotifier(null);
  final TextEditingController _siteController = TextEditingController();
  late UngappedIndex _ungapped = UngappedIndex(widget.data.sequences);
  _ScrollTarget? _pending;
  RowSelection? _orderSelection;
  List<int> _order = const [];

  @override
  void initState() {
    super.initState();
    _horizontal.addListener(_syncChunk);
  }

  @override
  void didUpdateWidget(AlignmentExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      _ungapped = UngappedIndex(widget.data.sequences);
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
    final AlignmentWindow window = _windowOf(settings);
    final bool isCompact = isPhoneScreen(context);
    final bool showChunkList = settings.showChunkList && !isCompact;
    final double nameWidth = settings.nameWidth ??
        (isCompact
            ? SeguiAlignmentLayout.nameColumnCompact
            : SeguiAlignmentLayout.nameColumn);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The gull stands on the toolbar's top edge near its right corner.
        Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(top: AlignmentGull.standingHeight),
              child: Container(
                decoration: getContainerDecoration(context),
                padding: const EdgeInsets.all(SeguiSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AlignmentToolbar(
                      fileName: widget.fileName,
                      data: data,
                      canShowChunkList: !isCompact,
                      siteController: _siteController,
                      onPrevious: () => _goToChunk(settings.chunk - 1),
                      onNext: () => _goToChunk(settings.chunk + 1),
                      onGoToSite: _goToSiteText,
                    ),
                    const SizedBox(height: SeguiSpacing.lg),
                    AlignmentOverview(
                      data: data,
                      rowOrder: order,
                      selectedRows: rowSelection.rows,
                      window: window,
                      cellSize: settings.cellSize,
                      rowHeight: settings.rowHeight,
                      horizontalController: _horizontal,
                      verticalController: _vertical,
                      onJump: (site, row) => _goToSite(site, row: row),
                    ),
                    const SizedBox(height: SeguiSpacing.sm),
                    AlignmentLegend(isDna: data.isDna),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 0,
              right: SeguiSpacing.xl,
              child: AlignmentGull(),
            ),
          ],
        ),
        const SizedBox(height: SeguiSpacing.md),
        Expanded(
          child: Container(
            decoration: getContainerDecoration(context),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showChunkList) ...[
                  ChunkSidebar(
                    data: data,
                    chunkSize: settings.chunkSize,
                    currentChunk: settings.chunk,
                    onSelected: _goToChunk,
                  ),
                  const VerticalDivider(width: SeguiStroke.thin),
                ],
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: nameWidth + SeguiAlignmentLayout.nameDivider,
                          ),
                          Expanded(
                            child: AlignmentRuler(
                              controller: _horizontal,
                              window: window,
                              cellSize: settings.cellSize,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: SeguiStroke.thin),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AlignmentNames(
                              names: data.names,
                              rowOrder: order,
                              selectedRows: rowSelection.rows,
                              controller: _vertical,
                              rowHeight: settings.rowHeight,
                              width: nameWidth,
                              selection: _selection,
                              onRowTap: (row,
                                      {required extend, required toggle}) =>
                                  _rowSelectionNotifier.tap(
                                row,
                                order,
                                extend: extend,
                                toggle: toggle,
                              ),
                            ),
                            AlignmentNameDivider(
                              onDrag: (dx) =>
                                  _notifier.setNameWidth(nameWidth + dx),
                              onReset: _notifier.resetNameWidth,
                            ),
                            Expanded(
                              child: AlignmentGrid(
                                data: data,
                                rowOrder: order,
                                selectedRows: rowSelection.rows,
                                window: window,
                                cellSize: settings.cellSize,
                                rowHeight: settings.rowHeight,
                                colorMode: settings.colorMode,
                                showLetters: settings.showLetters,
                                chunkSize: settings.chunkSize,
                                showChunkBoundaries: !settings.isPaged,
                                horizontalController: _horizontal,
                                verticalController: _vertical,
                                hover: _hover,
                                selection: _selection,
                                onZoom: _zoom,
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
          ),
        ),
        const SizedBox(height: SeguiSpacing.sm),
        Wrap(
          spacing: SeguiSpacing.lg,
          runSpacing: SeguiSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AlignmentStatusBar(
              data: data,
              window: window,
              cellSize: settings.cellSize,
              horizontalController: _horizontal,
              hover: _hover,
              selection: _selection,
              ungapped: _ungapped,
            ),
            if (!rowSelection.isEmpty) AlignmentSelectionBar(data: data),
          ],
        ),
      ],
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
      _order = selection.orderOf(widget.data.sequences.length);
    }
    return _order;
  }

  AlignmentChunks _chunksOf(AlignmentViewSettings settings) {
    return AlignmentChunks(
        length: widget.data.length, size: settings.chunkSize);
  }

  AlignmentWindow _windowOf(AlignmentViewSettings settings) {
    if (!settings.isPaged) return AlignmentWindow(0, widget.data.length);
    final AlignmentChunks chunks = _chunksOf(settings);
    final int chunk = chunks.clamp(settings.chunk);
    return AlignmentWindow(chunks.startOf(chunk), chunks.endOf(chunk));
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
    return (_windowOf(settings).start + x ~/ settings.cellSize)
        .clamp(0, widget.data.length - 1);
  }

  int _centerRow(AlignmentViewSettings settings) {
    final double y = _offsetOf(_vertical) + _viewportOf(_vertical) / 2;
    final int rows = _order.isEmpty ? 1 : _order.length;
    return (y ~/ settings.rowHeight).clamp(0, rows - 1);
  }

  // Zoom and paging change the grid size; keep the same site in the middle.
  void _keepCenter(
      AlignmentViewSettings? previous, AlignmentViewSettings next) {
    if (previous == null) return;
    final bool resized = previous.cellSize != next.cellSize ||
        previous.isPaged != next.isPaged ||
        (next.isPaged && previous.chunkSize != next.chunkSize);
    if (!resized) return;
    // A scroll still waiting for layout has not moved the grid yet.
    final _ScrollTarget? pending = _pending;
    final int site = pending == null || pending.alignStart
        ? _centerSite(previous)
        : pending.site;
    final int row = pending?.row ?? _centerRow(previous);
    if (next.isPaged && !previous.isPaged) {
      _notifier.setChunk(_chunksOf(next).chunkOf(site));
    }
    _scrollAfterLayout(site: site, row: row);
  }

  // In continuous view, the chunk follows the middle of the grid.
  void _syncChunk() {
    final AlignmentViewSettings settings = _settings;
    if (settings.isPaged) return;
    final int chunk = _chunksOf(settings).chunkOf(_centerSite(settings));
    if (chunk != settings.chunk) _notifier.setChunk(chunk);
  }

  void _zoom(int direction) {
    direction > 0 ? _notifier.zoomIn() : _notifier.zoomOut();
  }

  void _goToChunk(int chunk) {
    final AlignmentChunks chunks = _chunksOf(_settings);
    final int target = chunks.clamp(chunk);
    _notifier.setChunk(target);
    _scrollAfterLayout(site: chunks.startOf(target), alignStart: true);
  }

  void _goToSite(int site, {int? row}) {
    final AlignmentViewSettings settings = _settings;
    if (settings.isPaged) {
      _notifier.setChunk(_chunksOf(settings).chunkOf(site));
    }
    final int dataRow = row != null && row < _order.length
        ? _order[row]
        : _selection.value?.row ?? _order.first;
    _selection.value = AlignmentCell(dataRow, site);
    _scrollAfterLayout(site: site, row: row);
  }

  void _goToSiteText(String text) {
    final int? site = int.tryParse(text.replaceAll(',', '').trim());
    final int length = widget.data.length;
    if (site == null || site < 1 || site > length) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enter a site from 1 to ${_siteFormat.format(length)}.'),
      ));
      return;
    }
    _goToSite(site - 1);
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
      final AlignmentWindow window = _windowOf(settings);
      final double cellX = (target.site - window.start) * settings.cellSize;
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
          onPressed: () => _copy(context, selection),
        ),
        FilterChip(
          label: const Text('Only selected'),
          visualDensity: VisualDensity.compact,
          selected: selection.showOnlySelected,
          onSelected: notifier.setShowOnlySelected,
        ),
        FilterChip(
          label: const Text('Pin to top'),
          visualDensity: VisualDensity.compact,
          selected: selection.pinSelected,
          onSelected: notifier.setPinSelected,
        ),
        TextButton(onPressed: notifier.clear, child: const Text('Clear')),
      ],
    );
  }

  Future<void> _copy(BuildContext context, RowSelection selection) async {
    await Clipboard.setData(ClipboardData(
      text: fastaOf(data.names, data.sequences, selection.rows),
    ));
    if (!context.mounted) return;
    final int count = selection.rows.length;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Copied ${_siteFormat.format(count)} '
        '${count == 1 ? 'sequence' : 'sequences'}',
      ),
    ));
  }
}

/// Where to scroll once the grid lays out.
class _ScrollTarget {
  const _ScrollTarget(this.site, this.row, this.alignStart);

  final int site;
  final int? row;
  final bool alignStart;
}

/// Taxon, site, and residue under the pointer or selection, otherwise the
/// sites in view.
class AlignmentStatusBar extends StatelessWidget {
  const AlignmentStatusBar({
    super.key,
    required this.data,
    required this.window,
    required this.cellSize,
    required this.horizontalController,
    required this.hover,
    required this.selection,
    required this.ungapped,
  });

  final AlignmentViewData data;
  final AlignmentWindow window;
  final double cellSize;
  final ScrollController horizontalController;
  final ValueNotifier<AlignmentCell?> hover;
  final ValueNotifier<AlignmentCell?> selection;
  final UngappedIndex ungapped;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([hover, selection, horizontalController]),
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
    if (cell != null && cell.row < data.sequences.length) {
      final Uint8List seq = data.sequences[cell.row];
      final String residue =
          cell.site < seq.length ? String.fromCharCode(seq[cell.site]) : '';
      final int? position = ungapped.positionOf(cell.row, cell.site);
      return '${data.names[cell.row]} · site ${_siteFormat.format(cell.site + 1)}'
          ' · ${position == null ? 'gap' : 'ungapped ${_siteFormat.format(position)}'}'
          '${residue.isEmpty ? '' : ' · $residue'}';
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
      count: window.length,
    );
    if (cols.length == 0) return 'Ctrl or Cmd + scroll to zoom';
    return 'Showing sites ${_siteFormat.format(window.start + cols.first + 1)}–'
        '${_siteFormat.format(window.start + cols.last)} of '
        '${_siteFormat.format(data.length)} · Ctrl or Cmd + scroll to zoom';
  }
}
