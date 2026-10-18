import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/io/inspector_view.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/providers/inspector.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/viewers/inspector.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/styles/themes.dart';

const String _nexusPartition = '''#nexus
begin sets;
charset locus_1 = 1-120;
charset locus_2 = 121-300;
end;
''';

const String _nexusAlignment = '''#NEXUS
[Written by SEGUL]
begin data;
dimensions ntax=2 nchar=4;
format datatype=dna missing=? gap=-;
matrix
a ACGT
b ACGA
;
end;
begin sets;
charset locus_1 = 1-4;
end;
''';

Future<AlignmentViewData> _fakeAlignment(String path) async {
  return AlignmentViewData.fromSequences(
    const ['a', 'b', 'c'],
    [Uint8List(4), Uint8List(4), Uint8List(4)],
  );
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('segui-inspector-');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  File write(String name, String content) {
    return File(p.join(dir.path, name))..writeAsStringSync(content);
  }

  group('NEXUS partitions', () {
    test('A sets block without sequences is a partition', () {
      expect(isNexusPartitionHeader(_nexusPartition), isTrue);
      expect(isNexusPartitionHeader('#NEXUS\nBEGIN SETS;\nEND;'), isTrue);
    });

    test('An alignment with a sets block is not a partition', () {
      expect(isNexusPartitionHeader(_nexusAlignment), isFalse);
      expect(
        isNexusPartitionHeader('#nexus\nbegin characters;\nmatrix\n'),
        isFalse,
      );
    });

    test('Commented blocks are ignored', () {
      expect(
        isNexusPartitionHeader('#nexus\n[begin data;]\nbegin sets;\nend;'),
        isTrue,
      );
    });

    test('Detects partitions by content, not name', () async {
      final File partition = write('loci.nex', _nexusPartition);
      final File alignment = write('concat.nex', _nexusAlignment);
      expect(await isNexusPartition(partition), isTrue);
      expect(await isNexusPartition(alignment), isFalse);
      expect(await contentKindOf(partition), FileContentKind.partition);
      expect(await contentKindOf(alignment), FileContentKind.alignment);
    });

    test('Leaves partitions out of the alignment viewer files', () async {
      final List<File> files = [
        write('concat.nex', _nexusAlignment),
        write('concat_partition.nex', _nexusPartition),
        write('locus.fas', '>a\nACGT\n'),
        write('log.txt', 'done'),
      ];
      final List<File> alignments = await alignmentFilesOf(files);
      expect(
        [for (final file in alignments) p.basename(file.path)],
        ['concat.nex', 'locus.fas'],
      );
    });
  });

  test('Content kinds follow extension and name', () async {
    expect(
      await contentKindOf(write('concat_partition.txt', 'DNA, a = 1-4')),
      FileContentKind.partition,
    );
    expect(
      await contentKindOf(write('loci.part', 'DNA, a = 1-4')),
      FileContentKind.partition,
    );
    expect(
      await contentKindOf(write('summary.csv', 'a,b\n1,2\n')),
      FileContentKind.table,
    );
    expect(await contentKindOf(write('run.log', 'ok')), FileContentKind.text);
    expect(
      await contentKindOf(write('reads.fq', '@r\nA\n+\nI\n')),
      FileContentKind.other,
    );
  });

  group('parsePartitions', () {
    test('Reads NEXUS charsets with codon strides', () {
      final List<PartitionEntry> entries = parsePartitions(
        '#nexus\nbegin sets;\n'
        'charset gene_pos1 = 1-300\\3;\n'
        'charset gene_pos2 = 2-300\\3;\n'
        'charset intron = 301-450 460-500;\n'
        'end;\n',
      );
      expect([for (final e in entries) e.name],
          ['gene_pos1', 'gene_pos2', 'intron']);
      expect([for (final e in entries) e.lastSite], [300, 300, 500]);
    });

    test('Reads RAxML partitions', () {
      final List<PartitionEntry> entries =
          parsePartitions('DNA, locus_1 = 1-120\nDNA, locus_2 = 121-300\n');
      expect([for (final e in entries) e.name], ['locus_1', 'locus_2']);
      expect(entries.last.lastSite, 300);
    });
  });

  group('FileInspector', () {
    const FileInspector inspector =
        FileInspector(loadAlignment: _fakeAlignment);

    Map<String, String> details(FileInspection inspection) => {
          for (final detail in inspection.details) detail.label: detail.value,
        };

    test('Counts sequences and sites of an alignment', () async {
      final FileInspection inspection =
          await inspector.inspect(write('locus.fas', '>a\nACGT\n'));
      expect(inspection.kind, FileContentKind.alignment);
      expect(details(inspection), containsPair('Sequences', '3'));
      expect(details(inspection), containsPair('Sites', '4'));
      expect(details(inspection), containsPair('Data type', 'DNA'));
    });

    test('Counts partitions without loading sequences', () async {
      final FileInspection inspection = await const FileInspector(
        loadAlignment: _failingLoader,
      ).inspect(write('concat_partition.nex', _nexusPartition));
      expect(inspection.kind, FileContentKind.partition);
      expect(inspection.format, FileIconType.nexus);
      expect(details(inspection), containsPair('Partitions', '2'));
      expect(details(inspection), containsPair('Sites', '300'));
      expect(inspection.note, isNull);
    });

    test('Counts table rows and text lines', () async {
      final FileInspection table =
          await inspector.inspect(write('summary.csv', 'a,b\n1,2\n3,4\n'));
      expect(details(table), containsPair('Rows', '2'));
      expect(details(table), containsPair('Columns', '2'));
      final FileInspection text =
          await inspector.inspect(write('run.log', 'one\ntwo\nthree\n'));
      expect(details(text), containsPair('Lines', '3'));
    });

    test('Separates thousands in counts', () async {
      final FileInspection text =
          await inspector.inspect(write('long.log', 'line\n' * 12345));
      expect(details(text), containsPair('Lines', '12,345'));
    });

    test('Notes a missing file', () async {
      final FileInspection inspection =
          await inspector.inspect(File(p.join(dir.path, 'gone.fas')));
      expect(inspection.details, isEmpty);
      expect(inspection.note, isNotNull);
    });
  });

  testWidgets('Inspector shows the picked input file', (tester) async {
    final File partition = write('loci_partition.nex', _nexusPartition);
    final ProviderContainer container = ProviderContainer(
      overrides: [alignmentLoaderProvider.overrideWithValue(_failingLoader)],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() => container
        .read(fileInputProvider.notifier)
        .addFiles([XFile(partition.path)], partitionTypeGroup));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(child: FileInspectorCard()),
        ),
      ),
    ));
    expect(find.text('Choose a file (1)'), findsOneWidget);

    container.read(inspectedFileProvider.notifier).select(partition);
    // The inspection reads the file outside the fake clock.
    for (int i = 0; i < 20 && find.text('Open').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    expect(find.text('loci_partition.nex'), findsOneWidget);
    expect(find.text('Partition'), findsOneWidget);
    expect(find.text('Partitions'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  Future<ProviderContainer> pumpCard(
    WidgetTester tester,
    List<File> inputs,
  ) async {
    final ProviderContainer container = ProviderContainer(
      overrides: [alignmentLoaderProvider.overrideWithValue(_failingLoader)],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() => container
        .read(fileInputProvider.notifier)
        .addFiles([for (final f in inputs) XFile(f.path)], sequenceTypeGroup));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(child: FileInspectorCard()),
        ),
      ),
    ));
    return container;
  }

  testWidgets('View all sequences shows only with sequence files',
      (tester) async {
    await pumpCard(tester, [write('summary.csv', 'a,b\n1,2\n')]);
    expect(find.text('View all sequences'), findsNothing);

    await pumpCard(tester, [write('locus.fas', '>a\nACGT\n')]);
    expect(find.text('View all sequences'), findsOneWidget);
  });

  testWidgets('View all sequences skips NEXUS partitions', (tester) async {
    await pumpCard(tester, [write('loci.nex', _nexusPartition)]);
    expect(find.text('View all sequences'), findsOneWidget);

    await tester.tap(find.text('View all sequences'));
    for (int i = 0; i < 20; i++) {
      if (find.text('No sequence files to view.').evaluate().isNotEmpty) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(find.text('No sequence files to view.'), findsOneWidget);
  });
}

Future<AlignmentViewData> _failingLoader(String path) {
  throw StateError('Partitions must not load as sequences');
}
