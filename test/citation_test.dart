import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/home/components/citation.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/themes.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: SeguiTheme.lightTheme(),
      home: const Scaffold(body: Center(child: CiteSegulButton())),
    ));
  }

  testWidgets('Citation opens as a dialog on wide screens', (tester) async {
    await pumpButton(tester, const Size(1200, 800));
    await tester.tap(find.text('Cite SEGUL'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(CitationContent), findsOneWidget);
    expect(find.text('View article'), findsOneWidget);
  });

  testWidgets('Citation opens as a bottom sheet on phones', (tester) async {
    await pumpButton(tester, const Size(390, 844));
    await tester.tap(find.text('Cite SEGUL'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(CitationContent), findsOneWidget);
  });

  testWidgets('Copy button puts the citation on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpButton(tester, const Size(1200, 800));
    await tester.tap(find.text('Cite SEGUL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy citation'));
    await tester.pumpAndSettle();

    expect(copied, segulCitation);
    expect(copied, contains('Handika, H., and J. A. Esselstyn. 2024.'));
    expect(copied, contains('https://doi.org/10.1111/1755-0998.13964'));
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets('Responsive sheet content fits a phone sheet', (tester) async {
    await pumpButton(tester, const Size(390, 600));
    await tester.tap(find.text('Cite SEGUL'));
    await tester.pumpAndSettle();
    expect(find.byType(SheetContent), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
