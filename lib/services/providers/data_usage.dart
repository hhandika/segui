import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/io/data_usage.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/providers/io.dart';

/// Folders and files in SEGUI's data folder, read again each time the data
/// usage page opens.
final dataUsageProvider =
    AsyncNotifierProvider.autoDispose<DataUsage, DataUsageTree>(DataUsage.new);

class DataUsage extends AsyncNotifier<DataUsageTree> {
  @override
  Future<DataUsageTree> build() async {
    final Directory dir = await getSeguiDirectory();
    // Run folders can hold thousands of files, so read them off the UI
    // thread.
    return Isolate.run(() => DataUsageTree.fromDirectory(dir));
  }

  /// Deletes [entities], with everything inside the folders among them.
  /// [files] are every file deleted.
  Future<void> delete(
    List<FileSystemEntity> entities,
    List<File> files,
  ) async {
    final Directory dir = await getSeguiDirectory();
    final DataUsageCleaner cleaner = DataUsageCleaner(root: dir);
    for (final FileSystemEntity entity in entities) {
      await cleaner.delete(entity);
    }
    // Drop the deleted files from the output list as well.
    await ref.read(fileOutputProvider.notifier).deleteFiles(files);
    await reload();
  }

  /// Deletes everything except the latest log file.
  Future<void> clearAll() async {
    final Directory dir = await getSeguiDirectory();
    await DataUsageCleaner(root: dir).clearAll();
    ref.invalidate(fileOutputProvider);
    await reload();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(build);
  }
}
