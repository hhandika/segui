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
    required this.filledIcon,
    required this.svgAsset,
  });

  final ToolCategory category;
  final Enum operation;
  final String title;
  final String description;

  /// Longer explanation shown in the tool page header.
  final String about;
  final IconData icon;

  /// Filled variant of [icon], used once the tool has input files.
  final IconData filledIcon;

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
  filledIcon: SeguiIcons.readSummaryFilled,
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
  filledIcon: SeguiIcons.contigSummaryFilled,
  svgAsset: 'assets/icons/contig_summary_outlined.svg',
);

const HomeTool mafConversionTool = HomeTool(
  category: ToolCategory.genomics,
  operation: GenomicOperationType.mafConversion,
  title: 'Convert MAF alignments',
  description: 'Turn whole-genome MAF blocks into per-locus FASTA or PHYLIP.',
  about: 'Convert Multiple Alignment Format (MAF) files into one alignment '
      'per locus. A BED file names each locus by the start position of the '
      'reference sequence.',
  icon: SeguiIcons.mafConvertOutlined,
  filledIcon: SeguiIcons.mafConvertFilled,
  svgAsset: 'assets/icons/maf_convert_outlined.svg',
);

const HomeTool concatenationTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.concatenation,
  title: 'Concatenate alignments',
  description: 'Merge locus alignments into a supermatrix with partitions.',
  about: 'Concatenate multiple alignments and generate a partition file for '
      'the concatenated alignment.',
  icon: SeguiIcons.concatenateOutlined,
  filledIcon: SeguiIcons.concatenateFilled,
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
  filledIcon: SeguiIcons.convertFilled,
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
  filledIcon: SeguiIcons.filterFilled,
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
  filledIcon: SeguiIcons.partitionFilled,
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
  filledIcon: SeguiIcons.splitFilled,
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
  filledIcon: SeguiIcons.alignmentSummaryFilled,
  svgAsset: 'assets/icons/alignment_summary_outlined.svg',
);

const HomeTool distanceTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.distance,
  title: 'Compute genetic distances',
  description: 'Pairwise p, JC69, K2P, TN93, or Poisson distance matrices.',
  about: 'Compute pairwise genetic distances between samples in each '
      'alignment. Writes one distance matrix per alignment and a summary '
      'of the distances across all alignments.',
  icon: SeguiIcons.distanceOutlined,
  filledIcon: SeguiIcons.distanceFilled,
  svgAsset: 'assets/icons/distance_outlined.svg',
);

const HomeTool trimmingTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.trimming,
  title: 'Trim alignments',
  description: 'Drop sites with too much missing data or too little signal.',
  about: 'Trim alignment sites by the proportion of missing data or by the '
      'count of parsimony informative sites.',
  icon: SeguiIcons.trimOutlined,
  filledIcon: SeguiIcons.trimFilled,
  svgAsset: 'assets/icons/trim_outlined.svg',
);

const HomeTool unalignmentTool = HomeTool(
  category: ToolCategory.alignment,
  operation: AlignmentOperationType.unalignment,
  title: 'Unalign sequences',
  description: 'Strip alignment gaps to get raw sequences for realignment.',
  about: 'Remove gaps from aligned sequences and write them as unaligned '
      'FASTA files, ready for realignment.',
  icon: SeguiIcons.unalignOutlined,
  filledIcon: SeguiIcons.unalignFilled,
  svgAsset: 'assets/icons/unalign_outlined.svg',
);

const HomeTool extractionTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.extraction,
  title: 'Extract sequences',
  description: 'Pull sequences out of alignments by ID list or regex.',
  about: 'Extract sequences from multiple files. Supports regex, text file, '
      'and semicolon-separated IDs.',
  icon: SeguiIcons.extractOutlined,
  filledIcon: SeguiIcons.extractFilled,
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
  filledIcon: SeguiIcons.extractIdFilled,
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
  filledIcon: SeguiIcons.removeFilled,
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
  filledIcon: SeguiIcons.renameFilled,
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
  filledIcon: SeguiIcons.translateFilled,
  svgAsset: 'assets/icons/translate_outlined.svg',
);

const HomeTool additionTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.addition,
  title: 'Add sequences',
  description: 'Append new samples to matching alignments or a single file.',
  about: 'Add sequences to destination files that share the same file name, '
      'or add every sequence to a single destination file. Output is an '
      'unaligned FASTA file.',
  icon: SeguiIcons.addOutlined,
  filledIcon: SeguiIcons.addFilled,
  svgAsset: 'assets/icons/add_outlined.svg',
);

const HomeTool sequenceFilteringTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.filtering,
  title: 'Filter sequences',
  description: 'Keep samples by sequence length or proportion of gaps.',
  about: 'Filter sequences inside each file by minimum or maximum sequence '
      'length without gaps, or by the maximum proportion of gaps.',
  icon: SeguiIcons.sequenceFilterOutlined,
  filledIcon: SeguiIcons.sequenceFilterFilled,
  svgAsset: 'assets/icons/sequence_filter_outlined.svg',
);

const HomeTool transpositionTool = HomeTool(
  category: ToolCategory.sequence,
  operation: SequenceOperationType.transposition,
  title: 'Transpose sequences',
  description: 'Turn locus alignments into one file of loci per sample.',
  about: 'Transpose locus alignments into per-sample files. Each output file '
      'holds one sample, with one sequence for each locus it appears in.',
  icon: SeguiIcons.transposeOutlined,
  filledIcon: SeguiIcons.transposeFilled,
  svgAsset: 'assets/icons/transpose_outlined.svg',
);

/// Every tool available in SEGUI, grouped by category.
const List<HomeTool> homeTools = [
  readSummaryTool,
  contigSummaryTool,
  mafConversionTool,
  concatenationTool,
  conversionTool,
  distanceTool,
  filterTool,
  partitionTool,
  splitTool,
  alignmentSummaryTool,
  trimmingTool,
  unalignmentTool,
  additionTool,
  extractionTool,
  idExtractionTool,
  sequenceFilteringTool,
  removalTool,
  renamingTool,
  translationTool,
  transpositionTool,
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
  HomeWorkflow(
    title: 'Build loci from genome alignments',
    description: 'Split whole-genome MAF files into loci, then check '
        'and filter them.',
    steps: [mafConversionTool, alignmentSummaryTool, filterTool],
  ),
  HomeWorkflow(
    title: 'Prepare loci for realignment',
    description: 'Drop short or gappy sequences, then strip the remaining '
        'gaps before realigning.',
    steps: [sequenceFilteringTool, unalignmentTool],
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

/// Tool open on the current navigation page, or null on the home page.
final currentToolProvider = Provider<HomeTool?>((ref) {
  return switch (ref.watch(tabSelectionProvider)) {
    1 => homeToolFor(ref.watch(genomicOperationSelectionProvider)),
    2 => homeToolFor(ref.watch(alignmentOperationSelectionProvider)),
    3 => homeToolFor(ref.watch(sequenceOperationSelectionProvider)),
    _ => null,
  };
});

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
