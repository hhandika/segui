// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tabSelectionHash() => r'd6653938964e30aa9d73a8dd1512a8cb91ff08ff';

/// See also [TabSelection].
@ProviderFor(TabSelection)
final tabSelectionProvider = NotifierProvider<TabSelection, int>.internal(
  TabSelection.new,
  name: r'tabSelectionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tabSelectionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TabSelection = Notifier<int>;
String _$operationSelectionHash() =>
    r'731bf5da9fc0436bd99ecdf619a25122ae7826cd';

/// See also [OperationSelection].
@ProviderFor(OperationSelection)
final operationSelectionProvider =
    NotifierProvider<OperationSelection, OperationType>.internal(
  OperationSelection.new,
  name: r'operationSelectionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$operationSelectionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OperationSelection = Notifier<OperationType>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
