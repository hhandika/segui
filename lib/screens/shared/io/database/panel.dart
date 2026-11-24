import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/io/database/download_status.dart';
import 'package:segui/screens/shared/io/database/footer.dart';
import 'package:segui/screens/shared/io/database/options.dart';
import 'package:segui/screens/shared/io/database/result_list.dart';
import 'package:segui/screens/shared/io/database/search_fields.dart';
import 'package:segui/services/databases/compatibility.dart';
import 'package:segui/services/databases/download.dart';
import 'package:segui/services/databases/types.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/providers/databases.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

const Duration _slideDuration = Duration(milliseconds: 250);

/// Opens the database search beside the tool, or over it on phones. The
/// panel adds its downloads to the inputs and returns them.
Future<CompletedDownload?> showDatabasePanel(
  BuildContext context, {
  required SupportedTask task,
  required XTypeGroup group,
  required bool allowMultiple,
}) {
  final bool isStill = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<CompletedDownload>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close database search',
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.32),
    transitionDuration: isStill ? Duration.zero : _slideDuration,
    pageBuilder: (context, _, __) => DatabasePanel(
      target: (task: task, group: group),
      allowMultiple: allowMultiple,
    ),
    transitionBuilder: (context, animation, _, child) => SlideTransition(
      position: animation
          .drive(CurveTween(curve: Curves.easeOutCubic))
          .drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
      child: child,
    ),
  );
}

class DatabasePanel extends ConsumerStatefulWidget {
  const DatabasePanel({
    super.key,
    required this.target,
    required this.allowMultiple,
  });

  final DatabaseTarget target;

  /// Whether the picker takes more than one file.
  final bool allowMultiple;

  @override
  ConsumerState<DatabasePanel> createState() => DatabasePanelState();
}

