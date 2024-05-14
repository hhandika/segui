// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'io.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fileInputHash() => r'89b6e5e1ee1230686dca87b74b8ce0bcc41be05b';

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
String _$fileOutputHash() => r'9138266e3063e54e74def5e4dce6d5a9a2303f12';

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
