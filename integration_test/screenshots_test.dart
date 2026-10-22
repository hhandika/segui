// Captures the app screens used in the GUI guide on the documentation
// website. Run on a native target:
//
//   flutter test integration_test/screenshots_test.dart -d macos
//
// The sandboxed app saves the captures in its own temporary folder and
// prints the path. Pass --dart-define=SCREENSHOT_DIR=<folder> to save them
// elsewhere on unsandboxed targets.
//
// Desktop runs capture the large-screen layout and mobile runs capture the
// small-screen layout, matching the `-large` and `-small` image names the
// website expects.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/main.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/types.dart';
import 'package:segui/src/rust/frb_generated.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _outputDir = String.fromEnvironment('SCREENSHOT_DIR');

/// Logical size of the large-screen captures.
const Size _largeSize = Size(1280, 800);

const List<String> _taxa = [
  'Bunomys_chrysocomus',
  'Crunomys_celebensis',
  'Echiothrix_centrosa',
  'Maxomys_hellwaldii',
  'Paruromys_dominator',
  'Rattus_hoffmanni',
  'Taeromys_celebensis',
  'Tateomys_macrocercus',
];

/// One captured screen: the tab and tool to open and the input to load.
class _Shot {
  const _Shot(this.name, {this.tab = 0, this.tool, this.input});

  final String name;
  final int tab;
  final Enum? tool;
  final _Input? input;
}

enum _Input { alignments, sequences, reads, contigs, maf }

const List<_Shot> _shots = [
  _Shot('home'),
  _Shot(
    'align-concat',
    tab: 2,
    tool: AlignmentOperationType.concatenation,
    input: _Input.alignments,
  ),
  _Shot(
    'align-convert',
    tab: 2,
    tool: AlignmentOperationType.conversion,
    input: _Input.alignments,
  ),
  _Shot('align-partition', tab: 2, tool: AlignmentOperationType.partition),
  _Shot(
    'align-filter',
    tab: 2,
    tool: AlignmentOperationType.filter,
    input: _Input.alignments,
  ),
  _Shot('align-split', tab: 2, tool: AlignmentOperationType.split),
  _Shot(
    'align-summary',
    tab: 2,
    tool: AlignmentOperationType.summary,
    input: _Input.alignments,
  ),
  _Shot(
    'align-distance',
    tab: 2,
    tool: AlignmentOperationType.distance,
    input: _Input.alignments,
  ),
  _Shot(
    'align-trim',
    tab: 2,
    tool: AlignmentOperationType.trimming,
    input: _Input.alignments,
  ),
  _Shot(
    'align-unalign',
    tab: 2,
    tool: AlignmentOperationType.unalignment,
    input: _Input.alignments,
  ),
  _Shot(
    'genomic-read',
    tab: 1,
    tool: GenomicOperationType.readSummary,
    input: _Input.reads,
  ),
  _Shot(
    'genomic-contig',
    tab: 1,
    tool: GenomicOperationType.contigSummary,
    input: _Input.contigs,
  ),
  _Shot(
    'maf-convert',
    tab: 1,
    tool: GenomicOperationType.mafConversion,
    input: _Input.maf,
  ),
  _Shot(
    'maf-summary',
    tab: 1,
    tool: GenomicOperationType.mafSummary,
    input: _Input.maf,
  ),
  _Shot(
    'sequence-extract',
    tab: 3,
    tool: SequenceOperationType.extraction,
    input: _Input.sequences,
  ),
  _Shot(
    'sequence-id',
    tab: 3,
    tool: SequenceOperationType.idExtraction,
    input: _Input.sequences,
  ),
  _Shot(
    'sequence-remove',
    tab: 3,
    tool: SequenceOperationType.removal,
    input: _Input.sequences,
  ),
  _Shot(
    'sequence-rename',
    tab: 3,
    tool: SequenceOperationType.renaming,
    input: _Input.sequences,
  ),
  _Shot(
    'sequence-translate',
    tab: 3,
    tool: SequenceOperationType.translation,
    input: _Input.sequences,
  ),
  _Shot('sequence-add', tab: 3, tool: SequenceOperationType.addition),
  _Shot(
    'sequence-filter',
    tab: 3,
    tool: SequenceOperationType.filtering,
    input: _Input.sequences,
  ),
  _Shot(
    'sequence-transpose',
    tab: 3,
    tool: SequenceOperationType.transposition,
    input: _Input.sequences,
  ),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final bool isLarge =
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  final String suffix = isLarge ? 'large' : 'small';
  late Directory dataDir;
  late Map<_Input, List<XFile>> inputs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'themeMode': 'light'});
    await RustLib.init();
    dataDir = await Directory.systemTemp.createTemp('segui-screenshots-');
    inputs = await _writeInputs(dataDir);
  });

  tearDownAll(() async {
    RustLib.dispose();
    await dataDir.delete(recursive: true);
  });

  testWidgets('Capture GUI guide screenshots', (tester) async {
    final Directory output = Directory(
      _outputDir.isEmpty
          ? p.join(Directory.systemTemp.path, 'segui-screenshots')
          : _outputDir,
    );
    await output.create(recursive: true);
    if (isLarge) {
      tester.view.physicalSize = _largeSize * tester.view.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
    }

    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [settingProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    final GlobalKey boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: UncontrolledProviderScope(
          container: container,
          child: const MyApp(),
        ),
      ),
    );
    await _settle(tester);

    for (final _Shot shot in _shots) {
      container.read(tabSelectionProvider.notifier).setTab(shot.tab);
      final Enum? tool = shot.tool;
      if (tool is AlignmentOperationType) {
        container
            .read(alignmentOperationSelectionProvider.notifier)
            .setOperation(tool);
      } else if (tool is GenomicOperationType) {
        container
            .read(genomicOperationSelectionProvider.notifier)
            .setOperation(tool);
      } else if (tool is SequenceOperationType) {
        container
            .read(sequenceOperationSelectionProvider.notifier)
            .setOperation(tool);
      }
      await _settle(tester);
      final _Input? input = shot.input;
      if (input != null) {
        await container
            .read(fileInputProvider.notifier)
            .addFiles(inputs[input]!, _typeGroups[input]!);
      }
      await _settle(tester);
      await _capture(
        tester,
        boundaryKey,
        File(p.join(output.path, '${shot.name}-$suffix.png')),
      );
    }
    debugPrint('Screenshots saved in ${output.path}');
  });
}