class DatabasePanelState extends ConsumerState<DatabasePanel> {
  final DatabaseSearchInput _input = DatabaseSearchInput();
  bool _isWorking = false;
  bool _isAdding = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseState state = ref.watch(_provider);
    final bool isPhone = isPhoneScreen(context);
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: isPhone ? double.infinity : SeguiContentWidth.databasePanel,
        height: double.infinity,
        child: PopScope(
          // Closing would throw the download away. Stop it first.
          canPop: !state.isDownloading && !_isAdding,
          child: ClipRRect(
            borderRadius: isPhone
                ? BorderRadius.zero
                : const BorderRadius.horizontal(
                    left: Radius.circular(SeguiRadius.lg),
                  ),
            child: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: SafeArea(
                child: FormFieldTheme(
                  child: Column(
                    children: [
                      DatabasePanelHeader(
                        target: widget.target,
                        content: state.content,
                        canClose: !state.isDownloading,
                      ),
                      Expanded(
                        child: switch (state) {
                          DatabaseState(isDownloading: true) => DownloadingList(
                              records: state.selection,
                              statuses: state.progress?.statuses ?? const {},
                            ),
                          DatabaseState(:final report?) =>
                            DownloadFailureList(report: report),
                          _ => DatabaseBrowser(
                              target: widget.target,
                              input: _input,
                              allowMultiple: widget.allowMultiple,
                            ),
                        },
                      ),
                      DatabasePanelFooter(
                        target: widget.target,
                        onDownload: _download,
                        onRetry: () => _finish(_session.retry),
                        onAddRest: () => _finish(_session.addRest),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  NotifierProvider<DatabaseSession, DatabaseState> get _provider =>
      databaseSessionProvider(widget.target);

  DatabaseSession get _session => ref.read(_provider.notifier);

  Future<void> _download() async {
    final DatabaseState state = ref.read(_provider);
    final int? bytes = state.selectionBytes;
    if (bytes != null && bytes > largeDownloadBytes) {
      final bool? isConfirmed = await showResponsiveSheet<bool>(
        context: context,
        builder: (context) => LargeDownloadAlert(bytes: bytes),
      );
      if (isConfirmed != true || !mounted) return;
    }
    // A single-file picker replaces its file, so no name is taken.
    final Set<String> takenNames = widget.allowMultiple
        ? _currentFiles.map((file) => inputStem(file.path)).toSet()
        : const {};
    await _finish(() => _session.download(takenNames: takenNames));
  }

  /// Adds what [work] downloads, then closes the panel.
  Future<void> _finish(Future<CompletedDownload?> Function() work) async {
    // A second tap must not commit the same files again.
    if (_isWorking) return;
    _isWorking = true;
    final CompletedDownload? completed = await work();
    _isWorking = false;
    if (completed == null || !mounted) return;
    _isWorking = true;
    setState(() => _isAdding = true);
    // Added here, as the picker below can rebuild when the window resizes.
    await FileInputServices(
      ref,
      allowedExtension: widget.target.group,
      allowMultiple: widget.allowMultiple,
    ).addDownloaded(completed.files, _currentFiles);
    if (mounted) Navigator.of(context).pop(completed);
  }

  List<File> get _currentFiles {
    final SegulType type = matchTypeByXTypeGroup(widget.target.group);
    return [
      for (final input
          in ref.read(fileInputProvider).value ?? const <SegulInputFile>[])
        if (input.type == type) input.file,
    ];
  }
}

/// Names the tool and the format it receives.
class DatabasePanelHeader extends ConsumerWidget {
  const DatabasePanelHeader({
    super.key,
    required this.target,
    required this.content,
    required this.canClose,
  });

  final DatabaseTarget target;
  final DownloadContent content;
  final bool canClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String? tool = ref.watch(currentToolProvider)?.title;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SeguiSpacing.xl,
        SeguiSpacing.lg,
        SeguiSpacing.md,
        SeguiSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search databases',
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  [
                    if (tool != null) tool,
                    '${content.label} as ${content.format}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: canClose ? () => Navigator.of(context).maybePop() : null,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

/// Search fields, options, and results in one scroll view, so short windows
/// and open keyboards still reach all of them.
class DatabaseBrowser extends ConsumerStatefulWidget {
  const DatabaseBrowser({
    super.key,
    required this.target,
    required this.input,
    required this.allowMultiple,
  });

  final DatabaseTarget target;
  final DatabaseSearchInput input;
  final bool allowMultiple;

  @override
  ConsumerState<DatabaseBrowser> createState() => DatabaseBrowserState();
}

class DatabaseBrowserState extends ConsumerState<DatabaseBrowser> {
  final GlobalKey _resultsStart = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final DatabaseTarget target = widget.target;
    final DatabaseSearchInput input = widget.input;
    final bool allowMultiple = widget.allowMultiple;
    final DatabaseState state = ref.watch(databaseSessionProvider(target));
    ref.listen(databaseSessionProvider(target), _revealResults);
    final support =
        databaseSupportFor(target.task, target.group) as DatabaseAvailable;
    final bool hasRecords =
        state.page.records.isNotEmpty || state.selection.isNotEmpty;
    final bool hasOptions = state.content.isSequence && hasRecords;
    final bool hasFolder =
        hasRecords && runningPlatform == PlatformType.isDesktop;
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(SeguiSpacing.lg),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: DatabaseSearchFields(
                  target: target,
                  support: support,
                  input: input,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(key: _resultsStart, width: double.infinity),
              ),
              if (hasOptions)
                SliverToBoxAdapter(
                  child: DatabaseDownloadOptions(
                    target: target,
                    input: input,
                    allowMultiple: allowMultiple,
                  ),
                ),
              if (hasFolder)
                const SliverToBoxAdapter(child: DownloadFolderTile()),
              DatabaseResults(target: target),
            ],
          ),
        ),
      ],
    );
  }

  /// Scrolls to what a new search found, which the fields push out of view.
  /// More results of the same search stay where they are.
  void _revealResults(DatabaseState? previous, DatabaseState next) {
    if (previous == null || next.isSearching) return;
    final bool isFailed = next.error != null && previous.error != next.error;
    final bool isFound = !previous.hasSearched && next.hasSearched;
    if (!isFailed && !isFound) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? start = _resultsStart.currentContext;
      if (!mounted || start == null) return;
      Scrollable.ensureVisible(
        start,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : _slideDuration,
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class LargeDownloadAlert extends StatelessWidget {
  const LargeDownloadAlert({super.key, required this.bytes});

  final int bytes;

  @override
  Widget build(BuildContext context) {
    final String size = FileUtils().formatSize(bytes);
    return SheetContent(
      title: 'Download $size?',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Download'),
        ),
      ],
      child: const Text('Use Wi-Fi and check your free storage.'),
    );
  }
}
