import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/navigation.dart';
import 'package:segui/screens/genomics/contig.dart';
import 'package:segui/screens/genomics/read_summary.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/services/types.dart';

class GenomicPage extends ConsumerStatefulWidget {
  const GenomicPage({super.key});

  @override
  GenomicPageState createState() => GenomicPageState();
}

class GenomicPageState extends ConsumerState<GenomicPage> {
  @override
  Widget build(BuildContext context) {
    return const SharedOperationPage(
      child: GenomicContentPage(),
    );
  }
}

class GenomicContentPage extends ConsumerWidget {
  const GenomicContentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormView(children: [
      DropdownButton<GenomicOperationType>(
        isExpanded: true,
        value: ref.watch(genomicOperationSelectionProvider),
        items: genomicOperationMap.entries
            .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                ))
            .toList(),
        onChanged: (GenomicOperationType? value) {
          if (value != null) {
            ref
                .read(genomicOperationSelectionProvider.notifier)
                .setOperation(value);
          }
        },
      ),
      const SizedBox(height: 8),
      GenomicOptions(
        analysis: ref.watch(genomicOperationSelectionProvider),
      ),
    ]);
  }
}

class GenomicOptions extends StatelessWidget {
  const GenomicOptions({super.key, required this.analysis});

  final GenomicOperationType analysis;

  @override
  Widget build(BuildContext context) {
    switch (analysis) {
      case GenomicOperationType.readSummary:
        return const ReadSummaryPage();
      case GenomicOperationType.contigSummary:
        return const ContigPage();
      default:
        return const SizedBox();
    }
  }
}
