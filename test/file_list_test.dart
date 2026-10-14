import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/io/file_list.dart';
import 'package:segui/screens/shared/io/input_view.dart';
import 'package:segui/screens/shared/io/output_view.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/output.dart';
import 'package:segui/styles/themes.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('segui-file-list-');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  List<File> createFiles(int count, String extension) {
    return List.generate(count, (index) {
      final file = File(p.join(dir.path, 'locus_$index.$extension'));
      file.writeAsStringSync('content');
      return file;
    });
  }

  Future<void> pumpList(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(600, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: Scaffold(body: child),
      ),
    ));
    await tester.pump();
  }

  test('File names map to their format icons', () {
    final Map<String, FileIconType> cases = {
      'locus.fasta': FileIconType.fasta,
      'locus.FAS': FileIconType.fasta,
      'locus.nex': FileIconType.nexus,
      'locus.phy': FileIconType.phylip,
      'reads_R1.fastq': FileIconType.fastq,
      'reads_R1.fq.gz': FileIconType.fastq,
      'contigs.fasta.gz': FileIconType.gzip,
      'summary.csv': FileIconType.csv,
      'ids.txt': FileIconType.text,
      'concat.partition': FileIconType.partition,
      'segul.log': FileIconType.log,
      'output.zip': FileIconType.zip,
      'notes.docx': FileIconType.unknown,
    };
    cases.forEach((name, type) {
      expect(FileIconType.fromFileName(name), type, reason: name);
    });
  });

  test('Every file icon is a bundled SVG', () {
    for (final type in FileIconType.values) {
      // Asset keys always use POSIX separators.
      final File asset = File(p.joinAll(p.posix.split(type.assetPath)));
      expect(asset.existsSync(), isTrue, reason: type.name);
    }
  });

  testWidgets('Input list shows 20 files, then more on request',
      (tester) async {
    final files = createFiles(45, 'nexus')
        .map((file) => SegulInputFile(file: file, type: SegulType.standardSequence))
        .toList();
    await pumpList(tester, InputFileList(files: files));

    expect(find.byType(ListTile), findsNWidgets(fileListPageSize));
    expect(find.text('Show 20 more'), findsOneWidget);
    expect(find.text('Show all 25'), findsOneWidget);

    await tester.tap(find.text('Show 20 more'));
    await tester.pump();
    expect(find.byType(ListTile), findsNWidgets(40));
    expect(find.text('Show 5 more'), findsOneWidget);
    expect(find.textContaining('Show all'), findsNothing);

    await tester.tap(find.text('Show 5 more'));
    await tester.pump();
    expect(find.byType(ListTile), findsNWidgets(45));
    expect(find.byType(ShowMoreFilesButtons), findsNothing);
  });

  testWidgets('Short lists have no show more button', (tester) async {
    final files = createFiles(3, 'fasta')
        .map((file) => SegulInputFile(file: file, type: SegulType.standardSequence))
        .toList();
    await pumpList(tester, InputFileList(files: files));

    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.byType(ShowMoreFilesButtons), findsNothing);
  });

  testWidgets('Output list shows new files and can show the rest',
      (tester) async {
    final List<File> newFiles = createFiles(2, 'nex');
    final List<File> oldFiles = [
      File(p.join(dir.path, 'old_a.csv'))..writeAsStringSync('a'),
      File(p.join(dir.path, 'old_b.csv'))..writeAsStringSync('b'),
      File(p.join(dir.path, 'old_c.csv'))..writeAsStringSync('c'),
    ];
    final output = SegulOutputFile(directory: dir, files: [
      for (final file in newFiles) (file: file, isNew: true),
      for (final file in oldFiles) (file: file, isNew: false),
    ]);
    await pumpList(tester, OutputFileList(data: output));

    expect(find.byType(OutputFileTiles), findsNWidgets(2));
    await tester.tap(find.text('Show 3 other files in the folder'));
    await tester.pump();
    expect(find.byType(OutputFileTiles), findsNWidgets(5));

    await tester.tap(find.text('Show new files only'));
    await tester.pump();
    expect(find.byType(OutputFileTiles), findsNWidgets(2));
  });

  testWidgets('Output list without new files explains how to get them',
      (tester) async {
    final output = SegulOutputFile(directory: dir, files: [
      for (final file in createFiles(2, 'csv')) (file: file, isNew: false),
    ]);
    await pumpList(tester, OutputFileList(data: output));

    expect(find.byType(OutputFileTiles), findsNothing);
    expect(find.text('No new output files yet.'), findsOneWidget);
    expect(find.text('Show 2 other files in the folder'), findsOneWidget);
  });
}
