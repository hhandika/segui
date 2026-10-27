import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io/export_view.dart';
import 'package:segui/screens/shared/io/file_browser.dart';
import 'package:segui/screens/shared/io/file_tree_view.dart';
import 'package:segui/screens/shared/io/output_view.dart';
import 'package:segui/services/io/export.dart';
import 'package:segui/services/io/output.dart';
import 'package:segui/src/rust/api/archive.dart';
import 'package:segui/styles/themes.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('segui-export-');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  File createFile(List<String> parts) {
    final File file = File(p.joinAll([dir.path, ...parts]));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('content');
    return file;
  }

  group('Export file names', () {
    test('Archives take the name of the folder the files share', () {
      final FileExportServices exporter = FileExportServices(
        files: [
          createFile(['loci', 'set_a', 'a.nex']),
          createFile(['loci', 'set_b', 'b.nex']),
        ],
        format: ExportFormat.tarGz,
      );
      expect(exporter.suggestedName, 'loci.tar.gz');
    });

    test('A single file names its archive', () {
      final FileExportServices exporter = FileExportServices(
        files: [
          createFile(['loci', 'a.nex'])
        ],
        format: ExportFormat.zip,
      );
      expect(exporter.suggestedName, 'a.zip');
    });

    test('Saved paths always end in the format extension', () {
      final String base = p.join(dir.path, 'export');
      const FileExportServices zip =
          FileExportServices(files: [], format: ExportFormat.zip);
      const FileExportServices tarGz =
          FileExportServices(files: [], format: ExportFormat.tarGz);
      expect(zip.withExtension(base), '$base.zip');
      expect(zip.withExtension('$base.ZIP'), '$base.ZIP');
      expect(tarGz.withExtension(base), '$base.tar.gz');
      expect(tarGz.withExtension('$base.tar.gz'), '$base.tar.gz');
    });

    test('Share is not offered on Linux', () {
      expect(canShareFiles, !Platform.isLinux);
    });
  });

  Future<ExportRequest?> openSheet(
    WidgetTester tester, {
    required bool canShare,
    required String button,
    ExportFormat? pick,
  }) async {
    ExportRequest? result;
    await tester.pumpWidget(MaterialApp(
      theme: SeguiTheme.lightTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showResponsiveSheet<ExportRequest>(
                context: context,
                builder: (context) =>
                    ExportFilesSheet(count: 3, canShare: canShare),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Export 3 files'), findsOneWidget);
    expect(find.text('Share'), canShare ? findsOneWidget : findsNothing);
    if (pick != null) {
      await tester.tap(find.text(pick.label));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
    expect(find.byType(ExportFilesSheet), findsNothing);
    return result;
  }

  testWidgets('Export sheet returns the chosen format', (tester) async {
    final ExportRequest? request = await openSheet(tester,
        canShare: false, button: 'Export', pick: ExportFormat.tarGz);
    expect(request, (format: ExportFormat.tarGz, isSharing: false));
  });

  testWidgets('Export sheet can share instead', (tester) async {
    final ExportRequest? request =
        await openSheet(tester, canShare: true, button: 'Share');
    expect(request, (format: ExportFormat.zip, isSharing: true));
  });

  testWidgets('Export sheet cancels without a request', (tester) async {
    final ExportRequest? request =
        await openSheet(tester, canShare: true, button: 'Cancel');
    expect(request, isNull);
  });

  testWidgets('Output selection offers Export in a compact toolbar',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final List<File> files = [
      createFile(['loci', 'a.nex']),
      createFile(['loci', 'b.nex']),
    ];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: Scaffold(
          body: OutputFileList(
            data: SegulOutputFile(
              directory: dir,
              files: [for (final File file in files) (file: file, isNew: true)],
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('Select'));
    await tester.pump();
    await tester.tap(find.byType(FileBrowserTile).first);
    await tester.pump();
    expect(find.text('Share'), findsNothing);

    // The toolbar shrinks to its buttons instead of spanning the panel.
    final Finder toolbar = find.descendant(
      of: find.byType(FileActionToolbar),
      matching: find.byType(DecoratedBox),
    );
    expect(tester.getSize(toolbar.first).width, lessThan(600));
    // Dividers set Export and Delete apart from the count.
    expect(find.byType(FileActionDivider), findsNWidgets(2));

    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    expect(find.byType(ExportFilesSheet), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    // Canceling keeps the selection.
    expect(find.text('1 selected'), findsOneWidget);
  });
}
