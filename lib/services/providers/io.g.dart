// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'io.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fileInputHash() => r'4e4ac0db307cfe0c2a0da4d031809fed4dc1fbc6';

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
String _$fileOutputHash() => r'5d2643f0a0090f14ef20e20433aeef1b1359566e';

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
