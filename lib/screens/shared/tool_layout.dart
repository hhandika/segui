import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/illustrations.dart';
import 'package:segui/screens/shared/io/input_view.dart';
import 'package:segui/screens/shared/io/output_view.dart';
import 'package:segui/screens/shared/io/summary_view.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/styles/decoration.dart';

/// Widest the tool form, header, and action bar grow before centering.
const double maxToolFormWidth = 760;

/// Page width that fits the tool list, the form, and the file panel.
const double toolListPageWidth = 1180;

const double toolListWidth = 280;

/// Space the tool form needs: its widest size plus side padding.
const double _toolFormSpace = maxToolFormWidth + 64;

/// Hover delay before a tool's full description shows.
const Duration _descriptionDelay = Duration(milliseconds: 400);

/// Widest a tool description tooltip grows before wrapping.
const double _descriptionMaxWidth = 360;

/// Width of the file panel next to the tool form.
///
/// The panel starts at [minFilePanelWidth] and takes any space the form
/// does not need, up to [maxFilePanelWidth].
const double minFilePanelWidth = 340;
const double maxFilePanelWidth = 640;

double filePanelWidth(double pageWidth, {required bool hasToolList}) {
  final double used = hasToolList ? toolListWidth : 0;
  return (pageWidth - used - _toolFormSpace)
      .clamp(minFilePanelWidth, maxFilePanelWidth);
}

/// Narrowest run bar that fits the summary and buttons on one row.
const double _runBarRowWidth = 320;

/// Side list of every tool in one category, used to switch tools.
class ToolListPanel extends StatelessWidget {
  const ToolListPanel({
    super.key,
    required this.category,
    required this.selected,
  });

