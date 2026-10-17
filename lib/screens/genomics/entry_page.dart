import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/screens/genomics/contig.dart';
import 'package:segui/screens/genomics/maf_convert.dart';
import 'package:segui/screens/genomics/maf_summary.dart';
import 'package:segui/screens/genomics/read_summary.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/services/types.dart';

class GenomicPage extends ConsumerWidget {
  const GenomicPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operation = ref.watch(genomicOperationSelectionProvider);
    return SharedOperationPage(
      operation: operation,
      child: GenomicOptions(
        analysis: operation,
      ),
    );
  }
}

class GenomicOptions extends StatelessWidget {
  const GenomicOptions({super.key, required this.analysis});

  final GenomicOperationType analysis;

  @override
  Widget build(BuildContext context) {
    switch (analysis) {
      case GenomicOperationType.readSummary:
        return const ReadSummaryView();
      case GenomicOperationType.contigSummary:
        return const ContigView();
      case GenomicOperationType.mafConversion:
        return const MafConversionView();
      case GenomicOperationType.mafSummary:
        return const MafSummaryView();
    }
  }
}
