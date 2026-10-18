import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Progress of copying input files into the app.
class InputCopyProgress {
  const InputCopyProgress({required this.copied, required this.total});

  /// Copying has started but the file count is not known yet.
  const InputCopyProgress.preparing()
      : copied = 0,
        total = 0;

  final int copied;
  final int total;

  bool get isCounting => total == 0;

  double? get fraction => isCounting ? null : copied / total;
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

  /// Copy progress while [pickFolder] copies an Android folder.
  Stream<InputCopyProgress> get progress {
    return _progressChannel.receiveBroadcastStream().map((event) {
      final Map<Object?, Object?> data = event as Map<Object?, Object?>;
      return InputCopyProgress(
        copied: data['copied'] as int? ?? 0,
        total: data['total'] as int? ?? 0,
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

  /// Stops an Android folder copy. Files copied so far are kept.
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
