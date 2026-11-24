//! Rust-backed [DownloadHandle] using `segul-core`'s concurrent downloader.

import 'dart:async';
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:segui/services/databases/client.dart';
import 'package:segui/services/databases/download.dart';
import 'package:segui/services/databases/types.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/src/rust/api/download.dart';

/// Executes GenBank and ENA downloads through `segul-core` via Flutter Rust
/// Bridge.
class RustDownloadHandle implements DownloadHandle {
  RustDownloadHandle({
    required this.records,
    required this.options,
    required this.trimsToFrame,
    required this.root,
    this.takenNames = const {},
    this.ncbiApiKey = '',
    this.concurrency = DownloadConcurrency.auto,
    this.maxConnections,
  });

  final List<DatabaseRecord> records;
  final DownloadOptions options;
  final bool trimsToFrame;
  final Directory root;
  final Set<String> takenNames;
  final String ncbiApiKey;
  final DownloadConcurrency concurrency;
  final int? maxConnections;

  DatabaseDownloadJob? _job;

  @override
  Future<DownloadReport> run({
    CancelToken? cancel,
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    cancel?.throwIfCancelled();
    final DatabaseDownloadJob job = _ensureJob();
    final DownloadMonitor monitor = DownloadMonitor();
    final StreamSubscription<FrbDownloadProgress> sub =
        monitor.subscribe().listen((progress) {
      onProgress?.call(_mapProgress(progress));
    });
    final removeCancel = cancel?.onCancel(monitor.cancel);
    try {
      final FrbDownloadReport report = await job.run(monitor: monitor);
      if (monitor.isCancelled() || (cancel?.isCancelled ?? false)) {
        throw const DatabaseCancelled();
      }
      return _mapReport(report);
    } on AnyhowException catch (e) {
      if (monitor.isCancelled() ||
          (cancel?.isCancelled ?? false) ||
          e.message.contains('CANCELLED')) {
        throw const DatabaseCancelled();
      }
      throw DatabaseException(_cleanRustError(e.message));
    } finally {
      removeCancel?.call();
      monitor.close();
      await sub.cancel();
    }
  }

  @override
  Future<CompletedDownload> commit() async {
    final DatabaseDownloadJob? job = _job;
    if (job == null) {
      throw const DatabaseException('Nothing was downloaded.');
    }
    try {
      final FrbCompletedDownload completed = await job.commit();
      return CompletedDownload(
        files: [for (final String path in completed.files) File(path)],
        dataType: completed.dataType,
      );
    } on AnyhowException catch (e) {
      throw DatabaseException(_cleanRustError(e.message));
    }
  }

  @override
  Future<void> discard() async {
    final DatabaseDownloadJob? job = _job;
    _job = null;
    if (job == null) return;
    try {
      await job.discard();
    } on Object {
      // Best-effort cleanup; Data usage lists anything left behind.
    }
  }

  DatabaseDownloadJob _ensureJob() {
    if (_job case final DatabaseDownloadJob existing) return existing;
    final String key = ncbiApiKey.trim();
    return _job = DatabaseDownloadJob(
      request: FrbDownloadRequest(
        records: [for (final record in records) _toFrbRecord(record)],
        options: FrbDownloadOptions(
          grouping: switch (options.grouping) {
            SequenceGrouping.singleFile => FrbSequenceGrouping.singleFile,
            SequenceGrouping.perRecord => FrbSequenceGrouping.perRecord,
          },
          naming: switch (options.naming) {
            SequenceNaming.speciesAccession =>
              FrbSequenceNaming.speciesAccession,
            SequenceNaming.accession => FrbSequenceNaming.accession,
          },
          gene: options.gene,
          fileName: options.fileName,
        ),
        ncbiApiKey: key.isEmpty ? null : key,
        concurrency: switch (concurrency) {
          DownloadConcurrency.auto => FrbConcurrencyProfile.auto,
          DownloadConcurrency.conservative =>
            FrbConcurrencyProfile.conservative,
          DownloadConcurrency.single => FrbConcurrencyProfile.single,
        },
        maxConnections: maxConnections,
        trimsToFrame: trimsToFrame,
        rootDir: root.path,
        takenNames: takenNames.toList(),
      ),
    );
  }

  FrbDownloadRecord _toFrbRecord(DatabaseRecord record) {
    return FrbDownloadRecord(
      source: switch (record.source) {
        DatabaseSource.genBank => FrbDatabaseSource.genBank,
        DatabaseSource.ena => FrbDatabaseSource.ena,
      },
      content: switch (record.content) {
        DownloadContent.nucleotide => FrbDownloadContent.nucleotide,
        DownloadContent.coding => FrbDownloadContent.coding,
        DownloadContent.protein => FrbDownloadContent.protein,
        DownloadContent.reads => FrbDownloadContent.reads,
        DownloadContent.assembly => FrbDownloadContent.assembly,
      },
      accession: record.accession,
      organism: record.organism,
      title: record.title,
      length: record.length == null ? null : BigInt.from(record.length!),
      codonStart: record.codonStart,
      gene: record.gene,
      files: [
        for (final file in record.files)
          FrbRemoteFile(
            url: file.url.toString(),
            bytes: file.bytes == null ? null : BigInt.from(file.bytes!),
            md5: file.md5,
          ),
      ],
    );
  }

  DownloadProgress _mapProgress(FrbDownloadProgress progress) {
    return DownloadProgress(
      done: progress.done,
      total: progress.total,
      bytes: progress.bytes.toInt(),
      bytesTotal: progress.bytesTotal.toInt(),
      bytesPerSecond: progress.bytesPerSecond?.toInt(),
      stage: switch (progress.stage) {
        FrbDownloadStage.connecting => DownloadStage.connecting,
        FrbDownloadStage.downloading => DownloadStage.downloading,
        FrbDownloadStage.retrying => DownloadStage.retrying,
        FrbDownloadStage.verifying => DownloadStage.verifying,
        FrbDownloadStage.decompressing => DownloadStage.decompressing,
        FrbDownloadStage.preparing => DownloadStage.preparing,
      },
      retryAttempt: progress.retryAttempt,
      retryMax: progress.retryMax,
      statuses: {
        for (final entry in progress.statuses)
          entry.key: switch (entry.status) {
            FrbRecordStatus.pending => RecordDownloadStatus.pending,
            FrbRecordStatus.active => RecordDownloadStatus.active,
            FrbRecordStatus.done => RecordDownloadStatus.done,
            FrbRecordStatus.failed => RecordDownloadStatus.failed,
          },
      },
    );
  }

  DownloadReport _mapReport(FrbDownloadReport report) {
    final Map<String, DatabaseRecord> byKey = {
      for (final record in records) record.key: record,
    };
    return DownloadReport(
      completed: report.completed,
      failures: [
        for (final failure in report.failures)
          DownloadFailure(
            record: byKey[failure.recordKey] ??
                records.firstWhere(
                  (r) => r.accession == failure.accession,
                  orElse: () => records.first,
                ),
            reason: failure.reason,
          ),
      ],
    );
  }

  String _cleanRustError(String raw) {
    final String firstLine = raw.split('\n').first.trim();
    if (firstLine.isEmpty) return 'Something went wrong. Try again.';
    return firstLine;
  }
}
