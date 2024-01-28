// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'io.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fileInputHash() => r'59503c99a20cacb3df1e8e98b1868c18d700b7e8';

/// See also [FileInput].
@ProviderFor(FileInput)
final fileInputProvider =
    AsyncNotifierProvider<FileInput, List<SegulInputFile>>.internal(
  FileInput.new,
  name: r'fileInputProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$fileInputHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FileInput = AsyncNotifier<List<SegulInputFile>>;
String _$fileOutputHash() => r'd6af37f5092e26a812c926ce9f2514fe5967ea6d';

/// The output directory.
/// This is use to store the output files.
///
/// Copied from [FileOutput].
@ProviderFor(FileOutput)
final fileOutputProvider =
    AsyncNotifierProvider<FileOutput, SegulOutputFile>.internal(
  FileOutput.new,
  name: r'fileOutputProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$fileOutputHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FileOutput = AsyncNotifier<SegulOutputFile>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
