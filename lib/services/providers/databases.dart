import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/databases/archive.dart';
import 'package:segui/services/databases/client.dart';
import 'package:segui/services/databases/compatibility.dart';
import 'package:segui/services/databases/download.dart';
import 'package:segui/services/databases/ena.dart';
import 'package:segui/services/databases/genbank.dart';
import 'package:segui/services/databases/rust_download.dart';
import 'package:segui/services/databases/types.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/io/mobile_io.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/types.dart';
import 'package:segui/src/rust/api/common.dart';

final databaseClientProvider = Provider<DatabaseClient>((ref) {
  final String apiKey = ref.watch(ncbiApiKeyProvider).trim();
  final HttpDatabaseClient client = HttpDatabaseClient(
    ncbiInterval: apiKey.isEmpty
        ? HttpDatabaseClient.defaultNcbiInterval
        : HttpDatabaseClient.keyedNcbiInterval,
  );
  ref.onDispose(client.close);
  return client;
});

final databaseArchivesProvider =
    Provider<Map<DatabaseSource, SequenceArchive>>((ref) {
  final DatabaseClient client = ref.watch(databaseClientProvider);
  final String apiKey = ref.watch(ncbiApiKeyProvider).trim();
  return {
    DatabaseSource.genBank: GenBankArchive(client, apiKey: apiKey),
    DatabaseSource.ena: EnaArchive(client),
  };
});

typedef DownloadHandleFactory = DownloadHandle Function({
  required List<DatabaseRecord> records,
  required DownloadOptions options,
  required bool trimsToFrame,
  required Directory root,
  required Set<String> takenNames,
});

/// Creates the download runner for a session; overridden in tests to avoid
/// loading the native Rust library.
final downloadHandleFactoryProvider = Provider<DownloadHandleFactory>((ref) {
  final String apiKey = ref.watch(ncbiApiKeyProvider).trim();
  final DownloadConcurrency concurrency =
      ref.watch(downloadConcurrencyProvider);
  final int? maxConnections = concurrency == DownloadConcurrency.auto &&
          runningPlatform == PlatformType.isMobile
      ? 4
      : null;
  return ({
    required List<DatabaseRecord> records,
    required DownloadOptions options,
    required bool trimsToFrame,
    required Directory root,
    required Set<String> takenNames,
  }) =>
      RustDownloadHandle(
        records: records,
        options: options,
        trimsToFrame: trimsToFrame,
        root: root,
        takenNames: takenNames,
        ncbiApiKey: apiKey,
        concurrency: concurrency,
        maxConnections: maxConnections,
      );
});

final downloadFolderProvider =
    NotifierProvider<DownloadFolderSetting, String?>(DownloadFolderSetting.new);

/// Remembers the folder the user picked for downloads on desktop, or null
/// for the downloads folder in SEGUI's data folder.
class DownloadFolderSetting extends Notifier<String?> {
  static const String _key = 'downloadFolder';

  @override
  String? build() {
    if (runningPlatform != PlatformType.isDesktop) return null;
    return ref.watch(settingProvider).getString(_key);
  }

  /// Asks the user for a folder. Returns false when the user cancels.
  Future<bool> choose() async {
    final Directory? dir = await pickDirectory();
    if (dir == null) return false;
    state = dir.path;
    await ref.read(settingProvider).setString(_key, dir.path);
    return true;
  }

  Future<void> reset() async {
    state = null;
    await ref.read(settingProvider).remove(_key);
  }
}

/// Finds the folder downloads are saved to: the one the user picked, or
/// the downloads folder in SEGUI's data folder.
final downloadsDirProvider = Provider<Future<Directory> Function()>((ref) {
  return () async {
    final String? chosen = ref.read(downloadFolderProvider);
    if (chosen != null) {
      final dir = Directory(chosen);
      await dir.create(recursive: true);
      return dir;
    }
    final Directory data = await getSeguiDirectory();
    final dir = Directory(p.join(data.path, downloadsDirName));
    await dir.create(recursive: true);
    // Downloads can be fetched again, and iOS would back them up to iCloud.
    if (Platform.isIOS) {
      await MobileIoChannel.instance.excludeFromBackup(dir);
    }
    return dir;
  };
});

