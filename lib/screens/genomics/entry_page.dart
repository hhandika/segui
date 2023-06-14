import 'package:flutter/material.dart';
import 'package:segui/screens/genomics/contig.dart';
import 'package:segui/screens/genomics/read_summary.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/types.dart';

class SeqReadPage extends StatefulWidget {
  const SeqReadPage({super.key});

  @override
  State<SeqReadPage> createState() => _SeqReadPageState();
}

class _SeqReadPageState extends State<SeqReadPage> {
  GenomicOperationType analysisType = GenomicOperationType.readSummary;
  @override
  Widget build(BuildContext context) {
    return FormView(children: [
      DropdownButton<GenomicOperationType>(
        isExpanded: true,
        value: analysisType,
        items: genomicOperationMap.entries
            .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                ))
            .toList(),
        onChanged: (GenomicOperationType? value) {
          setState(() {
            if (value != null) {
              analysisType = value;
            }
          });
        },
      ),
      const SizedBox(height: 20),
      GenomicOptions(
        analysis: analysisType,
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
