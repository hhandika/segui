// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'io.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fileInputHash() => r'c39722717988ff838a967d962283ff118bb25c99';

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
String _$fileOutputHash() => r'2298daa901c590f5fc3df8e2675d633601591266';

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
