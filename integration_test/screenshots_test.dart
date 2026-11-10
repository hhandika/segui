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
//
// Pass --dart-define=SCREENSHOT_LANDSCAPE=true on a mobile target to capture
// its landscape layout, such as for iPad store screenshots.
//
// Pass --dart-define=SCREENSHOT_ONLY=<prefix> to capture only the screens
// whose names start with it, such as `viewer`.
//
// Pass --dart-define=SCREENSHOT_ALIGNMENTS=<folder> to show real alignments
// instead of generated ones. The folder is copied, not changed. Add
// --dart-define=SCREENSHOT_SITE=<site> to scroll the alignment viewer there
// with its Go to site field, and --dart-define=SCREENSHOT_HIDE_CHUNKS=true
// to hide its chunk list.
//
// Pass --dart-define=SCREENSHOT_REPORT=<file> to also capture a summary
// report, such as `alignment-report.json`, as `viewer-report`, and
// --dart-define=SCREENSHOT_REPORT_TAB=<tab> to open a tab of it first.
//
// Pass --dart-define=SCREENSHOT_VIEWER_FILE=<name> to open that alignment
// in the viewer instead of the first one listed, and
// --dart-define=SCREENSHOT_VIEWER_SITE=<site> to scroll it to that site, so
// the capture shows aligned bases rather than the gaps at its ends.
//
// Pass --dart-define=SCREENSHOT_READS=<folder> to show real raw reads
// instead of generated ones. The reads are read in place, not changed.
//
// The read and alignment report screens summarize these inputs, so real
// datasets give realistic plots. The sandboxed macOS app can only read its
// own container, so copy the datasets into
// ~/Library/Containers/com.hhandika.segui/Data/tmp first.
import 'dart:async';
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
import 'package:segui/screens/viewers/alignment/alignment_grid.dart';
import 'package:segui/screens/viewers/alignment_report.dart';
import 'package:segui/screens/viewers/common.dart';
import 'package:segui/screens/viewers/read_report.dart';
import 'package:segui/screens/viewers/viewer_page.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/providers/viewer.dart';
import 'package:segui/services/types.dart';
import 'package:segui/src/rust/api/progress.dart';
import 'package:segui/src/rust/api/reads.dart';
import 'package:segui/src/rust/api/sequence.dart';
import 'package:segui/src/rust/frb_generated.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _outputDir = String.fromEnvironment('SCREENSHOT_DIR');
const String _only = String.fromEnvironment('SCREENSHOT_ONLY');
const String _alignmentDir = String.fromEnvironment('SCREENSHOT_ALIGNMENTS');
const String _readDir = String.fromEnvironment('SCREENSHOT_READS');
const String _viewerFile = String.fromEnvironment('SCREENSHOT_VIEWER_FILE');
const int _viewerSite = int.fromEnvironment('SCREENSHOT_VIEWER_SITE');
const bool _landscape = bool.fromEnvironment('SCREENSHOT_LANDSCAPE');
const String _site = String.fromEnvironment('SCREENSHOT_SITE');
const bool _hideChunks = bool.fromEnvironment('SCREENSHOT_HIDE_CHUNKS');
const String _report = String.fromEnvironment('SCREENSHOT_REPORT');
const String _reportTab = String.fromEnvironment('SCREENSHOT_REPORT_TAB');

