import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/services/databases/types.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/providers/databases.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/design_tokens.dart';

/// The records found, as a sliver so long lists build only what shows.
class DatabaseResults extends ConsumerWidget {
  const DatabaseResults({super.key, required this.target});

  final DatabaseTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DatabaseState state = ref.watch(databaseSessionProvider(target));
    final DatabaseSession session =
        ref.read(databaseSessionProvider(target).notifier);
    final DatabasePage page = state.page;
    final List<DatabaseRecord> records = page.records;
    return SliverMainAxisGroup(
      slivers: [
        if (state.error case final String error)
          SliverToBoxAdapter(
            child: DatabaseNotice(message: error, isError: true),
          ),
        if (page.missing.isNotEmpty)
          SliverToBoxAdapter(
            child: DatabaseNotice(
              message: 'Not found in ${state.source.label}: '
                  '${page.missing.join(', ')}',
              isError: true,
            ),
          ),
        if (state.isSearching && records.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(SeguiSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        if (state.hasSearched &&
            !state.isSearching &&
            records.isEmpty &&
            state.error == null)
          const SliverToBoxAdapter(
            child: EmptyScreen(
              title: 'No records found.',
              description: 'Try fewer terms or another database.',
            ),
          ),
        if (records.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: DatabaseResultsHeader(target: target),
          ),
          SliverList.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final DatabaseRecord record = records[index];
              final bool canSelect = session.canSelect(record);
              return DatabaseRecordTile(
                key: ValueKey(record.key),
                record: record,
                isSelected: state.selected.containsKey(record.key),
                onToggle: canSelect ? () => session.toggle(record) : null,
              );
            },
          ),
          if (page.next != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: SeguiSpacing.md),
                child: Center(
                  child: state.isSearching
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: session.loadMore,
                          child: const Text('Show more'),
                        ),
                ),
              ),
            )
          else if (page.total > records.length)
            const SliverToBoxAdapter(
              child: DatabaseNotice(
                message: 'Refine the search to see other records.',
              ),
            ),
        ],
      ],
    );
  }
}

/// How many records match, with a button to select those shown.
class DatabaseResultsHeader extends ConsumerWidget {
  const DatabaseResultsHeader({super.key, required this.target});

  final DatabaseTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DatabaseState state = ref.watch(databaseSessionProvider(target));
    final DatabaseSession session =
        ref.read(databaseSessionProvider(target).notifier);
    final int shown = state.page.records.length;
    final int total = state.page.total;
    final bool isAllSelected = state.page.records
        .where(session.canSelect)
        .every((record) => state.selected.containsKey(record.key));
    return Padding(
      padding: const EdgeInsets.only(
        top: SeguiSpacing.md,
        left: SeguiSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              total > shown
                  ? '${formatCount(shown)} of ${formatCount(total)} records'
                  : '${formatCount(shown)} ${shown == 1 ? 'record' : 'records'}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          TextButton(
            onPressed: () => session.selectShown(!isAllSelected),
            child: Text(isAllSelected ? 'Deselect shown' : 'Select shown'),
          ),
        ],
      ),
    );
  }
}

class DatabaseRecordTile extends StatelessWidget {
  const DatabaseRecordTile({
    super.key,
    required this.record,
    required this.isSelected,
    required this.onToggle,
  });

  final DatabaseRecord record;
  final bool isSelected;

  /// Null when the record has nothing to download.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasOrganism = record.organism.isNotEmpty;
    // Material, so the ink shows over the panel.
    return Material(
      type: MaterialType.transparency,
      child: CheckboxListTile(
        value: isSelected,
        enabled: onToggle != null,
        onChanged: onToggle == null ? null : (_) => onToggle!(),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: Text(
          hasOrganism ? record.organism : record.accession,
          style: theme.textTheme.titleSmall?.copyWith(
            fontStyle: hasOrganism ? FontStyle.italic : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            [
              if (hasOrganism) record.accession,
              _size,
            ].where((part) => part.isNotEmpty).join(' · '),
            if (record.title.isNotEmpty) record.title,
          ].join('\n'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  String get _size {
    if (onToggle == null) return 'No files to download';
    if (record.content == DownloadContent.reads) {
      final int? bytes = record.estimatedBytes;
      final int count = record.files.length;
      return [
        count == 1 ? '1 file' : '$count files',
        if (bytes != null) FileUtils().formatSize(bytes),
      ].join(' · ');
    }
    final int? length = record.length;
    if (length == null) return '';
    final String unit = record.content == DownloadContent.protein ? 'aa' : 'bp';
    // GenBank lists the whole record, whose coding sequences are cut later.
    final bool isWholeRecord = record.content == DownloadContent.coding &&
        record.source == DatabaseSource.genBank;
    return '${formatCount(length)} $unit${isWholeRecord ? ' record' : ''}';
  }
}

/// A short message above or below the results.
class DatabaseNotice extends StatelessWidget {
  const DatabaseNotice({
    super.key,
    required this.message,
    this.isError = false,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SeguiSpacing.xs,
        vertical: SeguiSpacing.md,
      ),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isError
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
