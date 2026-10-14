import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/services/types.dart';
import 'package:segui/styles/segui_icons.dart';

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
    required this.about,
    required this.icon,
    required this.svgAsset,
  });

  final ToolCategory category;
  final Enum operation;
  final String title;
  final String description;

  /// Longer explanation shown in the tool page header.
  final String about;
  final IconData icon;

  /// SVG source of [icon], drawn on tool cards.
  final String svgAsset;

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
  about: 'Summarize raw genomic reads by calculating the number of reads, '
      'base counts, GC and AT content, low Q-score counts, and other '
      'relevant statistics.',
  icon: SeguiIcons.readSummaryOutlined,
  svgAsset: 'assets/icons/read_summary_outlined.svg',
);

const HomeTool contigSummaryTool = HomeTool(
  category: ToolCategory.genomics,
  operation: GenomicOperationType.contigSummary,
  title: 'Summarize genomic contigs',
  description: 'Contig counts, N50, length, and GC content for assemblies.',
  about: 'Summarize contigs by calculating the number of contigs, total '
      'length, base count, N50, and other relevant statistics.',
  icon: SeguiIcons.contigSummaryOutlined,
  svgAsset: 'assets/icons/contig_summary_outlined.svg',
);

const HomeTool concatenationTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.concatenation,
  title: 'Concatenate alignments',
  description: 'Merge locus alignments into a supermatrix with partitions.',
  about: 'Concatenate multiple alignments and generate a partition file for '
      'the concatenated alignment.',
  icon: SeguiIcons.concatenateOutlined,
  svgAsset: 'assets/icons/concatenate_outlined.svg',
);

const HomeTool conversionTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.conversion,
  title: 'Convert alignments',
  description: 'Switch alignments between FASTA, NEXUS, and PHYLIP.',
  about: 'Convert sequence alignments to other formats. It can convert '
      'multiple files at once.',
  icon: SeguiIcons.convertOutlined,
  svgAsset: 'assets/icons/convert_outlined.svg',
);

const HomeTool filterTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.filter,
  title: 'Filter alignments',
  description: 'Keep loci by taxon coverage, length, or informative sites.',
  about: 'Filter alignments by minimal alignment length, data matrix '
      'completeness, count of parsimony informative sites, and percentage '
      'of parsimony informative sites.',
  icon: SeguiIcons.filterOutlined,
  svgAsset: 'assets/icons/filter_outlined.svg',
);

const HomeTool partitionTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.partition,
  title: 'Convert partition',
  description: 'Convert between RAxML, NEXUS, and charset partitions.',
  about: 'Convert partition files to a different format. It can convert '
      'multiple files at once.',
  icon: SeguiIcons.partitionOutlined,
  svgAsset: 'assets/icons/partition_outlined.svg',
);

const HomeTool splitTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.split,
  title: 'Split alignments',
  description: 'Break a concatenated matrix back into individual loci.',
  about: 'Split a concatenated alignment into multiple files based on its '
      'partitions. The partition can be in a separate RAxML or NEXUS file, '
      'or in the same file as a charset block.',
  icon: SeguiIcons.splitOutlined,
  svgAsset: 'assets/icons/split_outlined.svg',
);

const HomeTool alignmentSummaryTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.summary,
  title: 'Summarize alignments',
  description: 'Missing data, informative sites, GC, and length statistics.',
  about: 'Summarize alignments by calculating the number of sequences, sites, '
      'parsimony informative sites, and other relevant statistics.',
  icon: SeguiIcons.alignmentSummaryOutlined,
  svgAsset: 'assets/icons/alignment_summary_outlined.svg',
);

const HomeTool extractionTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.extraction,
  title: 'Extract sequences',
  description: 'Pull sequences out of alignments by ID list or regex.',
  about: 'Extract sequences from multiple files. Supports regex, text file, '
      'and semicolon-separated IDs.',
  icon: SeguiIcons.extractOutlined,
  svgAsset: 'assets/icons/extract_outlined.svg',
);

const HomeTool idExtractionTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.idExtraction,
  title: 'Extract and map sequence IDs',
  description: 'List unique sample IDs and the files each one appears in.',
  about: 'Extract unique IDs across multiple sequence files. The output file '
      'is a list of unique sequence IDs. The map option maps sample '
      'distribution across the input dataset.',
  icon: SeguiIcons.extractIdOutlined,
  svgAsset: 'assets/icons/extract_id_outlined.svg',
);

const HomeTool removalTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.removal,
  title: 'Remove sequences',
  description: 'Drop samples by ID or regex across many alignments.',
  about: 'Remove sequences from a collection of sequence files based on '
      'sequence name. Supports regular expressions.',
  icon: SeguiIcons.removeOutlined,
  svgAsset: 'assets/icons/remove_outlined.svg',
);

const HomeTool renamingTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.renaming,
  title: 'Rename sequence IDs',
  description: 'Rename samples from a mapping file or a text pattern.',
  about: 'Rename sequence IDs across a collection of sequence files. Supports '
      'file, text, and regular expression input.',
  icon: SeguiIcons.renameOutlined,
  svgAsset: 'assets/icons/rename_outlined.svg',
);

const HomeTool translationTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.translation,
  title: 'Translate sequences',
  description: 'Translate DNA to amino acids with NCBI genetic codes.',
  about: 'Translate nucleotide sequences to amino acid sequences. It can '
      'translate multiple files at once.',
  icon: SeguiIcons.translateOutlined,
  svgAsset: 'assets/icons/translate_outlined.svg',
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

/// The tool that runs [operation].
HomeTool homeToolFor(Enum operation) {
  return homeTools.firstWhere((tool) => tool.operation == operation);
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
