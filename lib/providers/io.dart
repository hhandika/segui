import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:segui/services/io.dart';

part 'io.g.dart';

@Riverpod(keepAlive: true)
class FileInput extends _$FileInput {
  @override
  FutureOr<List<SegulInputFile>> build() {
    return [];
  }

  Future<void> addFiles(List<XFile> inputFiles, XTypeGroup xTypeGroup) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (inputFiles.isEmpty) {
        return [];
      }
      final files = inputFiles.map((file) {
        return SegulInputFile.fromXFile(file, xTypeGroup);
      }).toList();
      return files;
    });
  }

  Future<void> addMoreFiles(
      List<XFile> inputFiles, XTypeGroup xTypeGroup) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null) {
        return [];
      }
      final files = [...state.value!];
      files.addAll(inputFiles.map((file) {
        return SegulInputFile.fromXFile(file, xTypeGroup);
      }));
      return files;
    });
  }

  Future<void> removeFromList(SegulInputFile file) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null) {
        return [];
      }
      final files = [...state.value!];
      files.remove(file);
      return files;
    });
  }
}

/// The output directory.
/// This is use to store the output files.
@Riverpod(keepAlive: true)
class FileOutput extends _$FileOutput {
  @override
  FutureOr<SegulOutputFile> build() {
    return SegulOutputFile.empty();
  }

  /// Add the files in the output directory.
  /// This is use after the use selects the output directory.
  Future<void> add(Directory? outputDir) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (outputDir == null) {
        return SegulOutputFile.empty();
      }
      return SegulOutputFile.fromDirectory(outputDir, isRecursive: false);
    });
  }

  /// Add files for mobile iOS and Android.
  /// Android and iOS does not allow to write
  /// files outside the app directory.
  /// So we save the files in the app directory
  Future<void> addMobile(
    String? dirName,
    SupportedTask task,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      Directory dir = await getOutputDir(dirName, task);
      return SegulOutputFile.fromDirectory(dir, isRecursive: false);
    });
  }

  Future<void> addFromAppDir() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      Directory dir = await getSeguiDirectory();
      return SegulOutputFile.fromDirectory(dir, isRecursive: false);
    });
  }

  /// Update the files in the output directory.
  /// This is use after the use executes a task.
  /// We can also do stream with `FileEntity().watch`
  /// to update the file list.
  /// But it may slow down the task execution.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null || state.value!.directory == null) {
        return SegulOutputFile.empty();
      }
      final updates =
          SegulOutputFile.updateFiles(state.value!, isRecursive: false);

      return updates;
    });
  }

  Future<void> removeFile(File file) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null) {
        return SegulOutputFile.empty();
      }
      final files = [...state.value!.files];
      files.removeWhere((f) => f.file.path == file.path);
      file.delete();
      return SegulOutputFile.deleteFile(state.value!, file);
    });
  }

  Future<void> removeAllFiles() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null) {
        return SegulOutputFile.empty();
      }
      final files = state.value!.files.map((f) => f.file).toList();
      final log = await FileCleaningService().removeAllFiles(files);
      if (log != null) {
        return SegulOutputFile.refresh(state.value!, [log]);
      }
      return SegulOutputFile.empty();
    });
  }
}
