import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/alignment/distance.dart';
import 'package:segui/screens/shared/group_preview.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/tasks/alignment.dart';
import 'package:segui/src/rust/api/sequence.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Distance grouping validators', () {
    test('Delimiter must be one character', () {
      expect(isValidGroupDelimiter('_'), isTrue);
      expect(isValidGroupDelimiter(' '), isTrue);
      expect(isValidGroupDelimiter(''), isFalse);
      expect(isValidGroupDelimiter('__'), isFalse);
    });

    test('Fields must be one or more', () {
      expect(isValidGroupFields('2'), isTrue);
      expect(isValidGroupFields(' 1 '), isTrue);
      expect(isValidGroupFields('0'), isFalse);
      expect(isValidGroupFields('two'), isFalse);
    });

    test('Regex must be non-empty and well formed', () {
      expect(isValidGroupRegex(r'^(\w+)_'), isTrue);
      expect(isValidGroupRegex(''), isFalse);
      expect(isValidGroupRegex('('), isFalse);
    });
  });

  group('DistanceGrouping', () {
    final String groupPath = p.join('data', 'groups.csv');
    final List<SegulInputFile> withGroupFile = [
      SegulInputFile(
        file: File(p.join('data', 'locus.fas')),
        type: SegulType.standardSequence,
      ),
      SegulInputFile(file: File(groupPath), type: SegulType.sampleGroup),
    ];

    test('No grouping is always valid', () {
      const grouping = DistanceGrouping.none();
      expect(grouping.isEnabled, isFalse);
      expect(grouping.isValid(const []), isTrue);
      expect(grouping.toParams(const []), const DistanceGroupingParams.none());
    });

    test('Delimiter grouping builds params', () {
      const grouping =
          DistanceGrouping(method: 'delimiter', delimiter: '_', fields: '2');
      expect(grouping.isValid(const []), isTrue);
      expect(
        grouping.toParams(const []),
        DistanceGroupingParams.delimiter(delimiter: '_', fields: BigInt.two),
      );
      expect(
        const DistanceGrouping(method: 'delimiter', delimiter: '_')
            .isValid(const []),
        isFalse,
      );
    });

    test('Regex and auto grouping build params', () {
      const regex = DistanceGrouping(method: 'regex', pattern: '^sp');
      expect(
          regex.toParams(const []), const DistanceGroupingParams.regex('^sp'));
      const auto = DistanceGrouping(method: 'auto');
      expect(auto.isValid(const []), isTrue);
      expect(auto.toParams(const []), const DistanceGroupingParams.auto());
    });

    test('File grouping needs one group file', () {
      const grouping = DistanceGrouping(method: 'file');
      expect(grouping.isValid(withGroupFile), isTrue);
      expect(grouping.isValid(withGroupFile.take(1).toList()), isFalse);
      expect(
        grouping.toParams(withGroupFile),
        DistanceGroupingParams.mapFile(groupPath),
      );
      expect(() => grouping.toParams(const []), throwsA(isA<String>()));
    });
  });

  testWidgets('Group preview lists groups and unassigned samples',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: SeguiTheme.lightTheme(),
      home: Scaffold(
        body: SampleGroupPreview(
          preview: DistanceGroupPreview(
            delimiter: '_',
            fields: BigInt.two,
            sampleCount: BigInt.from(5),
            groups: [
              DistanceGroupCount(name: 'Rattus_rattus', count: BigInt.two),
              DistanceGroupCount(name: 'Mus_musculus', count: BigInt.two),
            ],
            unassigned: const ['outgroup'],
          ),
        ),
      ),
    ));

    expect(find.text('2 groups from 5 samples'), findsOneWidget);
    expect(
        find.textContaining('split on "_" and keep 2 fields'), findsOneWidget);
    expect(find.byType(GroupCountChip), findsNWidgets(2));
    expect(find.textContaining('1 sample matches no group'), findsOneWidget);
  });

  testWidgets('Grouping fields follow the selected method', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [settingProvider.overrideWithValue(preferences)],
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: const Scaffold(body: AlignmentDistancePage()),
      ),
    ));
    await tester.pumpAndSettle();

    Future<void> selectMethod(String from, String to) async {
      await tester.tap(find.text(from));
      await tester.pumpAndSettle();
      await tester.tap(find.text(to).last);
      await tester.pumpAndSettle();
    }

    expect(find.text('Delimiter'), findsNothing);
    expect(find.text('Long-format tables'), findsOneWidget);
    expect(find.text('Zero'), findsOneWidget);

    // With groups, the diagonal defaults to the within-group mean.
    await selectMethod('No grouping', 'Split sample names');
    expect(find.text('Mean within the group'), findsOneWidget);
    expect(find.text('Delimiter'), findsOneWidget);
    expect(find.text('Fields to keep'), findsOneWidget);
    expect(find.text('Preview groups'), findsOneWidget);

    await selectMethod('Split sample names', 'Regular expression');
    expect(find.text('Delimiter'), findsNothing);
    expect(find.text('Regex pattern'), findsOneWidget);

    await selectMethod('Regular expression', 'Detect from sample names');
    expect(find.text('Regex pattern'), findsNothing);
    expect(find.text('Detect groups'), findsOneWidget);

    // Without groups, the diagonal returns to zero.
    await selectMethod('Detect from sample names', 'No grouping');
    expect(find.text('Mean within the group'), findsNothing);
    expect(find.text('Zero'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
