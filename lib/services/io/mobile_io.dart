import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// What SEGUI is doing with input files while it reports progress.
enum InputCopyStage { copying, extracting }

/// Progress of copying or extracting input files into the app.
class InputCopyProgress {
  const InputCopyProgress({
    required this.copied,
    required this.total,
    this.bytesCopied = 0,
    this.bytesTotal = 0,
    this.stage = InputCopyStage.copying,
    this.onCancel,
  });

  /// Copying has started but the file count is not known yet.
  const InputCopyProgress.preparing({
    this.stage = InputCopyStage.copying,
    this.onCancel,
  })  : copied = 0,
        total = 0,
        bytesCopied = 0,
        bytesTotal = 0;

  /// Reads a progress event sent by the native mobile channel. Keys that
  /// are missing count as unknown.
  factory InputCopyProgress.fromEvent(
    Map<Object?, Object?> data, {
    VoidCallback? onCancel,
  }) {
    return InputCopyProgress(
      copied: _asInt(data['copied']),
      total: _asInt(data['total']),
      bytesCopied: _asInt(data['bytesCopied']),
      bytesTotal: _asInt(data['bytesTotal']),
      onCancel: onCancel,
    );
  }

  /// Files done and files to do. [total] is zero while counting.
  final int copied;
  final int total;

  /// Bytes done and bytes to do. [bytesTotal] is zero when sizes are
  /// unknown, and then progress follows the file count.
  final int bytesCopied;
  final int bytesTotal;

  final InputCopyStage stage;

  /// Stops the copy, or null when it cannot stop.
  final VoidCallback? onCancel;

  bool get canCancel => onCancel != null;

  /// Whether nothing is known about the amount of work yet.
  bool get isCounting => total == 0 && bytesTotal == 0;

  /// Share done, by bytes when sizes are known, else by files, else null.
  double? get fraction {
    if (bytesTotal > 0) {
      return (bytesCopied / bytesTotal).clamp(0.0, 1.0);
    }
    if (total > 0) {
      return (copied / total).clamp(0.0, 1.0);
    }
    return null;
  }

  static int _asInt(Object? value) => value is num ? value.toInt() : 0;
}

/// Native file access on Android and iOS that the picker plugins lack:
/// folder selection and files shared to SEGUI from other apps.
///
/// iOS opens a picked folder in place with security-scoped access, so
/// nothing is copied. Android folders are content URIs, not paths, so the
/// matching files are copied into [destination] with progress events.
class MobileIoChannel {
  MobileIoChannel._() {
    _channel.setMethodCallHandler(_handleCall);
  }

  static final MobileIoChannel instance = MobileIoChannel._();

  static const MethodChannel _channel = MethodChannel('segui/mobile_io');
  static const EventChannel _progressChannel =
      EventChannel('segui/mobile_io/progress');

  final StreamController<int> _sharedController =
      StreamController<int>.broadcast();

  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  /// The number of pending shared files, sent when files are shared to
  /// SEGUI while it is running.
  Stream<int> get onShared => _sharedController.stream;

  /// Copy progress while [pickFolder], [pickFiles], or [takeSharedFiles]
  /// copy files into the app.
  Stream<InputCopyProgress> get progress {
    return _progressChannel.receiveBroadcastStream().map((event) {
      return InputCopyProgress.fromEvent(
        event as Map<Object?, Object?>,
        onCancel: cancelCopy,
      );
    });
  }

  /// Lets the user pick a folder and returns a local folder holding its
  /// files, or null when the picker is dismissed. On Android, files whose
  /// extensions match [extensions] are copied into [destination].
  Future<Directory?> pickFolder({
    required List<String> extensions,
    required Directory destination,
  }) async {
    final String? path = await _channel.invokeMethod<String>('pickFolder', {
      'extensions': extensions,
      'destination': destination.path,
    });
    return path == null ? null : Directory(path);
  }

  /// Lets the user pick files and copies them into [destination] with
  /// progress events. Returns the copied paths and the number of picked
  /// files left out. Android leaves out names without [extensions], and an
  /// empty list keeps every file. iOS shows only files of
  /// [typeIdentifiers], or of [extensions] when there are none.
  Future<({List<String> paths, int skipped})> pickFiles({
    required bool multiple,
    required List<String> extensions,
    required Directory destination,
    List<String> typeIdentifiers = const [],
  }) async {
    final Map<Object?, Object?>? result =
        await _channel.invokeMethod<Map<Object?, Object?>>('pickFiles', {
      'multiple': multiple,
      'extensions': extensions,
      'typeIdentifiers': typeIdentifiers,
      'destination': destination.path,
    });
    if (result == null) {
      return (paths: const <String>[], skipped: 0);
    }
    final List<Object?> paths = result['paths'] as List<Object?>? ?? const [];
    return (
      paths: paths.whereType<String>().toList(),
      skipped: (result['skipped'] as num?)?.toInt() ?? 0,
    );
  }

  /// Stops a folder, file, or shared-file copy. Files copied so far are kept.
  Future<void> cancelCopy() async {
    await _channel.invokeMethod<void>('cancelCopy');
  }

  /// Ends access to the folders picked on iOS.
  Future<void> releaseFolders() async {
    await _channel.invokeMethod<void>('releaseFolders');
  }

  /// The number of files shared to SEGUI that have not been taken yet.
  Future<int> pendingSharedCount() async {
    return await _channel.invokeMethod<int>('pendingSharedCount') ?? 0;
  }

  /// Copies the pending shared files into [destination] and returns
  /// their paths. Shared files are taken only once.
  Future<List<String>> takeSharedFiles(Directory destination) async {
    final List<Object?>? paths = await _channel.invokeMethod<List<Object?>>(
      'takeSharedFiles',
      {'destination': destination.path},
    );
    return paths?.whereType<String>().toList() ?? [];
  }

  Future<void> _handleCall(MethodCall call) async {
    if (call.method == 'sharedFilesAvailable') {
      _sharedController.add(call.arguments as int? ?? 0);
    }
  }
}
