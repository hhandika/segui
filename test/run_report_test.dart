import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/providers/replay.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/viewers/inspector.dart';
import 'package:segui/services/viewers/run_report.dart';
import 'package:segui/services/workbench.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('segui-run-report-test-');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ChecksumModeSetting & checksumModeProvider', () {
    test('round-trips wire values and persists to SharedPreferences', () async {
      for (final mode in ChecksumModeSetting.values) {
        expect(ChecksumModeSetting.fromWire(mode.wireValue), mode);
      }
      expect(ChecksumModeSetting.fromWire('invalid'), ChecksumModeSetting.none);

      SharedPreferences.setMockInitialValues(<String, Object>{
        ChecksumModeSettingNotifier.prefsKey: 'outputs',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer container = ProviderContainer(
        overrides: [settingProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(checksumModeProvider), ChecksumModeSetting.outputs);
      await container
          .read(checksumModeProvider.notifier)
          .setMode(ChecksumModeSetting.all);
      expect(container.read(checksumModeProvider), ChecksumModeSetting.all);
      expect(
        prefs.getString(ChecksumModeSettingNotifier.prefsKey),
        'all',
      );
    });
  });

  group('toolForTaskKind & PendingReplayNotifier', () {
    test('maps all 21 TaskKind values and rejects unknown kinds', () {
      const List<String> allKinds = [
        'align.summary',
        'align.distance',
        'align.concat',
        'align.convert',
        'align.filter',
        'align.split',
        'align.trim',
        'align.unalign',
        'partition.convert',
        'contig.summary',
        'read.summary',
        'maf.summary',
        'maf.convert',
        'sequence.add',
        'sequence.extract',
        'sequence.filter',
        'sequence.id',
        'sequence.remove',
        'sequence.rename',
        'sequence.translate',
        'sequence.transpose',
      ];
      for (final kind in allKinds) {
        expect(toolForTaskKind(kind), isNotNull, reason: 'Missing $kind');
      }
      expect(toolForTaskKind('unknown.task'), isNull);
    });

    test('consumes matching taskKind only once', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      const PendingReplay replay = PendingReplay(
        taskKind: 'align.summary',
        reportPath: 'report.json',
        inputFiles: <String>[],
        auxiliaryInputs: <String, List<String>>{},
        outputDir: '',
        prefix: 'out',
        parameters: <String, dynamic>{'interval': 10},
      );
      container.read(pendingReplayProvider.notifier).setReplay(replay);

      expect(
        container
            .read(pendingReplayProvider.notifier)
            .consumeFor('align.concat'),
        isNull,
      );
      expect(
        container
            .read(pendingReplayProvider.notifier)
            .consumeFor('align.summary'),
        replay,
      );
      expect(container.read(pendingReplayProvider), isNull);
    });
  });

  group('v2 run report & legacy detection', () {
    test('detects v2 summary kinds, non-summary runReport, and legacy reports',
        () async {
      final File alignV2 = File(p.join(tempDir.path, 'align_report.json'));
      await alignV2.writeAsString(jsonEncode({
        'schema_version': 2,
        'kind': 'align.summary',
        'run': {
          'frontend': {'name': 'segui', 'version': '1.0.0'},
          'checksum_mode': 'none',
        },
        'inputs': {'primary': <dynamic>[]},
        'outputs': {'files': <dynamic>[]},
        'parameters': {'interval': 5},
        'statistics': {'datatype': 'DNA'},
      }));
      expect(await contentKindOf(alignV2), FileContentKind.alignmentReport);
      expect(isRunReportFile(alignV2), isTrue);

      final File concatV2 = File(p.join(tempDir.path, 'concat_report.json'));
      await concatV2.writeAsString(jsonEncode({
        'schema_version': 2,
        'kind': 'align.concat',
        'run': {
          'frontend': {'name': 'segui', 'version': '1.0.0'},
          'checksum_mode': 'none',
        },
        'inputs': {'primary': <dynamic>[]},
        'outputs': {'files': <dynamic>[]},
        'parameters': {'prefix': 'concat'},
      }));
      expect(await contentKindOf(concatV2), FileContentKind.runReport);
      expect(isRunReportFile(concatV2), isTrue);

      final File legacyAlign =
          File(p.join(tempDir.path, 'legacy_alignment-report.json'));
      await legacyAlign.writeAsString(jsonEncode({
        'datatype': 'DNA',
        'summary': <String, dynamic>{},
      }));
      expect(await contentKindOf(legacyAlign), FileContentKind.alignmentReport);
      expect(isRunReportFile(legacyAlign), isFalse);

      final File plainJson = File(p.join(tempDir.path, 'other.json'));
      await plainJson.writeAsString(jsonEncode({'hello': 'world'}));
      expect(await contentKindOf(plainJson), FileContentKind.text);
      expect(isRunReportFile(plainJson), isFalse);
    });
  });

  group('WorkbenchRunHistory', () {
    test('appends and deduplicates report paths', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final File first = File(p.join(tempDir.path, 'step1_report.json'));
      final File dup = File(p.join(tempDir.path, '.', 'step1_report.json'));
      final File second = File(p.join(tempDir.path, 'step2_report.json'));

      final WorkbenchRunHistory history =
          container.read(workbenchRunHistoryProvider.notifier);
      history.add(first);
      history.add(dup);
      history.add(second);

      final List<File> list = container.read(workbenchRunHistoryProvider);
      expect(list.length, 2);
      expect(p.basename(list[0].path), 'step1_report.json');
      expect(p.basename(list[1].path), 'step2_report.json');

      history.clear();
      expect(container.read(workbenchRunHistoryProvider), isEmpty);
    });
  });
}
