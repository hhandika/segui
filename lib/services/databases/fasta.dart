//! Prepares archive FASTA as SEGUL input.
//!
//! SEGUL takes the whole header as the sequence ID and stops on repeated
//! IDs, so headers are always rewritten.

import 'dart:convert';
import 'dart:io';

import 'package:segui/services/databases/archive.dart';
import 'package:segui/services/databases/client.dart';
import 'package:segui/services/databases/types.dart';

// The residues SEGUL accepts for DNA and for amino acids.
final RegExp _notDna = RegExp(r'[^?\-ACGTRYSWKMBDHVNacgtryswkmbdhvn.]');
final RegExp _notAminoAcid = RegExp(r'[^?\-ARNDCQEGHILKMFPSTWYVXBZJU*.~]');
final RegExp _notSequence = RegExp(r'[^A-Za-z*.~?\-]');

/// A sequence written by [FastaPreparer].
class PreparedSequence {
  const PreparedSequence({
    required this.record,
    required this.id,
    required this.header,
    required this.trimmed,
  });

  final DatabaseRecord record;
  final String id;

  /// The header the archive gave.
  final String header;

  /// Bases removed before the first full codon.
  final int trimmed;
}

class PreparedBatch {
  const PreparedBatch({
    required this.sequences,
    required this.hasUnknownResidues,
  });

  final List<PreparedSequence> sequences;

  /// Whether a residue is outside the alphabet SEGUL checks.
  final bool hasUnknownResidues;
}

/// Streams archive FASTA into SEGUL FASTA with safe, unique IDs.
class FastaPreparer {
  const FastaPreparer({
    required this.archive,
    required this.options,
    required this.trimsToFrame,
  });

  final SequenceArchive archive;
  final DownloadOptions options;

  /// Whether coding sequences start at their first full codon.
  final bool trimsToFrame;

  static const int _flushBytes = 1 << 16;

  /// Writes the sequences of [records] found in [raw] to the files
  /// [outputFor] gives, adding to what those files hold.
  ///
  /// [usedIds] gains the new IDs. Throws when [raw] is not FASTA, such as
  /// the errors NCBI sends with a success status.
  Future<PreparedBatch> prepare(
    File raw,
    List<DatabaseRecord> records, {
    required File Function(DatabaseRecord record) outputFor,
    required Set<String> usedIds,
    CancelToken? cancel,
  }) async {
    final Map<String, DatabaseRecord> wanted = {
      for (final record in records) baseAccession(record.accession): record,
    };
    final List<PreparedSequence> sequences = [];
    final StringBuffer buffer = StringBuffer();
    bool hasUnknownResidues = false;
    bool hasHeader = false;
    IOSink? sink;
    String? sinkPath;
    // The ID waits for the first residue, so empty sequences are left out.
    PreparedSequence? current;
    bool isWritten = false;
    int toTrim = 0;

    Future<void> flush() async {
      if (sink != null && buffer.isNotEmpty) {
        sink.write(buffer.toString());
        await sink.flush();
      }
      buffer.clear();
    }

    try {
      await for (final String rawLine in raw
          .openRead()
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())) {
        final String line = rawLine.trim();
        if (line.isEmpty) continue;
        cancel?.throwIfCancelled();
        if (line.startsWith('>')) {
          hasHeader = true;
          current = null;
          isWritten = false;
          final String header = line.substring(1).trim();
          final FastaOrigin origin = archive.readHeader(header);
          final record = wanted[baseAccession(origin.accession)];
          if (record == null ||
              !accessionMatches(record.accession, origin.accession) ||
              !_matchesGene(record, origin)) {
            continue;
          }
          toTrim = trimsToFrame && record.content == DownloadContent.coding
              ? ((origin.codonStart ?? record.codonStart) - 1).clamp(0, 2)
              : 0;
          current = PreparedSequence(
            record: record,
            id: _baseId(record, origin),
            header: header,
            trimmed: toTrim,
          );
          continue;
        }
        if (!hasHeader || _notSequence.hasMatch(line)) {
          throw DatabaseException(
            '${archive.source.label} sent an error instead of sequences. '
            'Try again.',
          );
        }
        final PreparedSequence? sequence = current;
        if (sequence == null) continue;
        String residues = line;
        if (toTrim > 0) {
          final int cut = toTrim < line.length ? toTrim : line.length;
          toTrim -= cut;
          residues = line.substring(cut);
          if (residues.isEmpty) continue;
        }
        if (!isWritten) {
          isWritten = true;
          final File output = outputFor(sequence.record);
          if (sinkPath != output.path) {
            await flush();
            await sink?.close();
            sink = output.openWrite(mode: FileMode.append);
            sinkPath = output.path;
          }
          final String id = _unique(sequence.id, usedIds);
          sequences.add(PreparedSequence(
            record: sequence.record,
            id: id,
            header: sequence.header,
            trimmed: sequence.trimmed,
          ));
          buffer.writeln('>$id');
        }
        final RegExp invalid =
            sequence.record.content == DownloadContent.protein
                ? _notAminoAcid
                : _notDna;
        hasUnknownResidues = hasUnknownResidues || invalid.hasMatch(residues);
        buffer.writeln(residues);
        if (buffer.length >= _flushBytes) await flush();
      }
      await flush();
    } finally {
      await sink?.close();
    }
    return PreparedBatch(
      sequences: sequences,
      hasUnknownResidues: hasUnknownResidues,
    );
  }

  bool _matchesGene(DatabaseRecord record, FastaOrigin origin) {
    if (record.content != DownloadContent.coding) return true;
    final String wanted = _geneKey(options.gene);
    if (wanted.isEmpty) return true;
    final String gene = origin.gene.isNotEmpty ? origin.gene : record.gene;
    return _geneKey(gene) == wanted || _geneKey(origin.product) == wanted;
  }

  // CYTB, cytb, and cyt-b are the same gene.
  String _geneKey(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');

  String _baseId(DatabaseRecord record, FastaOrigin origin) {
    // A GenBank record can hold many coding sequences.
    final String part = record.content == DownloadContent.coding &&
            record.source == DatabaseSource.genBank &&
            options.gene.trim().isEmpty
        ? (origin.gene.isNotEmpty ? origin.gene : origin.product)
        : '';
    return safeName([
      if (options.naming == SequenceNaming.speciesAccession) record.organism,
      origin.accession,
      part,
    ].where((value) => value.isNotEmpty).join('_'));
  }

  String _unique(String id, Set<String> used) {
    String unique = id;
    for (int i = 2; !used.add(unique); i++) {
      unique = '${id}_$i';
    }
    return unique;
  }
}

/// [value] with only letters, digits, underscores, and inner periods, safe
/// as a sequence ID in FASTA, NEXUS, and PHYLIP and as a file name.
String safeName(String value) {
  final String name = value
      .replaceAll(RegExp(r'[^A-Za-z0-9_.]+'), '_')
      .replaceAll(RegExp(r'_{2,}'), '_')
      .replaceAll(RegExp(r'^[_.]+|[_.]+$'), '');
  return name.isEmpty ? 'sequence' : name;
}