  final ToolCategory category;
  final HomeTool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<HomeTool> tools = filterHomeTools(category, '');
    return Container(
      width: toolListWidth,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(right: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
            child: Text(
              category.label,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              '${tools.length} tools',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              children: [
                for (final tool in tools)
                  ToolListTile(
                    tool: tool,
                    isSelected: tool == selected,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One tool in [ToolListPanel] or the tool switcher sheet.
class ToolListTile extends ConsumerWidget {
  const ToolListTile({
    super.key,
    required this.tool,
    required this.isSelected,
    this.onOpened,
  });

  final HomeTool tool;
  final bool isSelected;

  /// Called after the tool opens, such as to close a sheet.
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ToolDescriptionTooltip(
      tool: tool,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color:
              isSelected ? colors.surfaceContainerLowest : Colors.transparent,
          elevation: isSelected ? 1 : 0,
          shadowColor: colors.shadow.withAlpha(60),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (!isSelected) {
                ref.read(homeToolNavigatorProvider).open(tool);
              }
              onOpened?.call();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  ToolIconTile(tool: tool, isSelected: isSelected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          tool.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
}

/// Shows the tool's full description when [child] is hovered or held.
class ToolDescriptionTooltip extends StatelessWidget {
  const ToolDescriptionTooltip({
    super.key,
    required this.tool,
    required this.child,
  });

  final HomeTool tool;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tool.about,
      waitDuration: _descriptionDelay,
      constraints: const BoxConstraints(maxWidth: _descriptionMaxWidth),
      child: child,
    );
  }
}

/// Tool font icon on a rounded tile, highlighted when [isSelected].
class ToolIconTile extends StatelessWidget {
  const ToolIconTile({
    super.key,
    required this.tool,
    required this.isSelected,
    this.size = 36,
  });

  final HomeTool tool;
  final bool isSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Icon(
        tool.icon,
        size: size * 0.55,
        color: isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
      ),
    );
  }
}

/// Title and explanation above the tool form.
///
/// When the tool list is hidden, the title opens a tool switcher. On compact
/// screens a files button opens the input and output files.
class ToolHeader extends StatelessWidget {
  const ToolHeader({
    super.key,
    required this.tool,
    required this.showSwitcher,
    required this.isCompact,
  });

  final HomeTool tool;
  final bool showSwitcher;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? titleStyle =
        (isCompact ? textTheme.titleLarge : textTheme.headlineSmall)
            ?.copyWith(fontWeight: FontWeight.w700);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 32,
        isCompact ? 12 : 28,
        isCompact ? 8 : 32,
        isCompact ? 4 : 8,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxToolFormWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: showSwitcher
                        ? ToolSwitcherButton(tool: tool, style: titleStyle)
                        : Text(tool.title, style: titleStyle),
                  ),
                  if (isCompact) const FilesButton(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tool.about,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: isCompact ? 2 : null,
                overflow: isCompact ? TextOverflow.ellipsis : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tool title that opens a sheet listing the other tools in its category.
class ToolSwitcherButton extends StatelessWidget {
  const ToolSwitcherButton({super.key, required this.tool, this.style});

  final HomeTool tool;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: 'Switch tool',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showResponsiveSheet(
            context: context,
            builder: (context) => ToolSwitcherSheet(tool: tool),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    tool.title,
                    style: style,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ToolSwitcherSheet extends StatelessWidget {
  const ToolSwitcherSheet({super.key, required this.tool});

  final HomeTool tool;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        // Sheets have a drag handle above; dialogs need their own top space.
        padding:
            EdgeInsets.fromLTRB(12, isPhoneScreen(context) ? 0 : 20, 12, 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              tool.category.label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final other in filterHomeTools(tool.category, ''))
            ToolListTile(
              tool: other,
              isSelected: other == tool,
              onOpened: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

/// Opens the input and output files on compact screens.
class FilesButton extends ConsumerWidget {
  const FilesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int inputCount = ref.watch(fileInputProvider).value?.length ?? 0;
    return IconButton(
      tooltip: 'Input and output files',
      icon: Badge(
        isLabelVisible: inputCount > 0,
        label: Text('$inputCount'),
        child: const Icon(Icons.folder_open_outlined),
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const FilesPage()),
      ),
    );
  }
}

class FilesPage extends StatelessWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Files')),
      body: const SafeArea(child: FilePanel()),
    );
  }
}

/// Input and output summary and file lists, switched with a segmented
/// control.
class FilePanel extends ConsumerWidget {
  const FilePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int inputCount = ref.watch(fileInputProvider).value?.length ?? 0;
    final int outputCount = ref
            .watch(fileOutputProvider)
            .value
            ?.files
            .where((file) => file.isNew)
            .length ??
        0;
    final FilePanelView view = ref.watch(filePanelViewProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<FilePanelView>(
            showSelectedIcon: false,
            segments: [
              const ButtonSegment(
                value: FilePanelView.summary,
                label: Text('Summary'),
              ),
              ButtonSegment(
                value: FilePanelView.input,
                label: Text('Input · $inputCount'),
              ),
              ButtonSegment(
                value: FilePanelView.output,
                label: Text('Output · $outputCount'),
              ),
            ],
            selected: {view},
            onSelectionChanged: (value) {
              ref.read(filePanelViewProvider.notifier).show(value.first);
            },
          ),
          Expanded(
            child: IndexedStack(
              index: view.index,
              sizing: StackFit.expand,
              children: const [
                FileSummaryView(),
                InputScreen(),
                OutputScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Side panel that holds [FilePanel] on wide screens.
class FileSidePanel extends StatelessWidget {
  const FileSidePanel({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    // Material paints the background so file tiles keep their ink splashes.
    return Material(
      color: colors.surfaceContainerLow,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: colors.outlineVariant)),
        ),
        child: const FilePanel(),
      ),
    );
  }
}

/// Scrolling tool form with a run bar pinned below it.
///
/// [form] holds the input and output sections; [action] is the execution
/// button shown in the run bar.
class ToolFormLayout extends StatelessWidget {
  const ToolFormLayout({
    super.key,
    required this.form,
    required this.action,
  });

  final List<Widget> form;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = isPhoneScreen(context);
    final double sidePadding = isCompact ? 16 : 32;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                // Fill the height so the gull scene sits on the run bar
                // when the form is short.
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: maxToolFormWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: form,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: ToolScene(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        ToolRunBar(action: action),
      ],
    );
  }
}

/// Bottom bar that summarizes the run and holds the execution button.
class ToolRunBar extends StatelessWidget {
  const ToolRunBar({super.key, required this.action});

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isCompact = isPhoneScreen(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 32,
          vertical: 12,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxToolFormWidth),
            child: LayoutBuilder(builder: (context, constraints) {
              // Stack the summary over the buttons when they cannot share
              // a row, so the success buttons can wrap.
              if (constraints.maxWidth < _runBarRowWidth) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const RunSummary(),
                    if (action != null) ...[
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: action),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(child: RunSummary()),
                  const SizedBox(width: 12),
                  if (action != null) action!,
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Counts the selected input files and names the output directory.
class RunSummary extends ConsumerWidget {
  const RunSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int inputCount = ref.watch(fileInputProvider).value?.length ?? 0;
    final String? outputDir =
        ref.watch(fileOutputProvider).value?.directory?.path;
    final String inputLabel = switch (inputCount) {
      0 => 'No input files',
      1 => '1 input file',
      _ => '$inputCount input files',
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          inputLabel,
          style: textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          outputDir == null
              ? 'Output folder not selected'
              : 'Saving to ${p.basename(outputDir)}',
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