/// Whether to capture the screen called [name].
bool _wants(String name) => name.startsWith(_only);

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
    if (_alignmentDir.isNotEmpty) {
      final List<XFile> alignments = await _copyAlignments(
        Directory(_alignmentDir),
        dataDir,
      );
      inputs[_Input.alignments] = alignments;
      inputs[_Input.sequences] = alignments;
    }
    if (_readDir.isNotEmpty) {
      inputs[_Input.reads] = _listFiles(
        Directory(_readDir),
        genomicRawReadTypeGroup,
      );
    }
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
    } else if (_landscape) {
      // Tablets and foldables render their landscape layout at the device's
      // own resolution, whichever way the simulator is turned.
      final Size size = tester.view.physicalSize;
      tester.view.physicalSize = Size(
        max(size.width, size.height),
        min(size.width, size.height),
      );
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

    for (final _Shot shot in _shots.where((shot) => _wants(shot.name))) {
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
    if (_wants('genomic-read-report')) {
      final File report = await _summarizeReads(inputs[_Input.reads]!, dataDir);
      await _captureRoute(
        tester,
        boundaryKey,
        ReadReportView(file: report),
        tab: 'Quality',
        File(p.join(output.path, 'genomic-read-report-$suffix.png')),
      );
    }
    if (_wants('align-summary-report')) {
      final File report = await _summarizeAlignments(
        inputs[_Input.alignments]!,
        dataDir,
      );
      await _captureRoute(
        tester,
        boundaryKey,
        AlignmentReportView(file: report),
        tab: 'Distributions',
        File(p.join(output.path, 'align-summary-report-$suffix.png')),
      );
    }
    if (_wants('viewer')) {
      await _captureViewer(
          tester,
          container,
          boundaryKey,
          [
            for (final XFile file in inputs[_Input.alignments]!)
              File(file.path),
          ],
          (name) => File(p.join(output.path, '$name-$suffix.png')));
    }
    if (_report.isNotEmpty && _wants('viewer-report')) {
      await _captureReport(
        tester,
        boundaryKey,
        File(_report),
        File(p.join(output.path, 'viewer-report-$suffix.png')),
      );
    }
    debugPrint('Screenshots saved in ${output.path}');
  });
}

/// Summarizes [reads] in Complete mode and returns the read report.
Future<File> _summarizeReads(List<XFile> reads, Directory dir) async {
  final RunMonitor monitor = RunMonitor();
  final ReadSummaryOutput output = await RawReadServices(
    files: [for (final XFile file in reads) file.path],
    fileFmt: 'auto',
    outputDir: p.join(dir.path, 'read-summary'),
  ).summarize(mode: 'complete', phred: 'auto', monitor: monitor);
  monitor.close();
  return File(output.reportPath!);
}

/// Summarizes [alignments] and returns the alignment report.
Future<File> _summarizeAlignments(List<XFile> alignments, Directory dir) async {
  final String report = await AlignmentServices(
    inputFiles: [for (final XFile file in alignments) file.path],
    inputFmt: 'auto',
    datatype: 'dna',
    outputDir: p.join(dir.path, 'alignment-summary'),
  ).summarizeAlignment(
    outputPrefix: _alignmentDir.isEmpty ? 'uce' : p.basename(_alignmentDir),
    interval: BigInt.from(5),
  );
  return File(report);
}

