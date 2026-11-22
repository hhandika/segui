import 'package:material_ui/material_ui.dart';
import 'package:segui/services/databases/download.dart';
import 'package:segui/services/databases/types.dart';
import 'package:segui/styles/design_tokens.dart';

/// The records being downloaded, in place of the search.
class DownloadingList extends StatelessWidget {
  const DownloadingList({super.key, required this.records});

  final List<DatabaseRecord> records;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(SeguiSpacing.md),
      itemCount: records.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(records[index].accession),
        subtitle: records[index].organism.isEmpty
            ? null
            : Text(
                records[index].organism,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
      ),
    );
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
