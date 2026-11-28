import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/home_features.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/tasks/tree.dart';
import 'package:segui/services/types.dart';
import 'package:segui/services/viewers/inspector.dart';
import 'package:segui/services/workbench.dart';

const String _nexusTrees = '''#NEXUS
[Trees from a run]
BEGIN TREES;
  TRANSLATE
    1 Taxon_A,
    2 Taxon_B
  ;
  TREE tree_1 = (1:0.1,2:0.2);
END;
''';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('segui-tree-');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  File write(String name, String content) {
    return File(p.join(dir.path, name))..writeAsStringSync(content);
  }

  SegulInputFile input(String name) {
    return SegulInputFile(
      file: File(p.join(dir.path, name)),
      type: SegulType.phylogeneticTree,
    );
  }

  test('Tree files match by their full extension', () {
    expect(isTreePath('species.nwk'), isTrue);
    expect(isTreePath('species.TRE.gz'), isTrue);
    expect(isTreePath('run.trees'), isTrue);
    expect(isTreePath('species.nex'), isTrue);
    expect(isTreePath('reads.fq.gz'), isFalse);
    expect(matchesTypeGroup(File('a.phyloxml.gz'), treeTypeGroup), isTrue);
    expect(matchesTypeGroup(File('a.maf.gz'), treeTypeGroup), isFalse);
    expect(matchTypeByXTypeGroup(treeTypeGroup), SegulType.phylogeneticTree);
  });

  test('Tree formats use SEGUL names', () {
    expect(treeInputFormat.keys.first, 'auto');
    expect(treeOutputFormat.keys, isNot(contains('auto')));
    expect(defaultOutputDir[SupportedTask.treeConversion],
        'segui-tree-conversion');
  });

  test('Tree paths reject empty and non-tree input', () {
    expect(() => treePaths(const []), throwsA('No input files'));
    expect(() => treePaths([input('reads.fq')]),
        throwsA('Not a tree file: reads.fq'));
    expect(treePaths([input('a.nwk')]), [p.join(dir.path, 'a.nwk')]);
  });

  test('Tree conversion passes trees to the next step', () {
    final ToolDataFlow flow = dataFlowFor(treeConversionTool);
    expect(flow.accepts, {ToolData.tree});
    expect(flow.produces, ToolData.tree);
    expect(flow.inputGroup, treeTypeGroup);
    expect(homeToolFor(TreeOperationType.conversion), treeConversionTool);
  });

  group('NEXUS trees', () {
    test('A trees block without sequences is a tree file', () {
      expect(isNexusTreeHeader(_nexusTrees), isTrue);
      expect(isNexusTreeHeader('#nexus\n[begin trees;]\nbegin data;'), isFalse);
      expect(isNexusPartitionHeader(_nexusTrees), isFalse);
    });

    test('Opens as text and stays out of the alignment viewer', () async {
      final File trees = write('species.nex', _nexusTrees);
      final File newick = write('species.nwk', '(A,B);\n');
      expect(await isNexusTree(trees), isTrue);
      expect(await contentKindOf(trees), FileContentKind.text);
      expect(await contentKindOf(newick), FileContentKind.text);
      expect(await alignmentFilesOf([trees, newick]), isEmpty);
    });
  });
}
