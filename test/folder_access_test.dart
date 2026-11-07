import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/settings/folder_access.dart';
import 'package:segui/screens/settings/settings.dart';
import 'package:segui/services/io/folder_access.dart';
import 'package:segui/services/providers/folder_access.dart';
import 'package:segui/styles/themes.dart';

/// Stands in for the native side, which only macOS has.
class FakeFolderAccess extends FolderAccess {
  FakeFolderAccess(this.folders);

  final List<String> folders;

  @override
  FutureOr<List<String>> build() => folders;

  @override
  Future<void> forget(String path) async {
    state = AsyncValue.data([
      for (final String folder in state.requireValue)
        if (folder != path) folder,
    ]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('segui/folder_access');
  final List<MethodCall> calls = [];
  final String home = p.join(Directory.systemTemp.path, 'segui-home');
  final String data = p.join(home, 'data');

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'restore' || 'list' => [home],
        // The native side keeps only folders.
        'remember' => [data],
        _ => null,
      };
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('FolderAccessChannel', () {
    test('restores and lists saved folders only on macOS', () async {
      final FolderAccessChannel access = FolderAccessChannel.instance;
      final List<String> expected = Platform.isMacOS ? [home] : [];

      expect(await access.restore(), expected);
      expect(await access.list(), expected);
      expect(calls.length, Platform.isMacOS ? 2 : 0);
    });

    test('sends picked paths and returns the saved folders', () async {
      final String file = p.join(data, 'locus.fasta');
      final List<String> saved =
          await FolderAccessChannel.instance.remember([data, file]);

      if (Platform.isMacOS) {
        expect(saved, [data]);
        expect(calls.single.arguments, {
          'paths': [data, file],
        });
      } else {
        expect(saved, isEmpty);
        expect(calls, isEmpty);
      }
    });

    test('skips the native call when nothing was picked', () async {
      expect(await FolderAccessChannel.instance.remember([]), isEmpty);
      expect(calls, isEmpty);
    });
  });

  group('Folder access settings', () {
    Future<void> pumpView(WidgetTester tester, List<String> folders) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          folderAccessProvider.overrideWith(() => FakeFolderAccess(folders)),
        ],
        child: MaterialApp(
          theme: SeguiTheme.lightTheme(),
          home: const Scaffold(body: FolderAccessView()),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('lists folders and removes one', (tester) async {
      await pumpView(tester, [home, data]);

      expect(find.byType(FolderAccessTile), findsNWidgets(2));
      expect(find.text('Add folder'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove access').first);
      await tester.pumpAndSettle();

      expect(find.byType(FolderAccessTile), findsOneWidget);
      expect(find.text(data), findsOneWidget);
    });

    testWidgets('shows an empty state', (tester) async {
      await pumpView(tester, []);

      expect(find.text('No folders yet'), findsOneWidget);
      expect(find.byType(FolderAccessTile), findsNothing);
    });

    test('appears in settings only on macOS', () {
      expect(
        SettingsPage.available.contains(SettingsPage.folderAccess),
        Platform.isMacOS,
      );
    });
  });
}
