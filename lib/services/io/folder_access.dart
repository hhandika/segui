import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Folders the macOS sandbox lets SEGUI open again after a restart.
///
/// The sandbox allows a folder only for the session in which the user
/// picks it. The native side saves a security-scoped bookmark for each
/// folder here, so macOS asks once per folder. Access to a folder covers
/// everything inside it. Other platforms need none of this, so every
/// method does nothing there.
class FolderAccessChannel {
  const FolderAccessChannel._();

  static const FolderAccessChannel instance = FolderAccessChannel._();

  static const MethodChannel _channel = MethodChannel('segui/folder_access');

  static bool get isSupported => Platform.isMacOS;

  /// Starts access to the saved folders and returns those still available.
  /// Call once at startup.
  Future<List<String>> restore() => _invokeList('restore');

  /// The saved folders.
  Future<List<String>> list() => _invokeList('list');

  /// Saves the folders in [paths] that the app can open now. Files and
  /// folders outside the sandbox's reach are skipped. Returns the saved
  /// folders.
  Future<List<String>> remember(Iterable<String> paths) {
    final List<String> folders = paths.toList();
    if (folders.isEmpty) {
      return Future.value(const []);
    }
    return _invokeList('remember', {'paths': folders});
  }

  /// Asks the user to choose a folder, starting at [initialPath] or the
  /// home folder, and saves it. Returns null when the user cancels.
  Future<String?> grant({String? initialPath}) async {
    if (!isSupported) {
      return null;
    }
    return await _channel.invokeMethod<String>('grant', {
      if (initialPath != null) 'initialPath': initialPath,
    });
  }

  /// Ends access to [path] and removes it from the saved folders.
  Future<void> forget(String path) async {
    if (!isSupported) {
      return;
    }
    await _channel.invokeMethod<void>('forget', {'path': path});
  }

  Future<List<String>> _invokeList(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    if (!isSupported) {
      return const [];
    }
    try {
      final List<Object?>? result =
          await _channel.invokeListMethod<Object?>(method, arguments);
      return result?.whereType<String>().toList() ?? const [];
    } on MissingPluginException {
      // Widget tests run without the native side.
      return const [];
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Folder access $method failed: $e');
      }
      return const [];
    }
  }
}
