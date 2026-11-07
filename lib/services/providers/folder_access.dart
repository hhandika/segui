import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/io/folder_access.dart';

/// Folders SEGUI can open on macOS without asking again.
final folderAccessProvider =
    AsyncNotifierProvider<FolderAccess, List<String>>(FolderAccess.new);

class FolderAccess extends AsyncNotifier<List<String>> {
  FolderAccessChannel get _channel => FolderAccessChannel.instance;

  @override
  FutureOr<List<String>> build() => _channel.list();

  /// Asks the user for a folder to allow. Returns the folder, or null
  /// when the user cancels.
  Future<String?> grant() async {
    final String? path = await _channel.grant();
    if (path != null) {
      ref.invalidateSelf();
    }
    return path;
  }

  Future<void> forget(String path) async {
    await _channel.forget(path);
    ref.invalidateSelf();
  }
}
