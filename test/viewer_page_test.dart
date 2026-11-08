import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/home/compact_screen.dart';
import 'package:segui/screens/home/components/navigation.dart';
import 'package:segui/screens/home/components/pages.dart';
import 'package:segui/screens/home/large_screen.dart';
import 'package:segui/screens/home/more_page.dart';
import 'package:segui/screens/settings/settings.dart';
import 'package:segui/screens/viewers/common.dart';
import 'package:segui/screens/viewers/viewer_page.dart';
import 'package:segui/services/providers/alignment_view.dart';
import 'package:segui/services/providers/navigation.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/services/providers/viewer.dart';
import 'package:segui/services/viewers/viewer_files.dart';
import 'package:segui/src/rust/api/file_sort.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<int> _pathOrder(
  List<String> paths,
  FileSortKey key, {
  required bool ascending,
  List<int?> sizes = const [],
}) {
  return List.generate(paths.length, (i) => i)
    ..sort((a, b) => paths[a].compareTo(paths[b]));
}

void main() {
  late Directory dir;
  late ProviderContainer container;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('segui-viewer-page-');
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        settingProvider.overrideWithValue(preferences),
        fileOrderProvider.overrideWithValue(_pathOrder),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await dir.delete(recursive: true);
  });

  File write(String name, [String content = 'hello\n']) {
    final File file = File(p.join(dir.path, name));
    file.writeAsStringSync(content);
    return file;
  }

  Future<void> pump(WidgetTester tester, Widget home, {double width = 390}) {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: SeguiTheme.lightTheme(), home: home),
    ));
  }

  group('ViewerPage', () {
    testWidgets('Empty viewer asks for files and lists recent ones',
        (tester) async {
      container.read(viewerRecentsProvider.notifier)
        ..record(ViewerRecent(path: write('old.txt').path, isFolder: false))
        ..record(ViewerRecent(path: dir.path, isFolder: true));
      await pump(tester, const ViewerPage());
      expect(find.byTooltip('Open file'), findsOneWidget);
      expect(find.byTooltip('Open folder'), findsOneWidget);
      expect(find.text('Open a file or folder to view'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.byType(ViewerRecentTile), findsNWidgets(2));

      await tester.tap(find.byTooltip('Remove from recent').first);
      await tester.pump();
      expect(find.byType(ViewerRecentTile), findsOneWidget);
    });

    testWidgets('A recent folder that is gone is removed with a note',
        (tester) async {
      final String gone = p.join(dir.path, 'gone');
      container
          .read(viewerRecentsProvider.notifier)
          .record(ViewerRecent(path: gone, isFolder: true));
      await pump(tester, const ViewerPage());
      await tester.tap(find.byType(ViewerRecentTile));
      await tester.pump();
      expect(find.byType(ViewerRecentTile), findsNothing);
      expect(find.text('Open gone again to view it'), findsOneWidget);
    });

    testWidgets('Opened files list, filter, and open in their viewer',
        (tester) async {
      container.read(viewerFilesProvider.notifier).addFiles([
        for (int i = 0; i < 9; i++) write('note_$i.txt', 'line $i\n'),
      ]);
      await pump(tester, const ViewerPage());
      expect(find.text('9 files'), findsOneWidget);
      expect(find.byType(ViewerFileTile), findsWidgets);

      await tester.enterText(find.byType(TextField), 'note_3');
      await tester.pump();
      expect(find.byType(ViewerFileTile), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('note_3.txt'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(find.byType(FileView), findsOneWidget);
    });

    testWidgets('Clear empties the list', (tester) async {
      container.read(viewerFilesProvider.notifier).addFiles([write('a.txt')]);
      await pump(tester, const ViewerPage());
      expect(find.text('1 file'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(find.byType(ViewerEmptyState), findsOneWidget);
    });
  });

  group('Navigation', () {
    testWidgets('Phones have a full More tab with the viewer and settings',
        (tester) async {
      await pump(tester, const CompactScreenView());
      final NavigationBar bar = tester.widget(find.byType(NavigationBar));
      expect(bar.destinations, hasLength(navigationTargets.length + 1));
      // Settings left the app bar for More.
      expect(find.byType(SettingButtons), findsNothing);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(container.read(tabSelectionProvider), moreTab);
      expect(find.byType(MorePage), findsOneWidget);
      expect(find.text('Quick settings'), findsOneWidget);
      expect(find.text('Colors'), findsOneWidget);

      await tester.tap(find.text('Viewer'));
      await tester.pumpAndSettle();
      expect(find.byType(ViewerPage), findsOneWidget);
    });

    testWidgets('Wider windows open Home instead of More', (tester) async {
      container.read(tabSelectionProvider.notifier).setTab(moreTab);
      await pump(tester, const LargeScreenView(), width: 1200);
      await tester.pumpAndSettle();
      final NavigationRail rail = tester.widget(find.byType(NavigationRail));
      expect(rail.selectedIndex, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('The rail has a viewer button', (tester) async {
      await pump(tester, const LargeScreenView(), width: 1200);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ViewerButton));
      await tester.pumpAndSettle();
      expect(find.byType(ViewerPage), findsOneWidget);
    });

    testWidgets('The drawer has a viewer entry', (tester) async {
      await pump(tester, const LargeScreenView(), width: 1600);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ViewerMenuTile));
      await tester.pumpAndSettle();
      expect(find.byType(ViewerPage), findsOneWidget);
    });
  });
}
