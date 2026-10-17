import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:segui/main.dart';
import 'package:segui/screens/home/components/quick_start.dart';
import 'package:segui/screens/home/home.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/tasks/alignment.dart';
import 'package:segui/services/tasks/genomics.dart';
import 'package:segui/services/tasks/sequences.dart';
import 'package:segui/src/rust/api/common.dart';
import 'package:segui/src/rust/api/csv.dart';
import 'package:segui/src/rust/api/sequence.dart';
import 'package:segui/src/rust/frb_generated.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'themeMode': 'system'});
    await RustLib.init();
  });

  tearDownAll(RustLib.dispose);

  testWidgets('Native startup loads SEGUL and opens the quick-start guide',
      (tester) async {
    expect(await getApiVersion(), isNotEmpty);
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [settingProvider.overrideWithValue(preferences)],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Common workflows'), findsNothing);
    expect(find.text('Concatenate alignments'), findsOneWidget);
    final quickStart = find.text('Quick start');
    await tester.ensureVisible(quickStart);
    await tester.tap(quickStart);
    await tester.pumpAndSettle();
    expect(find.byType(QuickStartPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(tester.takeException(), isNull);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(await getApiVersion(), isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  test('Native bridge reads a file written by Dart', () async {
    final directory = await Directory.systemTemp.createTemp('segui-bridge-');
    addTearDown(() => directory.delete(recursive: true));
    final input = File(p.join(directory.path, 'locus summary.csv'));
    await input.writeAsString('locus,length\nlocus_a,4\nlocus_b,8\n');

    final summary = await CsvSummaryServices.newInstance(
      inputPath: input.path,
      segulType: CsvSegulType.locusSummary,
    );
    expect(await summary.getLine(), BigInt.from(3));
    expect(await summary.getColumnNames(), ['length']);
  });

  test('Native bridge writes converted sequence output', () async {
    final directory = await Directory.systemTemp.createTemp('segui-output-');
    addTearDown(() => directory.delete(recursive: true));
    final input = File(p.join(directory.path, 'input alignment.fasta'));
    await input.writeAsString('>sample_a\nACGT\n>sample_b\nACGA\n');
    final output = Directory(p.join(directory.path, 'converted alignments'));

    await SequenceConversionServices(
      inputFiles: [input.path],
      inputFmt: 'fasta',
      datatype: 'dna',
      outputDir: output.path,
      outputFmt: 'nexus',
      sort: false,
    ).convertSequence();

    final files =
        await output.list(recursive: true).where((e) => e is File).toList();
    expect(files, hasLength(1));
    final content = await File(files.single.path).readAsString();
    expect(content.toUpperCase(), contains('#NEXUS'));
    expect(content, contains('sample_a'));
    expect(content, contains('ACGA'));
  });

  group('New SEGUL tasks run through the bridge', () {
    late Directory directory;
    late List<SegulInputFile> alignments;

    Future<List<String>> outputNames(Directory output) {
      return output
          .list(recursive: true)
          .where((e) => e is File)
          .map((e) => p.basename(e.path))
          .toList();
    }

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('segui-tasks-');
      final locus1 = File(p.join(directory.path, 'locus_1.fas'));
      await locus1.writeAsString(
          '>sample_a\nATGCATGC--GTAC\n>sample_b\nATGCATGCAAGTAA\n');
      final locus2 = File(p.join(directory.path, 'locus_2.fas'));
      await locus2.writeAsString('>sample_a\nGGCCTTAA\n>sample_c\nGGC-TTAA\n');
      alignments = [
        for (final file in [locus1, locus2])
          SegulInputFile(file: file, type: SegulType.standardSequence),
      ];
    });

    tearDown(() => directory.delete(recursive: true));

    test('Distance writes a matrix per locus and a summary', () async {
      final output = Directory(p.join(directory.path, 'distance'));
      await AlignmentDistanceRunner(
        inputFiles: alignments,
        inputFmt: 'Auto',
        datatype: 'DNA',
        outputDir: output,
        prefix: '',
        model: 'k2p',
        triangle: 'lower',
        diagonal: 'zero',
      ).run();
      expect(await outputNames(output),
          containsAll(['locus_1.csv', 'locus_2.csv', 'distance_summary.csv']));
    });

    test('An invalid model surfaces as an error', () async {
      final output = Directory(p.join(directory.path, 'distance-aa'));
      expect(
        AlignmentDistanceRunner(
          inputFiles: alignments,
          inputFmt: 'Auto',
          datatype: 'DNA',
          outputDir: output,
          prefix: '',
          model: 'poisson',
          triangle: 'full',
          diagonal: 'zero',
        ).run(),
        throwsA(anything),
      );
    });

    test('Transpose writes one file per sample', () async {
      final output = Directory(p.join(directory.path, 'transpose'));
      await SequenceTranspositionRunner(
        inputFiles: alignments,
        inputFmt: 'Auto',
        datatype: 'DNA',
        outputDir: output,
        isInterleave: false,
      ).run();
      expect(await outputNames(output),
          unorderedEquals(['sample_a.fas', 'sample_b.fas', 'sample_c.fas']));
    });

    test('Addition writes sources into matching destinations', () async {
      final destination = File(p.join(directory.path, 'dest', 'locus_1.fas'));
      await destination.create(recursive: true);
      await destination.writeAsString('>sample_x\nATGCATGCAAGTAC\n');
      final output = Directory(p.join(directory.path, 'added'));
      await SequenceAdditionRunner(
        inputFiles: [
          ...alignments,
          SegulInputFile(
              file: destination, type: SegulType.destinationSequence),
        ],
        inputFmt: 'Auto',
        datatype: 'DNA',
        destinationFmt: 'Auto',
        outputDir: output,
        isInterleave: false,
        isAddedOnly: true,
        isSingleDestination: false,
        isFilenameIncluded: false,
      ).run();
      final files = await output
          .list(recursive: true)
          .where((e) => e is File)
          .cast<File>()
          .toList();
      expect(files, hasLength(1));
      final content = await files.single.readAsString();
      expect(content, contains('sample_x'));
      expect(content, contains('sample_b'));
    });

    Future<File> writeMaf({bool gzip = false}) async {
      const text = '##maf version=1\n'
          'a score=1.0\n'
          's ref.chr1 100 8 + 1000 ACGTACGT\n'
          's other.chr1 50 8 + 900 ACGTACGA\n\n';
      if (gzip) {
        final file = File(p.join(directory.path, 'genome.maf.gz'));
        return file.writeAsBytes(GZipCodec().encode(text.codeUnits));
      }
      return File(p.join(directory.path, 'genome.maf')).writeAsString(text);
    }

    test('MAF conversion names loci from a four-column BED file', () async {
      final maf = await writeMaf();
      final bed = File(p.join(directory.path, 'loci.bed'));
      await bed.writeAsString('chr1\t100\t108\tlocus_a\n');
      final output = Directory(p.join(directory.path, 'maf'));
      await MafConversionRunner(
        inputFiles: [
          SegulInputFile(file: maf, type: SegulType.multipleAlignment),
          SegulInputFile(file: bed, type: SegulType.bed),
        ],
        outputDir: output,
        outputFormat: 'FASTA',
        isInterleave: false,
      ).run();
      expect(await outputNames(output),
          unorderedEquals(['locus_a-chr1-100-108.fas', 'maf_convert.csv']));
      final locus = await File(p.join(output.path, 'locus_a-chr1-100-108.fas'))
          .readAsString();
      expect(locus, contains('>ref'));
      expect(locus, contains('>other'));
      expect(locus, isNot(contains('chr1')));
    });

    test('Gzipped MAF converts by block without a BED file', () async {
      final maf = await writeMaf(gzip: true);
      final output = Directory(p.join(directory.path, 'maf-gz'));
      await MafConversionRunner(
        inputFiles: [
          SegulInputFile(file: maf, type: SegulType.multipleAlignment),
        ],
        outputDir: output,
        outputFormat: 'NEXUS',
        isInterleave: false,
      ).run();
      expect(await outputNames(output), ['chr1-100-108.nex']);
    });

    test('MAF summary writes per-file and per-species tables', () async {
      final maf = await writeMaf();
      final output = Directory(p.join(directory.path, 'maf-summary'));
      await MafSummaryRunner(
        inputFiles: [
          SegulInputFile(file: maf, type: SegulType.multipleAlignment),
        ],
        outputDir: output,
      ).run();
      expect(
          await outputNames(output),
          unorderedEquals(
              ['maf_summary_per_file.csv', 'maf_summary_per_species.csv']));
    });

    test('A non-MAF file is rejected with a clear error', () async {
      final reads = File(p.join(directory.path, 'reads.fq.gz'));
      await reads.writeAsBytes(GZipCodec().encode('@r\nA\n+\nI\n'.codeUnits));
      expect(
        MafSummaryRunner(
          inputFiles: [
            SegulInputFile(file: reads, type: SegulType.multipleAlignment),
          ],
          outputDir: Directory(p.join(directory.path, 'bad')),
        ).run(),
        throwsA(contains('Not a MAF file')),
      );
    });
  });
}
