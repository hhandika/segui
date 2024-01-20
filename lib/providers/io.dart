import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:segui/services/io.dart';

part 'io.g.dart';

@Riverpod(keepAlive: true)
class FileInput extends _$FileInput {
  @override
  FutureOr<List<SegulInputFile>> build() {
    return [];
  }

  Future<void> addFiles(List<SegulInputFile> inputFiles) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (inputFiles.isEmpty) {
        return [];
      }
      final files = [...inputFiles];
      return files;
    });
  }

  Future<void> addMoreFiles(List<SegulInputFile> inputFiles) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null) {
        return [];
      }
      final files = [...state.value!, ...inputFiles];
      return files;
    });
  }

  Future<void> removeFile(SegulInputFile file) async {
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
  Future<void> addFiles(Directory? outputDir) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (outputDir == null) {
        return SegulOutputFile.empty();
      }
      return SegulOutputFile.fromDirectory(outputDir);
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
      return SegulOutputFile.updateFiles(state.value!);
    });
  }
}
