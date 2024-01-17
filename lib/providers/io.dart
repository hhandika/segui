import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'io.g.dart';

@Riverpod(keepAlive: true)
class FileInput extends _$FileInput {
  @override
  FutureOr<List<XFile>> build() {
    return [];
  }

  Future<void> addFiles(List<XFile> inputFiles) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (inputFiles.isEmpty) {
        return [];
      }
      final files = [...inputFiles];
      return files;
    });
  }

  Future<void> addMoreFiles(List<XFile> inputFiles) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null) {
        return [];
      }
      final files = [...state.value!, ...inputFiles];
      return files;
    });
  }

  Future<void> removeFile(XFile file) async {
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

  Future<void> clear() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return [];
    });
  }
}

@Riverpod(keepAlive: true)
class FileOutput extends _$FileOutput {
  @override
  FutureOr<List<XFile>> build() {
    return [];
  }

  Future<void> addFiles(Directory? outputDir) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (outputDir == null) {
        return [];
      }
      // find all files in the directory
      final files = await outputDir.list().toList();
      // filter out directories
      final filesFiltered = files.whereType<File>().toList();
      // cast to XFile
      final filesCasted =
          filesFiltered.map((file) => XFile(file.path)).toList();
      return filesCasted;
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null) {
        return [];
      }
      final files = [...state.value!];
      return files;
    });
  }

  Future<void> clear() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return [];
    });
  }
}