const Map<_Input, XTypeGroup> _typeGroups = {
  _Input.alignments: sequenceTypeGroup,
  _Input.sequences: sequenceTypeGroup,
  _Input.reads: genomicRawReadTypeGroup,
  _Input.contigs: genomicContigTypeGroup,
  _Input.maf: mafTypeGroup,
};

/// Pumps frames until animations end, with a cap for looping animations.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundaryKey,
  File file,
) async {
  await tester.runAsync(() async {
    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(
      pixelRatio: tester.view.devicePixelRatio,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

/// Writes small example inputs with realistic names for each input type.
Future<Map<_Input, List<XFile>>> _writeInputs(Directory dir) async {
  final Random random = Random(7);
  String dna(int length) =>
      List.generate(length, (_) => 'ACGT'[random.nextInt(4)]).join();
  final List<XFile> alignments = [];
  for (int i = 1; i <= 12; i++) {
    final int length = 400 + random.nextInt(600);
    final String base = dna(length);
    final StringBuffer matrix = StringBuffer();
    for (final String taxon in _taxa) {
      final List<String> sites = base.split('');
      for (int s = 0; s < sites.length; s++) {
        if (random.nextInt(12) == 0) sites[s] = 'ACGT-'[random.nextInt(5)];
      }
      matrix.writeln('$taxon ${sites.join()}');
    }
    final File file = File(p.join(dir.path, 'uce-$i.nex'));
    await file.writeAsString(
      '#NEXUS\nbegin data;\n'
      'dimensions ntax=${_taxa.length} nchar=$length;\n'
      'format datatype=dna missing=? gap=-;\nmatrix\n$matrix;\nend;\n',
    );
    alignments.add(XFile(file.path));
  }
  final List<XFile> reads = [];
  final List<XFile> contigs = [];
  for (final String taxon in _taxa.take(4)) {
    for (final String read in ['R1', 'R2']) {
      final File file = File(p.join(dir.path, '${taxon}_$read.fastq.gz'));
      final String record = '@$taxon\n${dna(150)}\n+\n${'I' * 150}\n';
      await file.writeAsBytes(gzip.encode(record.codeUnits));
      reads.add(XFile(file.path));
    }
    final File contig = File(p.join(dir.path, '${taxon}_contigs.fasta'));
    await contig.writeAsString('>${taxon}_1\n${dna(800)}\n');
    contigs.add(XFile(contig.path));
  }
  final List<XFile> maf = [];
  for (final String name in ['chr1', 'chr2']) {
    final File file = File(p.join(dir.path, '$name.maf'));
    final String a = dna(60);
    await file.writeAsString(
      '##maf version=1\n\na score=0\n'
      's hg38.$name 100 60 + 248956422 $a\n'
      's mm39.$name 200 60 + 195154279 $a\n\n',
    );
    maf.add(XFile(file.path));
  }
  return {
    _Input.alignments: alignments,
    _Input.sequences: alignments,
    _Input.reads: reads,
    _Input.contigs: contigs,
    _Input.maf: maf,
  };
}
