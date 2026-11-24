//! Models shared by the GenBank and ENA services.

/// A public sequence archive SEGUI can search.
enum DatabaseSource {
  genBank('GenBank'),
  ena('ENA');

  const DatabaseSource(this.label);

  final String label;

  /// Whether the archive serves [content]. GenBank has no FASTQ files, and
  /// ENA has no protein sequences.
  bool serves(DownloadContent content) {
    return switch (this) {
      DatabaseSource.genBank => content != DownloadContent.reads,
      DatabaseSource.ena => content != DownloadContent.protein,
    };
  }
}

/// What a download holds.
enum DownloadContent {
  nucleotide('Whole record', 'FASTA'),
  coding('Coding sequence', 'FASTA'),
  protein('Protein', 'FASTA'),
  reads('Reads', 'FASTQ'),
  assembly('Assembly', 'FASTA');

  const DownloadContent(this.label, this.format);

  final String label;

  /// File format of the download.
  final String format;

  /// Whether records are written to FASTA with new sequence IDs. Reads and
  /// assemblies are saved as whole files.
  bool get isSequence => switch (this) {
        nucleotide || coding || protein => true,
        reads || assembly => false,
      };
}

/// How downloaded sequences are split into files.
enum SequenceGrouping {
  singleFile('One file'),
  perRecord('File per record');

  const SequenceGrouping(this.label);

  final String label;
}

/// How downloaded sequences are named.
enum SequenceNaming {
  speciesAccession('Species and accession'),
  accession('Accession');

  const SequenceNaming(this.label);

  final String label;
}

class DownloadOptions {
  const DownloadOptions({
    this.grouping = SequenceGrouping.singleFile,
    this.naming = SequenceNaming.speciesAccession,
    this.gene = '',
    this.fileName = '',
  });

  final SequenceGrouping grouping;
  final SequenceNaming naming;

  /// Keeps only coding sequences of this gene when not empty.
  final String gene;

  /// Name of the single file, without an extension.
  final String fileName;

  DownloadOptions copyWith({
    SequenceGrouping? grouping,
    SequenceNaming? naming,
    String? gene,
    String? fileName,
  }) {
    return DownloadOptions(
      grouping: grouping ?? this.grouping,
      naming: naming ?? this.naming,
      gene: gene ?? this.gene,
      fileName: fileName ?? this.fileName,
    );
  }
}

/// A file served by an archive.
class RemoteFile {
  const RemoteFile({required this.url, this.bytes, this.md5});

  final Uri url;
  final int? bytes;
  final String? md5;
}

class DatabaseRecord {
  const DatabaseRecord({
    required this.source,
    required this.content,
    required this.accession,
    this.organism = '',
    this.title = '',
    this.length,
    this.codonStart = 1,
    this.gene = '',
    this.files = const [],
  });

  final DatabaseSource source;
  final DownloadContent content;

  /// Accession, with its version when the archive gives one.
  final String accession;
  final String organism;
  final String title;

  /// Number of residues. Null for reads.
  final int? length;

  /// First base of the first full codon, starting at 1.
  final int codonStart;
  final String gene;

  /// Files to download, for reads and assemblies.
  final List<RemoteFile> files;

  DatabaseRecord withOrganism(String name) {
    return DatabaseRecord(
      source: source,
      content: content,
      accession: accession,
      organism: name,
      title: title,
      length: length,
      codonStart: codonStart,
      gene: gene,
      files: files,
    );
  }

  /// Identifies the record in a selection, whichever archive listed it.
  String get key => '${content.name}:${baseAccession(accession)}';

  /// Download size, or null when it is unknown. Plain FASTA is about a byte
  /// per residue, and the coding size is known only when ENA lists it.
  int? get estimatedBytes {
    if (files.isNotEmpty && files.every((file) => file.bytes != null)) {
      return files.fold<int>(0, (sum, file) => sum + file.bytes!);
    }
    if (content == DownloadContent.coding && source != DatabaseSource.ena) {
      return null;
    }
    return length;
  }
}

class DatabaseQuery {
  const DatabaseQuery({
    required this.content,
    this.organism = '',
    this.gene = '',
    this.keyword = '',
    this.minLength,
    this.maxLength,
    this.refSeqOnly = false,
  });

  final DownloadContent content;
  final String organism;
  final String gene;
  final String keyword;
  final int? minLength;
  final int? maxLength;
  final bool refSeqOnly;

  bool get hasTerms =>
      organism.trim().isNotEmpty ||
      gene.trim().isNotEmpty ||
      keyword.trim().isNotEmpty;
}

class DatabasePage {
  const DatabasePage({
    required this.records,
    required this.total,
    this.missing = const [],
    this.next,
  });

  static const DatabasePage empty = DatabasePage(records: [], total: 0);

  final List<DatabaseRecord> records;

  /// Number of records that match, which can exceed [records].
  final int total;

  /// Pasted accessions that were not found.
  final List<String> missing;

  /// Where the next page starts, or null on the last page.
  final PageCursor? next;
}

/// Position of the next result page.
class PageCursor {
  const PageCursor({
    required this.offset,
    this.total = 0,
    this.webEnv,
    this.queryKey,
    this.taxId,
  });

  final int offset;

  /// Number of records that match the search.
  final int total;

  /// NCBI history server session of the search.
  final String? webEnv;
  final String? queryKey;

  /// Cached ENA taxon ID for subsequent pages.
  final int? taxId;
}

/// A failure explained in words users can act on.
class DatabaseException implements Exception {
  const DatabaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DatabaseCancelled implements Exception {
  const DatabaseCancelled();

  @override
  String toString() => 'Stopped.';
}

/// [accession] without its version, in upper case.
String baseAccession(String accession) {
  return accession.trim().toUpperCase().replaceFirst(RegExp(r'\.\d+$'), '');
}

/// Version of [accession], or null when it has none.
int? accessionVersion(String accession) {
  final match = RegExp(r'\.(\d+)$').firstMatch(accession.trim());
  return match == null ? null : int.parse(match.group(1)!);
}

/// Whether [found] answers a request for [requested]. A request without a
/// version takes any version.
bool accessionMatches(String requested, String found) {
  if (baseAccession(requested) != baseAccession(found)) return false;
  final int? version = accessionVersion(requested);
  return version == null || version == accessionVersion(found);
}

/// Splits pasted accessions on commas, semicolons, and white space, and
/// drops repeats and anything that cannot be an accession.
({List<String> accessions, List<String> invalid}) parseAccessions(
  String text,
) {
  final Set<String> accessions = {};
  final Set<String> invalid = {};
  for (final String token in text.split(RegExp(r'[\s,;]+'))) {
    if (token.isEmpty) continue;
    if (RegExp(r'^[A-Za-z0-9_]{3,30}(\.\d{1,4})?$').hasMatch(token) &&
        token.contains(RegExp(r'\d'))) {
      accessions.add(token.toUpperCase());
    } else {
      invalid.add(token);
    }
  }
  return (accessions: accessions.toList(), invalid: invalid.toList());
}

/// [items] in lists of at most [size].
Iterable<List<T>> batches<T>(List<T> items, int size) sync* {
  for (int i = 0; i < items.length; i += size) {
    yield items.sublist(i, i + size > items.length ? items.length : i + size);
  }
}