/// Bytes free on the drive downloads are saved to, or null when unknown.
final downloadSpaceProvider = FutureProvider.autoDispose<int?>((ref) async {
  ref.watch(downloadFolderProvider);
  try {
    final Directory dir = await ref.read(downloadsDirProvider)();
    return await getAvailableSpace(path: dir.path);
  } on Object {
    // Free space is a hint, so a drive that cannot be read shows none.
    return null;
  }
});

/// The picker a database search adds to.
typedef DatabaseTarget = ({SupportedTask task, XTypeGroup group});

enum DatabaseEntryMode {
  search('Search'),
  paste('Paste accessions');

  const DatabaseEntryMode(this.label);

  final String label;
}

/// Downloads above this size ask first.
const int largeDownloadBytes = 1000 * 1000 * 1000;

class DatabaseState {
  const DatabaseState({
    required this.source,
    required this.content,
    this.mode = DatabaseEntryMode.search,
    this.options = const DownloadOptions(),
    this.isSearching = false,
    this.hasSearched = false,
    this.page = DatabasePage.empty,
    this.error,
    this.selected = const {},
    this.progress,
    this.report,
  });

  final DatabaseSource source;
  final DownloadContent content;
  final DatabaseEntryMode mode;
  final DownloadOptions options;
  final bool isSearching;
  final bool hasSearched;
  final DatabasePage page;
  final String? error;

  /// Every record selected since the panel opened, by key.
  final Map<String, DatabaseRecord> selected;

  /// Set while downloading.
  final DownloadProgress? progress;

  /// Set when a download finished with failures.
  final DownloadReport? report;

  bool get isDownloading => progress != null;

  /// The selected records of the current content, which download together.
  List<DatabaseRecord> get selection =>
      selected.values.where((e) => e.content == content).toList();

  /// Size of [selection], or null when any size is unknown.
  int? get selectionBytes {
    int total = 0;
    for (final record in selection) {
      final int? bytes = record.estimatedBytes;
      if (bytes == null) return null;
      total += bytes;
    }
    return total;
  }

  DatabaseState copyWith({
    DatabaseSource? source,
    DownloadContent? content,
    DatabaseEntryMode? mode,
    DownloadOptions? options,
    bool? isSearching,
    bool? hasSearched,
    DatabasePage? page,
    String? Function()? error,
    Map<String, DatabaseRecord>? selected,
    DownloadProgress? Function()? progress,
    DownloadReport? Function()? report,
  }) {
    return DatabaseState(
      source: source ?? this.source,
      content: content ?? this.content,
      mode: mode ?? this.mode,
      options: options ?? this.options,
      isSearching: isSearching ?? this.isSearching,
      hasSearched: hasSearched ?? this.hasSearched,
      page: page ?? this.page,
      error: error == null ? this.error : error(),
      selected: selected ?? this.selected,
      progress: progress == null ? this.progress : progress(),
      report: report == null ? this.report : report(),
    );
  }
}

/// The search, selection, and download of one open database panel. Closing
/// the panel disposes it, which stops requests and deletes unfinished files.
final databaseSessionProvider = NotifierProvider.autoDispose
    .family<DatabaseSession, DatabaseState, DatabaseTarget>(
        DatabaseSession.new);

class DatabaseSession extends Notifier<DatabaseState> {
  DatabaseSession(this.target);

  final DatabaseTarget target;

  static const Duration _suggestionDelay = Duration(milliseconds: 400);
  static const int _suggestionMinLength = 3;
  static const Duration _progressInterval = Duration(milliseconds: 100);

  CancelToken? _searchToken;
  CancelToken? _suggestToken;
  CancelToken? _downloadToken;
  DownloadHandle? _job;
  DatabaseQuery? _query;
  bool _isRunning = false;

  DatabaseAvailable get support =>
      databaseSupportFor(target.task, target.group) as DatabaseAvailable;

  @override
  DatabaseState build() {
    ref.onDispose(_dispose);
    final DatabaseSource source = support.sources.first;
    return DatabaseState(
      source: source,
      content: support.contentsOf(source).first,
    );
  }

  void setSource(DatabaseSource source) {
    if (source == state.source) return;
    final List<DownloadContent> contents = support.contentsOf(source);
    _resetResults();
    state = state.copyWith(
      source: source,
      content: contents.contains(state.content) ? null : contents.first,
    );
  }

  void setContent(DownloadContent content) {
    if (content == state.content) return;
    _resetResults();
    state = state.copyWith(content: content);
  }

