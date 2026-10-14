import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/services/types.dart';

/// Tool groups shown on the home screen, in navigation tab order.
enum ToolCategory {
  genomics('Genomics', 'Raw reads and assemblies', 1),
  alignment('Alignments', 'Multi-locus alignment matrices', 2),
  sequence('Sequences', 'Samples and IDs inside alignments', 3);

  const ToolCategory(this.label, this.description, this.tabIndex);

  final String label;
  final String description;

  /// Index of the matching page in the main navigation.
  final int tabIndex;
}

/// A SEGUI tool listed on the home screen.
///
/// [operation] is a [GenomicOperationType], [AlignmentOperationType], or
/// [SequenceOperationType] that matches [category].
class HomeTool {
  const HomeTool({
    required this.category,
    required this.operation,
    required this.title,
    required this.description,
    required this.icon,
  });

  final ToolCategory category;
  final Enum operation;
  final String title;
  final String description;
  final IconData icon;

  /// Whether the tool matches a case-insensitive search [query].
  bool matches(String query) {
    final String term = query.trim().toLowerCase();
    if (term.isEmpty) {
      return true;
    }
    return title.toLowerCase().contains(term) ||
        description.toLowerCase().contains(term) ||
        category.label.toLowerCase().contains(term);
  }
}

/// A common task that chains several tools in order.
class HomeWorkflow {
  const HomeWorkflow({
    required this.title,
    required this.description,
    required this.steps,
  });

  final String title;
  final String description;
  final List<HomeTool> steps;
}

const HomeTool readSummaryTool = HomeTool(
  category: ToolCategory.genomics,
  operation: GenomicOperationType.readSummary,
  title: 'Summarize genomic reads',
  description: 'FASTQ quality: read counts, length, GC content, and Q-scores.',
  icon: Icons.analytics_outlined,
);

const HomeTool contigSummaryTool = HomeTool(
  category: ToolCategory.genomics,
  operation: GenomicOperationType.contigSummary,
  title: 'Summarize genomic contigs',
  description: 'Contig counts, N50, length, and GC content for assemblies.',
  icon: Icons.segment,
);

const HomeTool concatenationTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.concatenation,
  title: 'Concatenate alignments',
  description: 'Merge locus alignments into a supermatrix with partitions.',
  icon: Icons.compare_arrows,
);

const HomeTool conversionTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.conversion,
  title: 'Convert alignments',
  description: 'Switch alignments between FASTA, NEXUS, and PHYLIP.',
  icon: Icons.swap_horiz,
);

const HomeTool filterTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.filter,
  title: 'Filter alignments',
  description: 'Keep loci by taxon coverage, length, or informative sites.',
  icon: Icons.filter_alt_outlined,
);

const HomeTool partitionTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.partition,
  title: 'Convert partition',
  description: 'Convert between RAxML, NEXUS, and charset partitions.',
  icon: Icons.view_column_outlined,
);

const HomeTool splitTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.split,
  title: 'Split alignments',
  description: 'Break a concatenated matrix back into individual loci.',
  icon: Icons.call_split,
);

const HomeTool alignmentSummaryTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.summary,
  title: 'Summarize alignments',
  description: 'Missing data, informative sites, GC, and length statistics.',
  icon: Icons.bar_chart,
);

const HomeTool extractionTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.extraction,
  title: 'Extract sequences',
  description: 'Pull sequences out of alignments by ID list or regex.',
  icon: Icons.output,
);

const HomeTool idExtractionTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.idExtraction,
  title: 'Extract and map sequence IDs',
  description: 'List unique sample IDs and the files each one appears in.',
  icon: Icons.badge_outlined,
);

const HomeTool removalTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.removal,
  title: 'Remove sequences',
  description: 'Drop samples by ID or regex across many alignments.',
  icon: Icons.remove_circle_outline,
);

const HomeTool renamingTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.renaming,
  title: 'Rename sequence IDs',
  description: 'Rename samples from a mapping file or a text pattern.',
  icon: Icons.drive_file_rename_outline,
);

const HomeTool translationTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.translation,
  title: 'Translate sequences',
  description: 'Translate DNA to amino acids with NCBI genetic codes.',
  icon: Icons.translate,
);

/// Every tool available in SEGUI, grouped by category.
const List<HomeTool> homeTools = [
  readSummaryTool,
  contigSummaryTool,
  concatenationTool,
  conversionTool,
  filterTool,
  partitionTool,
  splitTool,
  alignmentSummaryTool,
  extractionTool,
  idExtractionTool,
  removalTool,
  renamingTool,
  translationTool,
];

const List<HomeWorkflow> homeWorkflows = [
  HomeWorkflow(
    title: 'Build a phylogenomic supermatrix',
    description: 'Check loci, drop poorly sampled ones, then concatenate '
        'them with a partition file.',
    steps: [alignmentSummaryTool, filterTool, concatenationTool],
  ),
  HomeWorkflow(
    title: 'Check a sequencing run',
    description: 'Get read quality and assembly statistics before alignment.',
    steps: [readSummaryTool, contigSummaryTool],
  ),
  HomeWorkflow(
    title: 'Clean up sample names',
    description: 'Find every sample ID across files, then rename them '
        'consistently.',
    steps: [idExtractionTool, renamingTool],
  ),
  HomeWorkflow(
    title: 'Drop failed or contaminated samples',
    description: 'Remove samples from many alignments at once, then '
        're-check coverage.',
    steps: [removalTool, alignmentSummaryTool],
  ),
  HomeWorkflow(
    title: 'Reformat for another program',
    description: 'Move alignments and partitions between FASTA, NEXUS, '
        'PHYLIP, and RAxML formats.',
    steps: [conversionTool, partitionTool],
  ),
  HomeWorkflow(
    title: 'Work with protein data',
    description: 'Translate coding loci, then subset the samples you need.',
    steps: [translationTool, extractionTool],
  ),
];

/// Tools in [category] that match the search [query].
List<HomeTool> filterHomeTools(ToolCategory category, String query) {
  return homeTools
      .where((tool) => tool.category == category && tool.matches(query))
      .toList();
}

/// All tools sorted alphabetically by title.
List<HomeTool> get sortedHomeTools {
  return [...homeTools]..sort((a, b) => a.title.compareTo(b.title));
}

final homeToolNavigatorProvider =
    Provider<HomeToolNavigator>((ref) => HomeToolNavigator(ref));

/// Opens home screen tools on their navigation page.
class HomeToolNavigator {
  const HomeToolNavigator(this._ref);

  final Ref _ref;

  /// Switches to the page for [tool] and selects its operation.
  void open(HomeTool tool) {
    _ref.read(tabSelectionProvider.notifier).setTab(tool.category.tabIndex);
    final Enum operation = tool.operation;
    if (operation is GenomicOperationType) {
      _ref
          .read(genomicOperationSelectionProvider.notifier)
          .setOperation(operation);
    } else if (operation is AlignmentOperationType) {
      _ref
          .read(alignmentOperationSelectionProvider.notifier)
          .setOperation(operation);
    } else if (operation is SequenceOperationType) {
      _ref
          .read(sequenceOperationSelectionProvider.notifier)
          .setOperation(operation);
    }
  }
}
