import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/io/picker_widget.dart';
import 'package:segui/services/io/archive_input.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/io/mobile_io.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/styles/themes.dart';

void main() {
  group('Archive paths', () {
    test('Zip and gzip-compressed tar archives are accepted', () {
      final posix = p.Context(style: p.Style.posix);
      expect(isArchivePath(posix.join('data', 'loci.zip')), isTrue);
      expect(isArchivePath(posix.join('data', 'loci.TAR.GZ')), isTrue);
      expect(isArchivePath(posix.join('data', 'loci.tgz')), isTrue);
    });

    test('Gzipped sequences and other files are not archives', () {
      expect(isArchivePath('reads.fq.gz'), isFalse);
      expect(isArchivePath('loci.nex'), isFalse);
      expect(isArchivePath('loci.rar'), isFalse);
    });
  });

  group('Picked files', () {
    test('Files in other formats are skipped', () {
      final picked = [
        XFile(p.join('picked', 'a.nex')),
        XFile(p.join('picked', 'b.fasta')),
        XFile(p.join('picked', 'notes.docx')),
      ];
      final result = filterPickedFiles(picked, sequenceTypeGroup);
      expect(result.files.map((e) => p.basename(e.path)), ['a.nex', 'b.fasta']);
      expect(result.skipped, 1);
    });

    test('Running out of memory suggests a folder or archive', () {
      final error = InputPickException.fromPlatform(
        PlatformException(code: 'out_of_memory'),
      );
      expect(error.toString(), contains('Browse folder'));
      expect(error.toString(), contains('Open archive'));
    });

    test('Copy progress is unknown until the total is counted', () {
      expect(const InputCopyProgress.preparing().fraction, isNull);
      expect(const InputCopyProgress(copied: 50, total: 200).fraction, 0.25);
    });
  });

  group('Archive input', () {
    test('Raw reads are added as regular files, not extracted', () {
      expect(acceptsArchiveInput(genomicRawReadTypeGroup), isFalse);
      expect(acceptsArchiveInput(sequenceTypeGroup), isTrue);
    });
  });

  group('Shared files', () {
    test('Desktop apps have no shared files', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(sharedInputProvider), 0);
    });
  });

  group('File picker', () {
    testWidgets('Multi-file pickers offer an archive', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: SeguiTheme.lightTheme(),
            home: const Scaffold(
              body: SharedFilePicker(
                label: 'Alignments',
                allowMultiple: true,
                xTypeGroup: sequenceTypeGroup,
                hasSecondaryPicker: false,
                task: SupportedTask.alignmentConcatenation,
                allowDirectorySelection: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Browse files'), findsOneWidget);
      expect(find.text('Browse folder'), findsOneWidget);
      expect(find.text('Open archive'), findsOneWidget);
      expect(find.text('SEGUI folder'),
          Platform.isIOS ? findsOneWidget : findsNothing);
    });

    testWidgets('Raw read pickers do not offer an archive', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: SeguiTheme.lightTheme(),
            home: const Scaffold(
              body: SharedFilePicker(
                label: 'Raw reads',
                allowMultiple: true,
                xTypeGroup: genomicRawReadTypeGroup,
                hasSecondaryPicker: false,
                task: SupportedTask.genomicRawReadSummary,
                allowDirectorySelection: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Browse files'), findsOneWidget);
      expect(find.text('Browse folder'), findsOneWidget);
      expect(find.text('Open archive'), findsNothing);
    });

    testWidgets('Single-file pickers do not offer an archive', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: SeguiTheme.lightTheme(),
            home: const Scaffold(
              body: SharedFilePicker(
                label: 'Partition',
                allowMultiple: false,
                xTypeGroup: partitionTypeGroup,
                hasSecondaryPicker: false,
                task: SupportedTask.partitionConversion,
                allowDirectorySelection: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open archive'), findsNothing);
    });
  });
}
