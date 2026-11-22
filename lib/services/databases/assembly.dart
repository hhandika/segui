//! Prepares assembly downloads as contig input.

import 'dart:convert';
import 'dart:io';

import 'package:segui/services/databases/client.dart';
import 'package:segui/services/databases/types.dart';

/// Decompresses the gzipped FASTA [source] into [destination].
Future<void> decompressFasta(
  File source,
  File destination, {
  CancelToken? cancel,
}) async {
  final IOSink sink = destination.openWrite();
  try {
    await sink.addStream(source.openRead().transform(gzip.decoder).map((data) {
      cancel?.throwIfCancelled();
      return data;
    }));
    await sink.flush();
  } on FormatException {
    throw const DatabaseException('The downloaded assembly is damaged.');
  } finally {
    await sink.close();
  }
}

/// The accessions in an ENA sequence [report], without versions.
Set<String> parseSequenceReport(String report) {
  final List<String> lines = const LineSplitter().convert(report);
  if (lines.isEmpty || !lines.first.startsWith('accession\t')) {
    throw const DatabaseException('ENA sent an unreadable assembly report.');
  }
  return {
    for (final line in lines.skip(1))
      if (line.trim().isNotEmpty) baseAccession(line.split('\t').first),
  };
}

/// Writes the sequences that make up an ENA assembly to [destination].
///
/// ENA lists chromosomes and scaffolds along with the contigs they are
/// built from, which can double an assembly, so only [members] from its
/// sequence report are kept. ENA also answers for an older version with the
/// latest one. The bases must therefore add up to [expectedBases], or this
/// throws rather than give a wrong assembly. A null [members] keeps all.
Future<void> writeEnaAssembly(
  File source,
  File destination, {
  required Set<String>? members,
  required int expectedBases,
  CancelToken? cancel,
}) async {
  final IOSink sink = destination.openWrite();
  final StringBuffer buffer = StringBuffer();
  final Set<String> seen = {};
  int bases = 0;
  bool isKept = false;
  try {
    await for (final String line in source
        .openRead()
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())) {
      cancel?.throwIfCancelled();
      if (line.startsWith('>')) {
        final String id = baseAccession(
          line.substring(1).split(RegExp(r'\s')).first.split('|').last,
        );
        isKept = (members == null || members.contains(id)) && seen.add(id);
      } else if (isKept) {
        bases += line.trim().length;
      }
      if (!isKept) continue;
      buffer.writeln(line);
      if (buffer.length >= 1 << 16) {
        sink.write(buffer.toString());
        buffer.clear();
        await sink.flush();
      }
    }
    sink.write(buffer.toString());
    await sink.flush();
  } finally {
    await sink.close();
  }
  final bool hasAll = members == null || seen.containsAll(members);
  if (!hasAll || bases != expectedBases) {
    throw const DatabaseException(
      'ENA sent an incomplete or different assembly. Try GenBank.',
    );
  }
}
