//! Downloads selected records into SEGUI's data folder.

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/databases/archive.dart';
import 'package:segui/services/databases/assembly.dart';
import 'package:segui/services/databases/client.dart';
import 'package:segui/services/databases/ena.dart';
import 'package:segui/services/databases/fasta.dart';
import 'package:segui/services/databases/types.dart';

/// Folder of downloads in SEGUI's data folder. The input cache is emptied
/// at startup and whenever inputs change, so downloads cannot live there.
const String downloadsDirName = 'downloads';

/// File listing the origin of each sequence, beside every download.
const String sourcesFileName = 'sources.tsv';

/// Phase of a download job.
enum DownloadStage {
  connecting,
  downloading,
  retrying,
  verifying,
  decompressing,
  preparing,
}

/// Per-record download state.
enum RecordDownloadStatus { pending, active, done, failed }

class DownloadProgress {
  const DownloadProgress({
    required this.done,
    required this.total,
    this.bytes = 0,
    this.bytesTotal = 0,
    this.bytesPerSecond,
    this.stage = DownloadStage.downloading,
    this.retryAttempt,
    this.retryMax,
    this.statuses = const {},
  });

  final int done;
  final int total;
  final int bytes;

  /// Zero when the archive does not give sizes.
  final int bytesTotal;

  /// Rolling transfer speed, or null before the first sample.
  final int? bytesPerSecond;
  final DownloadStage stage;
  final int? retryAttempt;
  final int? retryMax;
  final Map<String, RecordDownloadStatus> statuses;
}

class DownloadFailure {
  const DownloadFailure({required this.record, required this.reason});

  final DatabaseRecord record;
  final String reason;
}

class DownloadReport {
  const DownloadReport({required this.completed, required this.failures});

  final int completed;
  final List<DownloadFailure> failures;

  bool get isComplete => failures.isEmpty;
}

/// Files ready to become inputs.
class CompletedDownload {
  const CompletedDownload({required this.files, required this.dataType});

  final List<File> files;

  /// SEGUL data type of the sequences, or null for reads and assemblies.
  final String? dataType;
}

/// Execution contract shared by the Rust downloader and the Dart test job.
abstract interface class DownloadHandle {
  Future<DownloadReport> run({
    CancelToken? cancel,
    void Function(DownloadProgress progress)? onProgress,
  });

  Future<CompletedDownload> commit();

  Future<void> discard();
}

