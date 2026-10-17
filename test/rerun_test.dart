import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/screens/shared/tool_layout.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/services/providers/io.dart';

void main() {
  group('ExecutionButton', () {
    Future<void> pumpTool(
      WidgetTester tester, {
      required VoidCallback onExecuted,
      bool isRunning = false,
    }) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ToolFormLayout(
              form: const [SwitchFormHost()],
              action: ExecutionButton(
                label: 'Split',
                isRunning: isRunning,
                isSuccess: true,
                controller: IOController.empty(),
                onExecuted: onExecuted,
                onShared: null,
                onNewRun: () {},
              ),
            ),
          ),
        ),
      ));
      // The running spinner never settles.
      isRunning ? await tester.pump() : await tester.pumpAndSettle();
    }

    testWidgets('Keeps new run and share after a successful run',
        (tester) async {
      await pumpTool(tester, onExecuted: () {});

      expect(find.text('New run'), findsOneWidget);
      expect(find.text('Quick Share'), findsOneWidget);
      expect(find.text('Re-run'), findsNothing);
    });

    testWidgets('Offers a re-run after the options change', (tester) async {
      int runs = 0;
      await pumpTool(tester, onExecuted: () => runs++);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Re-run'), findsOneWidget);
      expect(find.text('New run'), findsNothing);

      await tester.tap(find.text('Re-run'));
      await tester.pumpAndSettle();

      expect(runs, 1);
      // The run started, so the options match it again.
      expect(find.text('Re-run'), findsNothing);
      expect(find.text('New run'), findsOneWidget);
    });

    testWidgets('Shows only the running state during a re-run', (tester) async {
      await pumpTool(tester, isRunning: true, onExecuted: () {});

      expect(find.text('Running'), findsOneWidget);
      expect(find.text('New run'), findsNothing);
    });
  });

  group('FileOutput.markRunStart', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('segui_rerun_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Counts only files from the latest run as new', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final FileOutput output = container.read(fileOutputProvider.notifier);
      await container.read(fileOutputProvider.future);
      await output.add(tempDir);

      final File first = File(p.join(tempDir.path, 'first.nex'));
      await first.writeAsString('first');
      await output.refresh();
      expect(_newPaths(container), contains(first.path));

      output.markRunStart();
      expect(_newPaths(container), isEmpty);
    });
  });
}

List<String> _newPaths(ProviderContainer container) {
  return container
      .read(fileOutputProvider)
      .requireValue
      .files
      .where((f) => f.isNew)
      .map((f) => f.file.path)
      .toList();
}

/// A tool option the tests can toggle.
class SwitchFormHost extends StatefulWidget {
  const SwitchFormHost({super.key});

  @override
  State<SwitchFormHost> createState() => _SwitchFormHostState();
}

class _SwitchFormHostState extends State<SwitchFormHost> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return SwitchForm(
      label: 'Check partition for errors',
      value: _value,
      onPressed: (value) => setState(() => _value = value),
    );
  }
}
