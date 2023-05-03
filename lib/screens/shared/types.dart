enum PlatformType { isDesktop, isMobile }

enum RawReadOperationType { summary }

const List<String> rawReadOperation = [
  'Summary Statistics',
];

const List<String> rawReadFormat = [
  'FASTQ',
  'GZip',
  'Auto',
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
  "1. The Standard Code",
  "2. The Vertebrate Mitochondrial Code",
  "3. The Yeast Mitochondrial Code",
  "4. The Mold, Protozoan, and Coelenterate Mitochondrial Code and the Mycoplasma/Spiroplasma Code",
  "5. The Invertebrate Mitochondrial Code",
  "6. The Ciliate, Dasycladacean and Hexamita Nuclear Code",
  "9. The Echinoderm and Flatworm Mitochondrial Code",
  "10. The Euplotid Nuclear Code",
  "11. The Bacterial, Archaeal and Plant Plastid Code",
  "12. The Alternative Yeast Nuclear Code",
  "13. The Ascidian Mitochondrial Code",
  "14. The Alternative Flatworm Mitochondrial Code",
  "16. Chlorophycean Mitochondrial Code",
  "21. Trematode Mitochondrial Code",
  "22. Scenedesmus obliquus Mitochondrial Code",
  "23. Thraustochytrium Mitochondrial Code",
  "24. Rhabdopleuridae Mitochondrial Code",
  "25. Candidate Division SR1 and Gracilibacteria Code",
  "26. Pachysolen tannophilus Nuclear Code",
  "29. Mesodinium Nuclear Code",
  "30. Peritrich Nuclear Code",
  "33. Cephalodiscidae Mitochondrial UAA-Tyr Code",
];

/// Match NCBI translation table to the corresponding index
/// We use list index to represent the translation table
/// then convert to matching NCBI table number
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
