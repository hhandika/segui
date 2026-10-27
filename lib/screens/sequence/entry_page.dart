import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/screens/sequence/add.dart';
import 'package:segui/screens/sequence/extract.dart';
import 'package:segui/screens/sequence/filter.dart';
import 'package:segui/screens/sequence/remove.dart';
import 'package:segui/screens/sequence/rename.dart';
import 'package:segui/screens/sequence/sequence_id.dart';
import 'package:segui/screens/sequence/translate.dart';
import 'package:segui/screens/sequence/transpose.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/services/types.dart';

class SequencePage extends ConsumerWidget {
  const SequencePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operation = ref.watch(sequenceOperationSelectionProvider);
    return SharedOperationPage(
      operation: operation,
      child: SequenceOptions(analysis: operation),
    );
  }
}

class SequenceOptions extends StatelessWidget {
  const SequenceOptions({super.key, required this.analysis});

  final SequenceOperationType analysis;

  @override
  Widget build(BuildContext context) {
    switch (analysis) {
      case SequenceOperationType.extraction:
        return const ExtractSequenceView();
      case SequenceOperationType.removal:
        return const SequenceRemovalView();
      case SequenceOperationType.renaming:
        return const SequenceRenamingView();
      case SequenceOperationType.idExtraction:
        return const IDExtractionView();
      case SequenceOperationType.translation:
        return const TranslateView();
      case SequenceOperationType.addition:
        return const SequenceAdditionView();
      case SequenceOperationType.filtering:
        return const SequenceFilteringView();
      case SequenceOperationType.transposition:
        return const SequenceTranspositionView();
    }
  }
}
