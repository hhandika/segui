enum PlatformType { isDesktop, isMobile }

enum RawReadOperationType { summary }

const List<String> rawReadOperation = [
  'Summary Statistics',
];

const List<String> rawReadFormat = [
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
  'FASTA',
  'NEXUS',
  'PHYLIP',
];

const List<String> outputFormat = [
  'FASTA',
  'NEXUS',
  'PHYLIP',
  'FASTA interleaved',
  'NEXUS interleaved',
  'PHYLIP interleaved',
];

const List<String> partitionFormat = [
  'Charset',
  'NEXUS',
  'RaXML',
];

const List<String> dataType = [
  'DNA',
  'Amino Acid',
  'Ignore',
];

const List<String> summaryInt = ["1", "2", "5", "10"];

const List<String> readingFrame = ["1", "2", "3"];

const List<String> translationTable = [
  "Standard Code",
  "Vertebrate Mitochondrial Code",
];
