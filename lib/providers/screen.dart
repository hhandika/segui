import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:segui/services/types.dart';

part 'screen.g.dart';

@Riverpod(keepAlive: true)
class TabSelection extends _$TabSelection {
  @override
  int build() {
    return 0;
  }

  void setTab(int selectedIndex) {
    state = selectedIndex;
  }
}

@Riverpod(keepAlive: true)
class OperationSelection extends _$OperationSelection {
  @override
  OperationType build() {
    return OperationType.none;
  }

  void setOperation(OperationType operation) {
    state = operation;
  }
}
