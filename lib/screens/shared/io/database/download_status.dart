import 'package:material_ui/material_ui.dart';
import 'package:segui/services/databases/download.dart';
import 'package:segui/services/databases/types.dart';
import 'package:segui/styles/design_tokens.dart';

/// The records being downloaded, in place of the search.
class DownloadingList extends StatelessWidget {
  const DownloadingList({
    super.key,
    required this.records,
    this.statuses = const {},
  });

  final List<DatabaseRecord> records;
  final Map<String, RecordDownloadStatus> statuses;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(SeguiSpacing.md),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final DatabaseRecord record = records[index];
        final RecordDownloadStatus status =
            statuses[record.key] ?? RecordDownloadStatus.pending;
        return ListTile(
          leading: DownloadRecordStatusIcon(status: status),
          title: Text(record.accession),
          subtitle: record.organism.isEmpty
              ? null
              : Text(
                  record.organism,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
        );
      },
    );
  }
}

/// Leading indicator for a record's current download state.
class DownloadRecordStatusIcon extends StatelessWidget {
  const DownloadRecordStatusIcon({super.key, required this.status});

  final RecordDownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return switch (status) {
      RecordDownloadStatus.pending => Icon(
          Icons.schedule_rounded,
          color: colors.onSurfaceVariant,
        ),
      RecordDownloadStatus.active => const SizedBox.square(
          dimension: SeguiControlSize.iconMedium,
          child: CircularProgressIndicator(strokeWidth: SeguiStroke.regular),
        ),
      RecordDownloadStatus.done => Icon(
          Icons.check_circle_outline_rounded,
          color: colors.primary,
        ),
      RecordDownloadStatus.failed => Icon(
          Icons.error_outline_rounded,
          color: colors.error,
        ),
    };
  }
}

/// The records that failed, each with the reason.
class DownloadFailureList extends StatelessWidget {
  const DownloadFailureList({super.key, required this.report});

  final DownloadReport report;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<DownloadFailure> failures = report.failures;
    return ListView.builder(
      padding: const EdgeInsets.all(SeguiSpacing.md),
      itemCount: failures.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            title: Text(
              failures.length == 1
                  ? '1 record was not downloaded'
                  : '${failures.length} records were not downloaded',
              style: theme.textTheme.titleMedium,
            ),
          );
        }
        final DownloadFailure failure = failures[index - 1];
        return ListTile(
          leading: Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
          ),
          title: Text(failure.record.accession),
          subtitle: Text(failure.reason),
        );
      },
    );
  }
}