  void setMode(DatabaseEntryMode mode) {
    if (mode == state.mode) return;
    _resetResults();
    state = state.copyWith(mode: mode);
  }

  void setOptions(DownloadOptions options) {
    state = state.copyWith(options: options);
  }

  Future<void> search(DatabaseQuery query) async {
    _query = query;
    state = state.copyWith(
      options: state.options.copyWith(gene: query.gene.trim()),
    );
    await _load((archive, token) => archive.search(query, cancel: token));
  }

  Future<void> lookUp(String text) async {
    final parsed = parseAccessions(text);
    if (parsed.accessions.isEmpty) {
      state = state.copyWith(error: () => 'Enter one or more accessions.');
      return;
    }
    final DownloadContent content = state.content;
    await _load((archive, token) async {
      final page =
          await archive.lookUp(parsed.accessions, content, cancel: token);
      return DatabasePage(
        records: page.records,
        total: page.total,
        missing: [...page.missing, ...parsed.invalid],
      );
    }, selectsAll: true);
  }

  Future<void> loadMore() async {
    final DatabasePage current = state.page;
    final PageCursor? next = current.next;
    final DatabaseQuery? query = _query;
    if (next == null || query == null || state.isSearching) return;
    await _load((archive, token) async {
      final page = await archive.search(query, after: next, cancel: token);
      // ENA sends earlier results again, GenBank only the new ones.
      final Map<String, DatabaseRecord> records = {
        for (final record in current.records) record.key: record,
        for (final record in page.records) record.key: record,
      };
      return DatabasePage(
        records: records.values.toList(),
        total: page.total,
        next: page.next,
      );
    }, keepsResults: true);
  }

  void stopSearch() {
    _searchToken?.cancel();
    _searchToken = null;
    state = state.copyWith(isSearching: false);
  }

  void toggle(DatabaseRecord record) {
    final selected = {...state.selected};
    if (selected.remove(record.key) == null) {
      selected[record.key] = record;
    }
    state = state.copyWith(selected: selected);
  }

  void selectShown(bool isSelected) {
    final selected = {...state.selected};
    for (final record in state.page.records) {
      if (!canSelect(record)) continue;
      if (isSelected) {
        selected[record.key] = record;
      } else {
        selected.remove(record.key);
      }
    }
    state = state.copyWith(selected: selected);
  }

  void clearSelection() {
    state = state.copyWith(selected: const {});
  }

  /// Organism names that start like [text], after a pause in typing.
  Future<List<String>> suggest(String text) async {
    _suggestToken?.cancel();
    final token = _suggestToken = CancelToken();
    if (text.trim().length < _suggestionMinLength) return const [];
    await Future<void>.delayed(_suggestionDelay);
    if (token.isCancelled || !ref.mounted) return const [];
    try {
      return await _archive.suggestOrganisms(text, cancel: token);
    } on Exception {
      // Suggestions are optional, and a search reports connection problems.
      return const [];
    }
  }

  /// Downloads the selection. Returns the files when all records arrive,
  /// and otherwise shows what failed. [takenNames] are the names of the
  /// files the picker already holds.
  Future<CompletedDownload?> download({
    Set<String> takenNames = const {},
  }) async {
    if (state.isDownloading || state.selection.isEmpty) return null;
    _searchToken?.cancel();
    _suggestToken?.cancel();
    final List<DatabaseRecord> records = state.selection;
    final token = _downloadToken = CancelToken();
    state = state.copyWith(
      isSearching: false,
      error: () => null,
      progress: () => DownloadProgress(done: 0, total: records.length),
    );
    try {
      final Directory root = await ref.read(downloadsDirProvider)();
      token.throwIfCancelled();
      _job = ref.read(downloadHandleFactoryProvider)(
        records: records,
        options: state.options,
        trimsToFrame: support.trimsToFrame,
        root: root,
        takenNames: takenNames,
      );
      return await _run(token);
    } on Exception catch (e) {
      _endDownload(e);
      return null;
    }
  }

  /// Retries the records that failed.
  Future<CompletedDownload?> retry() async {
    final DownloadReport? report = state.report;
    if (_job == null || report == null) return null;
    final token = _downloadToken = CancelToken();
    state = state.copyWith(
      report: () => null,
      progress: () => DownloadProgress(
        done: report.completed,
        total: report.completed + report.failures.length,
      ),
    );
    try {
      return await _run(token);
    } on Exception catch (e) {
      _endDownload(e);
      return null;
    }
  }