/// Pushes [page], opens its [tab], captures it in [file] once its report
/// loads, and closes it.
Future<void> _captureRoute(
  WidgetTester tester,
  GlobalKey boundaryKey,
  Widget page,
  File file, {
  String? tab,
}) async {
  final NavigatorState navigator = tester.state<NavigatorState>(
    find.byType(Navigator).first,
  );
  navigator.push(MaterialPageRoute(builder: (context) => page));
  for (int i = 0; i < 100; i++) {
    await _settle(tester);
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  if (tab != null) {
    await tester.tap(find.widgetWithText(Tab, tab).first);
  }
  await _settle(tester);
  await _capture(tester, boundaryKey, file);
  navigator.pop();
  await _settle(tester);
}

/// Captures the Viewer page with [files] open, then the alignment viewer
/// opened from it.
Future<void> _captureViewer(
  WidgetTester tester,
  ProviderContainer container,
  GlobalKey boundaryKey,
  List<File> files,
  File Function(String name) target,
) async {
  // A readable folder name, since the files list shows it. Real alignments
  // are already in a folder named after their dataset.
  final List<File> copies;
  if (_alignmentDir.isNotEmpty) {
    copies = files;
  } else {
    final Directory folder = Directory(
      p.join(p.dirname(files.first.path), 'uce-loci'),
    )..createSync();
    copies = [
      for (final File file in files)
        file.copySync(p.join(folder.path, p.basename(file.path))),
    ];
  }
  container.read(viewerFilesProvider.notifier).addFiles(copies);
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute(builder: (context) => const ViewerPage()));
  await _settle(tester);
  await _capture(tester, boundaryKey, target('viewer'));
  if (_viewerFile.isNotEmpty) {
    final File file = copies.firstWhere(
      (file) => p.basename(file.path) == _viewerFile,
    );
    unawaited(
      openFileView(
        tester.element(find.byType(ViewerPage)),
        file,
        siblings: copies,
      ),
    );
  } else {
    // Open the first file shown, since the list order may differ from the
    // order of [copies].
    final Finder firstFile = copies
        .map((file) => find.text(p.basename(file.path)).hitTestable())
        .firstWhere((finder) => finder.evaluate().isNotEmpty);
    await tester.tap(firstFile.first);
  }
  // Opening reads the file and its siblings first, which takes a while for
  // large datasets, so wait until the file list is covered.
  for (int i = 0; i < 100; i++) {
    await _settle(tester);
    if (find.byType(ViewerFileList).hitTestable().evaluate().isEmpty) break;
  }
  await _settle(tester);
  if (_viewerSite > 1) {
    final AlignmentGrid grid = tester.widget(find.byType(AlignmentGrid));
    final ScrollPosition position = grid.horizontalController.position;
    position.jumpTo(
      min(
        (_viewerSite - 1 - grid.window.start) * grid.cellSize,
        position.maxScrollExtent,
      ),
    );
    await _settle(tester);
  }
  if (_site.isNotEmpty) {
    final Finder goToSite = find.ancestor(
      of: find.text('Go to site'),
      matching: find.byType(TextField),
    );
    await tester.enterText(goToSite, _site);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await _settle(tester);
    // Leave the field so its cursor is not in the capture.
    FocusManager.instance.primaryFocus?.unfocus();
    await _settle(tester);
  }
  if (_hideChunks) {
    await tester.tap(find.byTooltip('Hide chunk list'));
    await _settle(tester);
  }
  await _capture(tester, boundaryKey, target('viewer-alignment'));
}

/// Opens [report] in the file viewer and captures it to [target].
Future<void> _captureReport(
  WidgetTester tester,
  GlobalKey boundaryKey,
  File report,
  File target,
) async {
  final NavigatorState navigator = tester.state<NavigatorState>(
    find.byType(Navigator).first,
  );
  navigator.popUntil((route) => route.isFirst);
  await _settle(tester);
  // The route stays open until the capture, so the future is not awaited.
  openFileView(navigator.context, report);
  for (int i = 0; i < 50; i++) {
    await _settle(tester);
    if (find.text(p.basename(report.path)).evaluate().isNotEmpty) break;
  }
  await _settle(tester);
  if (_reportTab.isNotEmpty) {
    await tester.tap(find.text(_reportTab).first);
    await _settle(tester);
    await _settle(tester);
  }
  await _capture(tester, boundaryKey, target);
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

/// Files in [source] that match [group], sorted by name.
List<XFile> _listFiles(Directory source, XTypeGroup group) {
  final List<File> files = source
      .listSync()
      .whereType<File>()
      .where(
        (file) => group.extensions!.any(
          (ext) => p.basename(file.path).endsWith('.$ext'),
        ),
      )
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return [for (final File file in files) XFile(file.path)];
}

/// Copies the alignments in [source] into a folder of the same name in [dir],
/// sorted by name.
Future<List<XFile>> _copyAlignments(Directory source, Directory dir) async {
  final Directory folder = Directory(p.join(dir.path, p.basename(source.path)))
    ..createSync();
  final List<File> files = source
      .listSync()
      .whereType<File>()
      .where(
        (file) => sequenceTypeGroup.extensions!.contains(
          p.extension(file.path).replaceFirst('.', ''),
        ),
      )
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final File file in files)
      XFile(file.copySync(p.join(folder.path, p.basename(file.path))).path),
  ];
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
