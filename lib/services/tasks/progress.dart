import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/src/rust/api/progress.dart';

/// Message shown when the user stops a run.
const String runCancelledMessage = 'Run cancelled.';

/// File progress of a running task.
class RunProgress {
  const RunProgress({
    required this.tool,
    required this.startedAt,
    this.done = 0,
    this.total = 0,
    this.currentFile,
    this.stage,
    this.isCancelling = false,
  });

  /// Tool page that started the run.
  final HomeTool? tool;
  final DateTime startedAt;

  /// Files finished and files in the run. [total] is zero until the task
  /// reports it.
  final int done;
  final int total;

  /// Name of the file that started most recently.
  final String? currentFile;

  /// A step after the files are read, such as writing outputs.
  final String? stage;

  /// Whether the user asked to stop. Running files stop at their next block.
  final bool isCancelling;

  /// Share of files finished, or null when it is unknown or a later step
  /// is running.
  double? get fraction {
    if (total == 0 || stage != null) {
      return null;
    }
    return done / total;
  }

  RunProgress withTask(TaskProgress progress) {
    return RunProgress(
      tool: tool,
      startedAt: startedAt,
      done: progress.done,
      total: progress.total,
      currentFile: progress.currentFile,
      stage: progress.stage,
      isCancelling: isCancelling,
    );
  }

  RunProgress cancelling() {
    return RunProgress(
      tool: tool,
      startedAt: startedAt,
      done: done,
      total: total,
      currentFile: currentFile,
      stage: stage,
      isCancelling: true,
    );
  }
}

final runProgressProvider = NotifierProvider<RunProgressNotifier, RunProgress?>(
    RunProgressNotifier.new);

/// Progress of the running genomic task, or null when none is running.
class RunProgressNotifier extends Notifier<RunProgress?> {
  RunMonitor? _monitor;
  StreamSubscription<TaskProgress>? _subscription;

  @override
  RunProgress? build() {
    ref.onDispose(_stopListening);
    return null;
  }

  /// Starts tracking a run of the current tool. Pass the returned monitor
  /// to the task, and call [finish] when it returns.
  RunMonitor start() {
    _stopListening();
    final RunMonitor monitor = RunMonitor();
    _monitor = monitor;
    state = RunProgress(
      tool: ref.read(currentToolProvider),
      startedAt: DateTime.now(),
    );
    _subscription = monitor.subscribe().listen((TaskProgress progress) {
      if (identical(_monitor, monitor)) {
        state = state?.withTask(progress);
      }
    });
    return monitor;
  }

  /// Asks the running task to skip the files it has not started.
  void cancel() {
    final RunMonitor? monitor = _monitor;
    if (monitor == null) {
      return;
    }
    monitor.cancel();
    state = state?.cancelling();
  }

  void finish() {
    _monitor?.close();
    _stopListening();
    _monitor = null;
    state = null;
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Progress of the run started from the current tool page, or null when
/// that tool is not running a tracked task.
final currentRunProgressProvider = Provider<RunProgress?>((ref) {
  final RunProgress? progress = ref.watch(runProgressProvider);
  if (progress == null || progress.tool != ref.watch(currentToolProvider)) {
    return null;
  }
  return progress;
});

/// Elapsed time as m:ss, or h:mm:ss after an hour.
String formatElapsed(Duration elapsed) {
  final String minutes = elapsed.inMinutes.remainder(60).toString();
  final String seconds =
      elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (elapsed.inHours == 0) {
    return '$minutes:$seconds';
  }
  return '${elapsed.inHours}:${minutes.padLeft(2, '0')}:$seconds';
}
