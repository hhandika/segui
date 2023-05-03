enum PlatformType { isDesktop, isMobile }

enum RawReadOperationType { summary }

const List<String> rawReadOperation = [
  'Summary Statistics',
];

const List<String> rawReadFormat = [
  'Auto',
  'FASTQ',
  'GZip',
];

const List<String> rawReadSummaryMode = [
  'Default',
  'Minimal',
  'Complete',
];

enum AlignmentOperationType { concat, summary, convert }

// DO NOT CHANGE THE ORDER OF THE LIST
const List<String> alignmentOperation = [
  'Concatenation',
  'Summary Statistics',
  'Conversion',
];

enum SequenceOperationType { translation }

const List<String> sequenceOperation = [
  'Translation',
];

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
/// enum.
const Map<int, String> translationTableMap = {
  1: "1",
  2: "2",
  3: "3",
  4: "4",
  5: "5",
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
