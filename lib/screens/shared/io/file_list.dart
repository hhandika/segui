import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/design_tokens.dart';

/// Files shown at first and added by each "Show more".
const int fileListPageSize = 20;

/// Scrolling list that shows [fileListPageSize] items at a time, with
/// buttons to show more or all of the rest.
class PagedFileList extends StatefulWidget {
  const PagedFileList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;

  @override
  State<PagedFileList> createState() => _PagedFileListState();
}

class _PagedFileListState extends State<PagedFileList> {
  int _visibleCount = fileListPageSize;

  @override
  Widget build(BuildContext context) {
    final int shown = math.min(_visibleCount, widget.itemCount);
    final int remaining = widget.itemCount - shown;
    return ListView.builder(
      padding: widget.padding,
      itemCount: shown + (remaining > 0 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < shown) {
          return widget.itemBuilder(context, index);
        }
        return ShowMoreFilesButtons(
          remaining: remaining,
          onShowMore: () => setState(() {
            _visibleCount += fileListPageSize;
          }),
          onShowAll: () => setState(() {
            _visibleCount = widget.itemCount;
          }),
        );
      },
    );
  }
}

class ShowMoreFilesButtons extends StatelessWidget {
  const ShowMoreFilesButtons({
    super.key,
    required this.remaining,
    required this.onShowMore,
    required this.onShowAll,
  });

  final int remaining;
  final VoidCallback onShowMore;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final int nextCount = math.min(remaining, fileListPageSize);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SeguiSpacing.md),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: SeguiSpacing.md,
        children: [
          TextButton.icon(
            onPressed: onShowMore,
            icon: const Icon(Icons.expand_more_rounded),
            label: Text('Show $nextCount more'),
          ),
          if (remaining > fileListPageSize)
            TextButton(
              onPressed: onShowAll,
              child: Text('Show all $remaining'),
            ),
        ],
      ),
    );
  }
}

/// File type icon on a small rounded tile for file list rows.
class FileIconTile extends StatelessWidget {
  const FileIconTile({super.key, required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SeguiControlSize.avatar,
      height: SeguiControlSize.avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(SeguiRadius.md),
      ),
      child: icon,
    );
  }
}
