import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/types.dart';

final tabSelectionProvider =
    NotifierProvider<TabSelection, int>(TabSelection.new);

class TabSelection extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void setTab(int selectedIndex) {
    state = selectedIndex;
    ref.invalidate(fileInputProvider);
    ref.invalidate(fileOutputProvider);
  }
}

final genomicOperationSelectionProvider =
    NotifierProvider<GenomicOperationSelection, GenomicOperationType>(
        GenomicOperationSelection.new);

class GenomicOperationSelection extends Notifier<GenomicOperationType> {
  @override
  GenomicOperationType build() {
    return GenomicOperationType.readSummary;
  }

  void setOperation(GenomicOperationType operation) {
    state = operation;
  }
}

final alignmentOperationSelectionProvider =
    NotifierProvider<AlignmentOperationSelection, AlignmentOperationType>(
        AlignmentOperationSelection.new);

class AlignmentOperationSelection extends Notifier<AlignmentOperationType> {
  @override
  AlignmentOperationType build() {
    return AlignmentOperationType.concatenation;
  }

  void setOperation(AlignmentOperationType operation) {
    state = operation;
  }
}

final sequenceOperationSelectionProvider =
    NotifierProvider<SequenceOperationSelection, SequenceOperationType>(
        SequenceOperationSelection.new);

class SequenceOperationSelection extends Notifier<SequenceOperationType> {
  @override
  SequenceOperationType build() {
    return SequenceOperationType.extraction;
  }

  void setOperation(SequenceOperationType operation) {
    state = operation;
  }
}