  /// Keeps what arrived and leaves out what failed.
  Future<CompletedDownload?> addRest() async {
    final DownloadHandle? job = _job;
    if (job == null || state.report == null) return null;
    try {
      final completed = await job.commit();
      _job = null;
      return completed;
    } on Exception catch (e) {
      _endDownload(e);
      return null;
    }
  }

  /// Drops a download that failed in part, and returns to the results.
  Future<void> dismissReport() async {
    final DownloadHandle? job = _job;
    _job = null;
    state = state.copyWith(report: () => null);
    await job?.discard();
  }

  void cancelDownload() => _downloadToken?.cancel();

  /// Whether [record] has anything to download.
  bool canSelect(DatabaseRecord record) {
    return switch (record.content) {
      DownloadContent.reads => record.files.isNotEmpty,
      DownloadContent.assembly =>
        record.source == DatabaseSource.ena || record.files.isNotEmpty,
      _ => true,
    };
  }

  SequenceArchive get _archive =>
      ref.read(databaseArchivesProvider)[state.source]!;

  Future<void> _load(
    Future<DatabasePage> Function(SequenceArchive archive, CancelToken token)
        request, {
    bool keepsResults = false,
    bool selectsAll = false,
  }) async {
    _searchToken?.cancel();
    final token = _searchToken = CancelToken();
    state = state.copyWith(
      isSearching: true,
      error: () => null,
      page: keepsResults ? null : DatabasePage.empty,
      hasSearched: keepsResults,
    );
    try {
      final DatabasePage page = await request(_archive, token);
      if (!ref.mounted || token.isCancelled) return;
      state = state.copyWith(
        isSearching: false,
        hasSearched: true,
        page: page,
      );
      // Pasted accessions are already a choice.
      if (selectsAll) selectShown(true);
    } on Exception catch (e) {
      if (!ref.mounted || token.isCancelled) return;
      state = state.copyWith(isSearching: false, error: () => _message(e));
    }
  }

  Future<CompletedDownload?> _run(CancelToken token) async {
    final DownloadHandle job = _job!;
    final Stopwatch sinceUpdate = Stopwatch()..start();
    int lastDone = -1;
    DownloadStage? lastStage;
    int? lastRetryAttempt;
    _isRunning = true;
    final DownloadReport report = await job
        .run(
      cancel: token,
      onProgress: (progress) {
        if (!ref.mounted || token.isCancelled) return;
        final bool stateChanged = progress.done != lastDone ||
            progress.stage != lastStage ||
            progress.retryAttempt != lastRetryAttempt;
        // Bytes arrive far more often than the screen can show.
        if (!stateChanged && sinceUpdate.elapsed < _progressInterval) {
          return;
        }
        lastDone = progress.done;
        lastStage = progress.stage;
        lastRetryAttempt = progress.retryAttempt;
        sinceUpdate.reset();
        state = state.copyWith(progress: () => progress);
      },
    )
        .whenComplete(() {
      _isRunning = false;
      if (ref.mounted) ref.invalidate(downloadSpaceProvider);
    });
    if (!ref.mounted) {
      await job.discard();
      return null;
    }
    if (report.isComplete) {
      final CompletedDownload completed = await job.commit();
      _job = null;
      return completed;
    }
    state = state.copyWith(progress: () => null, report: () => report);
    return null;
  }

  void _endDownload(Exception error) {
    final DownloadHandle? job = _job;
    _job = null;
    unawaited(job?.discard());
    if (!ref.mounted) return;
    state = state.copyWith(
      progress: () => null,
      report: () => null,
      error: () => error is DatabaseCancelled ? null : _message(error),
    );
  }

  void _resetResults() {
    _searchToken?.cancel();
    _query = null;
    state = state.copyWith(
      isSearching: false,
      hasSearched: false,
      page: DatabasePage.empty,
      error: () => null,
    );
  }

  String _message(Exception error) {
    return switch (error) {
      DatabaseException(:final message) => message,
      FileSystemException(:final message) =>
        'Could not save the download ($message).',
      _ => 'Something went wrong. Try again.',
    };
  }

  void _dispose() {
    _searchToken?.cancel();
    _suggestToken?.cancel();
    _downloadToken?.cancel();
    // A running job deletes its files itself once it sees the cancel.
    if (!_isRunning) unawaited(_job?.discard());
  }
}
