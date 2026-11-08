import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/styles/themes.dart';

void main() {
  testWidgets('Phone sheets span the screen even with narrow content',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: SeguiTheme.lightTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showResponsiveSheet<void>(
                context: context,
                builder: (context) => const Text('Narrow'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.getSize(find.byType(BottomSheet)).width, 390);
  });
}
