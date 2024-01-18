import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/services/types.dart';

part 'navigation.g.dart';

@Riverpod(keepAlive: true)
class TabSelection extends _$TabSelection {
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

@Riverpod(keepAlive: true)
class GenomicOperationSelection extends _$GenomicOperationSelection {
  @override
  GenomicOperationType build() {
    return GenomicOperationType.readSummary;
  }

  void setOperation(GenomicOperationType operation) {
    state = operation;
  }
}

@Riverpod(keepAlive: true)
class AlignmentOperationSelection extends _$AlignmentOperationSelection {
  @override
  AlignmentOperationType build() {
    return AlignmentOperationType.summary;
  }

  void setOperation(AlignmentOperationType operation) {
    state = operation;
  }
}

@Riverpod(keepAlive: true)
class SequenceOperationSelection extends _$SequenceOperationSelection {
  @override
  SequenceOperationType build() {
    return SequenceOperationType.extraction;
  }

  void setOperation(SequenceOperationType operation) {
    state = operation;
  }
}
