import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:segui/main.dart';
import 'package:segui/screens/home/components/quick_start.dart';
import 'package:segui/screens/home/home.dart';
import 'package:segui/services/providers/settings.dart';
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
    expect(find.text('Quick Actions'), findsOneWidget);
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
}
