//! What each tool can take from GenBank and ENA.

import 'package:file_selector/file_selector.dart';
import 'package:segui/services/databases/types.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/io.dart';

sealed class DatabaseSupport {
  const DatabaseSupport();
}

/// The tool can read downloads of [contents].
class DatabaseAvailable extends DatabaseSupport {
  const DatabaseAvailable(this.contents, {this.trimsToFrame = false});

  /// Contents the tool reads, the default first.
  final List<DownloadContent> contents;

  /// Whether coding sequences are trimmed to their first full codon.
  final bool trimsToFrame;

  List<DatabaseSource> get sources => [
        for (final source in DatabaseSource.values)
          if (contents.any(source.serves)) source,
      ];

  List<DownloadContent> contentsOf(DatabaseSource source) =>
      contents.where(source.serves).toList();
}

/// The archives have nothing the tool can read, for a [reason] worth showing.
class DatabaseUnavailable extends DatabaseSupport {
  const DatabaseUnavailable(this.reason);

  final String reason;
}

/// The picker has nothing to do with the archives.
class DatabaseNotOffered extends DatabaseSupport {
  const DatabaseNotOffered();
}

const DatabaseAvailable _anySequence = DatabaseAvailable([
  DownloadContent.nucleotide,
  DownloadContent.coding,
  DownloadContent.protein,
]);

const DatabaseAvailable _translation = DatabaseAvailable(
  [DownloadContent.coding],
  trimsToFrame: true,
);

const DatabaseAvailable _reads = DatabaseAvailable([DownloadContent.reads]);

const DatabaseAvailable _assemblies =
    DatabaseAvailable([DownloadContent.assembly]);

const DatabaseUnavailable needsAlignment = DatabaseUnavailable(
  'Needs aligned sequences, so there is no database search.',
);

const DatabaseNotOffered _notOffered = DatabaseNotOffered();

/// Database support of [task]'s picker for [group].
///
/// SEGUL checks that inputs are aligned for the tools that get
/// [needsAlignment], and stops on the unaligned records archives serve.
/// Secondary pickers, such as ID lists and partitions, get nothing.
DatabaseSupport databaseSupportFor(SupportedTask task, XTypeGroup group) {
  return switch (task) {
    SupportedTask.sequenceTranslation =>
      group == sequenceTypeGroup ? _translation : _notOffered,
    SupportedTask.sequenceAddition =>
      group == sequenceTypeGroup || group == destinationSequenceTypeGroup
          ? _anySequence
          : _notOffered,
    SupportedTask.sequenceExtraction ||
    SupportedTask.sequenceRemoval ||
    SupportedTask.sequenceRenaming ||
    SupportedTask.sequenceUniqueId ||
    SupportedTask.sequenceFiltering ||
    SupportedTask.sequenceTransposition ||
    SupportedTask.alignmentConversion =>
      group == sequenceTypeGroup ? _anySequence : _notOffered,
    SupportedTask.genomicRawReadSummary =>
      group == genomicRawReadTypeGroup ? _reads : _notOffered,
    SupportedTask.genomicContigSummary =>
      group == genomicContigTypeGroup ? _assemblies : _notOffered,
    SupportedTask.alignmentConcatenation ||
    SupportedTask.alignmentSummary ||
    SupportedTask.alignmentFiltering ||
    SupportedTask.alignmentSplitting ||
    SupportedTask.alignmentDistance ||
    SupportedTask.alignmentTrimming ||
    SupportedTask.alignmentUnalignment =>
      group == sequenceTypeGroup ? needsAlignment : _notOffered,
    SupportedTask.partitionConversion ||
    SupportedTask.genomicMafConversion ||
    SupportedTask.genomicMafSummary ||
    SupportedTask.treeConversion =>
      _notOffered,
  };
}
