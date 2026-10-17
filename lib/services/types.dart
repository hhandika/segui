enum PlatformType { isDesktop, isMobile }

enum GenomicOperationType {
  readSummary,
  contigSummary,
  mafConversion,
  mafSummary,
}

const Map<GenomicOperationType, String> genomicOperationMap = {
  GenomicOperationType.readSummary: 'Summarize genomic reads',
  GenomicOperationType.contigSummary: 'Summarize genomic contigs',
  GenomicOperationType.mafConversion: 'Convert MAF alignments',
  GenomicOperationType.mafSummary: 'Summarize MAF alignments',
};

const List<String> sequenceReadFormat = [
  'Auto',
  'FASTQ',
  'GZip',
];

const List<String> contigFormat = [
  'Auto',
  'FASTA',
  'GZip',
];

const List<String> sequenceReadSummaryMode = [
  'Default',
  'Minimal',
  'Complete',
];

enum AlignmentOperationType {
  concatenation,
  conversion,
  filter,
  partition,
  summary,
  split,
  distance,
  trimming,
  unalignment,
}

const Map<AlignmentOperationType, String> alignmentOperationMap = {
  AlignmentOperationType.concatenation: 'Concatenate alignments',
  AlignmentOperationType.conversion: 'Convert alignments',
  AlignmentOperationType.partition: 'Convert partition',
  AlignmentOperationType.filter: 'Filter alignments',
  AlignmentOperationType.split: 'Split alignments',
  AlignmentOperationType.summary: 'Summarize alignments',
  AlignmentOperationType.distance: 'Compute genetic distances',
  AlignmentOperationType.trimming: 'Trim alignments',
  AlignmentOperationType.unalignment: 'Unalign sequences',
};

enum SequenceOperationType {
  extraction,
  idExtraction,
  removal,
  renaming,
  translation,
  addition,
  filtering,
  transposition,
}

const Map<SequenceOperationType, String> sequenceOperationMap = {
  SequenceOperationType.extraction: 'Extract sequences',
  SequenceOperationType.idExtraction: 'Extract and map sequence IDs',
  SequenceOperationType.removal: 'Remove sequences',
  SequenceOperationType.renaming: 'Rename sequence IDs',
  SequenceOperationType.translation: 'Translate sequences',
  SequenceOperationType.addition: 'Add sequences',
  SequenceOperationType.filtering: 'Filter sequences',
  SequenceOperationType.transposition: 'Transpose sequences',
};

const List<String> inputFormat = [
  'Auto',
  'FASTA',
  'NEXUS',
  'PHYLIP',
];

const List<String> outputFormat = [
  'FASTA',
  'NEXUS',
  'PHYLIP',
];

enum PartitionFormat { charset, nexus, raxml }

const List<String> partitionFormat = [
  'Charset',
  'NEXUS',
  'RaXML',
];

const List<String> dataType = [
  'DNA',
  'AA',
  'Ignore',
];

const List<String> summaryInt = ["1", "2", "5", "10"];

/// Output formats for tasks that write unaligned sequences.
const List<String> fastaOutputFormat = ['FASTA'];

/// Output formats for MAF conversion.
const List<String> mafOutputFormat = ['FASTA', 'NEXUS', 'PHYLIP'];

/// How MAF blocks are grouped without a BED file, keyed by the SEGUL value.
const Map<String, String> mafGroupingOptions = {
  'block': 'One file per block',
  'chrom': 'One file per chromosome',
};

/// Pairwise distance models, keyed by the SEGUL model name.
const Map<String, String> distanceModels = {
  'p': 'Uncorrected p-distance',
  'jc69': 'Jukes-Cantor (JC69)',
  'k2p': 'Kimura 2-parameter (K2P), DNA only',
  'tn93': 'Tamura-Nei (TN93), DNA only',
  'poisson': 'Poisson, amino acid only',
};

/// Distance models that SEGUL accepts for [datatype].
List<String> distanceModelsFor(String datatype) {
  switch (datatype) {
    case 'DNA':
      return const ['p', 'jc69', 'k2p', 'tn93'];
    case 'AA':
      return const ['p', 'jc69', 'poisson'];
    default:
      return const [];
  }
}

/// Distance matrix triangles, keyed by the SEGUL option name.
const Map<String, String> distanceMatrixTriangles = {
  'full': 'Full matrix',
  'lower': 'Lower triangle',
  'upper': 'Upper triangle',
};

/// Distance matrix diagonals, keyed by the SEGUL option name.
const Map<String, String> distanceMatrixDiagonals = {
  'zero': 'Zero',
  'blank': 'Blank',
  'max': 'Highest distance in the row',
};

/// Group mean matrix diagonals, keyed by the SEGUL option name.
const Map<String, String> distanceGroupDiagonals = {
  'within': 'Mean within the group',
  'zero': 'Zero',
  'blank': 'Blank',
  'max': 'Highest mean in the row',
};

/// Ways to assign samples to groups, such as populations or species,
/// for group mean distances.
const Map<String, String> distanceGroupingMethods = {
  'none': 'No grouping',
  'auto': 'Detect from sample names',
  'delimiter': 'Split sample names',
  'regex': 'Regular expression',
  'file': 'Group file (CSV or TSV)',
};

const List<String> readingFrame = ["1", "2", "3"];

const List<String> translationTable = [
  "Standard Code", // Table 1
  "Vertebrate Mitochondrial Code", // Table 2
  "Yeast Mitochondrial Code", // Table 3
  "Mold, Protozoan, and Coelenterate Mitochondrial Code and the Mycoplasma/Spiroplasma Code", // Table 4
  "Invertebrate Mitochondrial Code", // Table 5
  "Ciliate, Dasycladacean and Hexamita Nuclear Code", // Table 6
  "Echinoderm and Flatworm Mitochondrial Code", // Table 9
  "Euplotid Nuclear Code", // Table 10
  "Bacterial, Archaeal and Plant Plastid Code", // Table 11
  "Alternative Yeast Nuclear Code", // Table 12
  "Ascidian Mitochondrial Code", // Table 13
  "Alternative Flatworm Mitochondrial Code", // Table 14
  "Chlorophycean Mitochondrial Code", // Table 16
  "Trematode Mitochondrial Code", // Table 21
  "Scenedesmus obliquus Mitochondrial Code", // Table 22
  "Thraustochytrium Mitochondrial Code", // Table 23
  "Rhabdopleuridae Mitochondrial Code", // Table 24
  "Candidate Division SR1 and Gracilibacteria Code", // Table 25
  "Pachysolen tannophilus Nuclear Code", // Table 26
  "Mesodinium Nuclear Code", // Table 29
  "Peritrich Nuclear Code", // Table 30
  "Cephalodiscidae Mitochondrial UAA-Tyr Code", // Table 33
];

/// Match NCBI translation table to the corresponding index
/// We use list index to represent the translation table
/// then convert to matching NCBI table number
/// Internally segul API uses String to parse
/// the translation table number to Genetic Code
/// enum. Dart is zero-based index, so we start from 0.
const Map<int, String> translationTableMap = {
  0: "1",
  1: "2",
  2: "3",
  3: "4",
  4: "5",
  5: "6",
  6: "9",
  7: "10",
  8: "11",
  9: "12",
  10: "13",
  11: "14",
  12: "16",
  13: "21",
  14: "22",
  15: "23",
  16: "24",
  17: "25",
  18: "26",
  19: "29",
  20: "30",
  21: "33",
};