/// One download. [run] can be repeated to retry what failed, and nothing is
/// visible until [commit]. [discard] deletes everything.
class DownloadJob implements DownloadHandle {
  DownloadJob({
    required this.client,
    required this.archives,
    required this.records,
    required this.options,
    required this.trimsToFrame,
    required this.root,
    this.takenNames = const {},
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final DatabaseClient client;
  final Map<DatabaseSource, SequenceArchive> archives;
  final List<DatabaseRecord> records;
  final DownloadOptions options;
  final bool trimsToFrame;

  /// SEGUI's downloads folder.
  final Directory root;

  /// Names, without extensions, of the files the picker already holds.
  /// SEGUL names outputs after inputs, so a repeat would overwrite one.
  final Set<String> takenNames;
  final DateTime Function() _now;

  static const List<String> _sourceColumns = [
    'database',
    'accession',
    'file',
    'id',
    'original_header',
    'trimmed_bases',
    'url',
    'downloaded',
  ];

  Directory? _staging;
  final Set<String> _done = {};
  final Set<String> _usedIds = {};
  final Set<String> _usedNames = {};
  final List<String> _fileNames = [];
  final Map<String, String> _nameOf = {};
  final List<List<String>> _sources = [];
  String? _singleName;
  bool _hasUnknownResidues = false;
  int _bytes = 0;
  int _temporary = 0;

  @override
  Future<DownloadReport> run({
    CancelToken? cancel,
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    try {
      await _prepareStaging();
      final pending =
          records.where((record) => !_done.contains(record.key)).toList();
      final int bytesTotal = _knownBytes(pending);
      _bytes = 0;
      final Map<String, RecordDownloadStatus> statuses = {
        for (final record in records)
          record.key: _done.contains(record.key)
              ? RecordDownloadStatus.done
              : RecordDownloadStatus.pending,
      };
      void report([int partial = 0]) {
        onProgress?.call(DownloadProgress(
          done: _done.length,
          total: records.length,
          bytes: _bytes + partial,
          bytesTotal: bytesTotal,
          statuses: Map.unmodifiable(statuses),
        ));
      }

      report();
      final Map<String, String> reasons = {};
      for (final source in DatabaseSource.values) {
        final sequences = pending
            .where((e) => e.source == source && e.content.isSequence)
            .toList();
        if (sequences.isEmpty) continue;
        final SequenceArchive archive = archives[source]!;
        for (final batch in batches(sequences, archive.batchSize)) {
          cancel?.throwIfCancelled();
          for (final record in batch) {
            statuses[record.key] = RecordDownloadStatus.active;
          }
          report();
          try {
            await _saveSequences(archive, batch, reasons, cancel, report);
            for (final record in batch) {
              statuses[record.key] = _done.contains(record.key)
                  ? RecordDownloadStatus.done
                  : RecordDownloadStatus.failed;
            }
          } on DatabaseException catch (e) {
            for (final record in batch) {
              reasons[record.key] = e.message;
              statuses[record.key] = RecordDownloadStatus.failed;
            }
          }
          report();
        }
      }
      for (final record in pending.where((e) => !e.content.isSequence)) {
        cancel?.throwIfCancelled();
        statuses[record.key] = RecordDownloadStatus.active;
        report();
        try {
          await _saveWholeFiles(record, cancel, report);
          _done.add(record.key);
          statuses[record.key] = RecordDownloadStatus.done;
        } on DatabaseException catch (e) {
          reasons[record.key] = e.message;
          statuses[record.key] = RecordDownloadStatus.failed;
        }
        report();
      }
      cancel?.throwIfCancelled();
      return DownloadReport(
        completed: _done.length,
        failures: [
          for (final record in records)
            if (!_done.contains(record.key))
              DownloadFailure(
                record: record,
                reason: reasons[record.key] ?? 'Not downloaded.',
              ),
        ],
      );
    } on FileSystemException catch (e) {
      await discard();
      cancel?.throwIfCancelled();
      throw DatabaseException(
        'Could not save the download (${e.osError?.message ?? e.message}).',
      );
    } catch (_) {
      await discard();
      rethrow;
    }
  }

  /// Moves the finished files out of staging and lists their sources.
  @override
  Future<CompletedDownload> commit() async {
    final Directory? staging = _staging;
    if (staging == null || _fileNames.isEmpty) {
      throw const DatabaseException('Nothing was downloaded.');
    }
    try {
      final String table = [
        _sourceColumns.join('\t'),
        for (final row in _sources)
          row.map((cell) => cell.replaceAll(RegExp(r'\s'), ' ')).join('\t'),
      ].join('\n');
      await File(p.join(staging.path, sourcesFileName))
          .writeAsString('$table\n');
      final String stamp = DateFormat('yyyyMMdd-HHmmss').format(_now());
      final String label = safeName(p.basenameWithoutExtension(
        _singleName ?? records.first.content.name,
      ));
      Directory target = Directory(p.join(root.path, '$label-$stamp'));
      for (int i = 2; await target.exists(); i++) {
        target = Directory(p.join(root.path, '$label-$stamp-$i'));
      }
      await staging.rename(target.path);
      _staging = null;
      final DownloadContent content = records.first.content;
      return CompletedDownload(
        files: [
          for (final name in _fileNames) File(p.join(target.path, name)),
        ],
        dataType: !content.isSequence
            ? null
            : _hasUnknownResidues
                ? 'Ignore'
                : content == DownloadContent.protein
                    ? 'AA'
                    : 'DNA',
      );
    } on FileSystemException catch (e) {
      throw DatabaseException('Could not save the download (${e.message}).');
    }
  }

  /// Deletes what this job saved.
  @override
  Future<void> discard() async {
    final Directory? staging = _staging;
    _staging = null;
    _done.clear();
    _usedIds.clear();
    _usedNames.clear();
    _fileNames.clear();
    _nameOf.clear();
    _sources.clear();
    _singleName = null;
    if (staging == null) return;
    try {
      await staging.delete(recursive: true);
    } on FileSystemException {
      // Data usage still lists what could not be deleted.
    }
  }

  Future<void> _prepareStaging() async {
    if (_staging != null) return;
    await root.create(recursive: true);
    _staging = await root.createTemp('.partial-');
  }

  Future<void> _saveSequences(
    SequenceArchive archive,
    List<DatabaseRecord> batch,
    Map<String, String> reasons,
    CancelToken? cancel,
    void Function([int partial]) report,
  ) async {
    final File raw = _temporaryFile();
    final Directory parts = await _staging!.createTemp('batch-');
    try {
      final RawFasta saved = await archive.saveFasta(
        batch,
        raw,
        cancel: cancel,
        onReceived: report,
      );
      final bool isSingle = options.grouping == SequenceGrouping.singleFile;
      final Map<String, File> partOf = {
        for (final (int i, DatabaseRecord record) in batch.indexed)
          record.key: File(p.join(parts.path, isSingle ? 'all' : '$i')),
      };
      // IDs and files change only once the whole batch reads as FASTA.
      final Set<String> ids = {..._usedIds};
      final PreparedBatch prepared = await FastaPreparer(
        archive: archive,
        options: options,
        trimsToFrame: trimsToFrame,
      ).prepare(
        saved.file,
        batch,
        outputFor: (record) => partOf[record.key]!,
        usedIds: ids,
        cancel: cancel,
      );
      final Set<String> appended = {};
      for (final sequence in prepared.sequences) {
        final DatabaseRecord record = sequence.record;
        final String name = _sequenceFileName(record);
        final File part = partOf[record.key]!;
        if (appended.add(part.path)) {
          final IOSink sink = File(p.join(_staging!.path, name))
              .openWrite(mode: FileMode.append);
          try {
            await sink.addStream(part.openRead());
          } finally {
            await sink.close();
          }
        }
        _addSource(
          record,
          file: name,
          id: sequence.id,
          header: sequence.header,
          trimmed: sequence.trimmed,
          url: saved.url,
        );
        _done.add(record.key);
      }
      _usedIds.addAll(ids);
      _hasUnknownResidues |= prepared.hasUnknownResidues;
      _bytes += await raw.length();
      for (final record in batch) {
        if (!_done.contains(record.key)) {
          reasons[record.key] = _absentReason(record);
        }
      }
    } finally {
      await _delete(raw);
      await _delete(parts);
    }
  }

  Future<void> _saveWholeFiles(
    DatabaseRecord record,
    CancelToken? cancel,
    void Function([int partial]) report,
  ) async {
    if (record.content == DownloadContent.reads) {
      await _saveRun(record, cancel, report);
    } else {
      await _saveAssembly(record, cancel, report);
    }
  }

  Future<void> _saveRun(
    DatabaseRecord record,
    CancelToken? cancel,
    void Function([int partial]) report,
  ) async {
    if (record.files.isEmpty) {
      throw const DatabaseException('ENA has no FASTQ files for this run.');
    }
    final List<({File part, RemoteFile remote})> saved = [];
    try {
      // A pair is kept only when both files arrive.
      for (final RemoteFile remote in record.files) {
        final File part = _temporaryFile();
        saved.add((part: part, remote: remote));
        final String sum = await client.save(
          remote.url,
          part,
          cancel: cancel,
          onReceived: report,
        );
        final int size = await part.length();
        await _verify(remote, sum, size);
        _bytes += size;
      }
      for (final (:part, :remote) in saved) {
        // Such as SRR1_1 of SRR1_1.fastq.gz.
        final String remoteName = p.url.basename(remote.url.path);
        final String name = _uniqueName(
          safeName(remoteName.replaceFirst(RegExp(r'\.(fastq|fq)\.gz$'), '')),
          '.fastq.gz',
          // An underscore and a digit would read as a mate number.
          separator: '-',
        );
        await part.rename(p.join(_staging!.path, name));
        _fileNames.add(name);
        _addSource(record, file: name, url: remote.url);
      }
    } finally {
      for (final file in saved) {
        await _delete(file.part);
      }
    }
  }

  Future<void> _saveAssembly(
    DatabaseRecord record,
    CancelToken? cancel,
    void Function([int partial]) report,
  ) async {
    final File raw = _temporaryFile();
    final File ready = _temporaryFile();
    try {
      final Uri url;
      if (record.source == DatabaseSource.genBank) {
        if (record.files.isEmpty) {
          throw const DatabaseException('NCBI has no FASTA for this assembly.');
        }
        url = record.files.first.url;
        final String? expected = await _ncbiChecksum(url, cancel);
        final String sum = await client.save(
          url,
          raw,
          cancel: cancel,
          onReceived: report,
        );
        await _verify(
          RemoteFile(url: url, md5: expected),
          sum,
          await raw.length(),
        );
        await decompressFasta(raw, ready, cancel: cancel);
      } else {
        final int? length = record.length;
        if (length == null) {
          throw const DatabaseException(
            'ENA gives no size to check this assembly. Try GenBank.',
          );
        }
        final Uri reportUrl = EnaArchive.assemblyReportUrl(record.accession);
        final response = await client.read(reportUrl, cancel: cancel);
        if (!response.isOk && response.status != HttpStatus.notFound) {
          throw const DatabaseException(
            'Could not read the assembly report. Try again.',
          );
        }
        url = EnaArchive.assemblyFastaUrl(record.accession);
        await client.save(url, raw, cancel: cancel, onReceived: report);
        await writeEnaAssembly(
          raw,
          ready,
          members: response.isOk ? parseSequenceReport(response.body) : null,
          expectedBases: length,
          cancel: cancel,
        );
      }
      _bytes += await raw.length();
      final String name = _uniqueName(_stemOf(record), '.fna');
      await ready.rename(p.join(_staging!.path, name));
      _fileNames.add(name);
      _addSource(record, file: name, url: url);
    } finally {
      await _delete(raw);
      await _delete(ready);
    }
  }

  Future<String?> _ncbiChecksum(Uri file, CancelToken? cancel) async {
    final Uri list = file.replace(
      path: p.url.join(p.url.dirname(file.path), 'md5checksums.txt'),
    );
    final response = await client.read(list, cancel: cancel);
    if (response.status == HttpStatus.notFound) return null;
    if (!response.isOk) {
      throw const DatabaseException('Could not read the checksum. Try again.');
    }
    final String name = './${p.url.basename(file.path)}';
    for (final String line in response.body.split('\n')) {
      final List<String> parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length == 2 && parts.last == name) return parts.first;
    }
    return null;
  }

  Future<void> _verify(RemoteFile remote, String sum, int size) async {
    if (remote.bytes != null && remote.bytes != size) {
      throw const DatabaseException(
        'The file size does not match. Retry the download.',
      );
    }
    if (remote.md5 != null && remote.md5!.toLowerCase() != sum) {
      throw const DatabaseException(
        'The checksum does not match. Retry the download.',
      );
    }
  }

  String _absentReason(DatabaseRecord record) {
    if (record.content != DownloadContent.coding) {
      return '${record.source.label} did not return this record.';
    }
    final String gene = options.gene.trim();
    return gene.isEmpty
        ? 'No coding sequence in this record.'
        : 'No $gene coding sequence in this record.';
  }

  String _sequenceFileName(DatabaseRecord record) {
    if (options.grouping == SequenceGrouping.perRecord) {
      return _nameOf.putIfAbsent(record.key, () {
        final String name = _uniqueName(_stemOf(record), '.fasta');
        _fileNames.add(name);
        return name;
      });
    }
    if (_singleName case final String name) return name;
    String stem = options.fileName.trim();
    if (stem.isEmpty) stem = options.gene.trim();
    if (stem.isEmpty) stem = 'sequences';
    // SEGUL reads text after a period as an extension.
    final String name =
        _uniqueName(safeName(stem).replaceAll('.', '_'), '.fasta');
    _fileNames.add(name);
    return _singleName = name;
  }

  String _stemOf(DatabaseRecord record) =>
      safeName(record.accession).replaceAll('.', '_');

  String _uniqueName(String stem, String extension, {String separator = '_'}) {
    final Set<String> taken = {
      for (final name in takenNames) name.toLowerCase(),
    };
    String unique = stem;
    for (int i = 2;
        taken.contains(unique.toLowerCase()) ||
            _usedNames.contains(unique.toLowerCase());
        i++) {
      unique = '$stem$separator$i';
    }
    _usedNames.add(unique.toLowerCase());
    return '$unique$extension';
  }

  void _addSource(
    DatabaseRecord record, {
    required String file,
    required Uri url,
    String id = '',
    String header = '',
    int trimmed = 0,
  }) {
    _sources.add([
      record.source.label,
      record.accession,
      file,
      id,
      header,
      '$trimmed',
      '$url',
      _now().toUtc().toIso8601String(),
    ]);
  }

  int _knownBytes(List<DatabaseRecord> pending) {
    // Only runs list the exact size of what is downloaded.
    if (pending.any((e) => e.content != DownloadContent.reads)) return 0;
    return pending.fold(0, (sum, e) => sum + (e.estimatedBytes ?? 0));
  }

  File _temporaryFile() {
    _temporary++;
    return File(p.join(_staging!.path, 'download-$_temporary.part'));
  }

  Future<void> _delete(FileSystemEntity entity) async {
    try {
      if (await entity.exists()) await entity.delete(recursive: true);
    } on FileSystemException {
      // Discard deletes the staging folder with anything left in it.
    }
  }
}

/// Name of the file at [path] without its extensions, to compare with the
/// names of new downloads.
String inputStem(String path) {
  String name = p.basename(path);
  if (p.extension(name).toLowerCase() == '.gz') {
    name = p.withoutExtension(name);
  }
  return p.withoutExtension(name);
}
