//! What GenBank and ENA have in common.

import 'dart:convert';
import 'dart:io';

import 'package:segui/services/databases/client.dart';
import 'package:segui/services/databases/types.dart';

/// Raw sequences saved for a batch of records.
class RawFasta {
  const RawFasta({required this.file, required this.url});

  final File file;
  final Uri url;
}

abstract class SequenceArchive {
  const SequenceArchive(this.client);

  final DatabaseClient client;

  DatabaseSource get source;

  /// Most records [saveFasta] takes at once.
  int get batchSize;

  Future<DatabasePage> search(
    DatabaseQuery query, {
    PageCursor? after,
    CancelToken? cancel,
  });

  Future<DatabasePage> lookUp(
    List<String> accessions,
    DownloadContent content, {
    CancelToken? cancel,
  });

  /// Scientific names that start like [text].
  Future<List<String>> suggestOrganisms(String text, {CancelToken? cancel});

  /// Saves the sequences of [records] to [destination] as the archive
  /// serves them. Records the archive lacks are left out without an error.
  Future<RawFasta> saveFasta(
    List<DatabaseRecord> records,
    File destination, {
    CancelToken? cancel,
    void Function(int bytes)? onReceived,
  });

  /// Accession and any coding details in a header from [saveFasta].
  FastaOrigin readHeader(String header);
}

/// Where a FASTA record came from.
class FastaOrigin {
  const FastaOrigin({
    required this.accession,
    this.gene = '',
    this.product = '',
    this.codonStart,
  });

  final String accession;
  final String gene;
  final String product;

  /// Null when the header does not state it.
  final int? codonStart;
}

/// Decodes [body], explaining a response that is not JSON.
Object? decodeArchiveJson(String body) {
  try {
    // NCBI puts raw line breaks in some error messages.
    return jsonDecode(body.replaceAll(RegExp(r'[\r\n\t]'), ' '));
  } on FormatException {
    throw const DatabaseException(
      'The database sent an unreadable answer. Try again later.',
    );
  }
}

/// [value] without the characters that have meaning in a search query.
String cleanTerm(String value) {
  return value
      .replaceAll(RegExp(r'["\[\]()*\\=<>]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
