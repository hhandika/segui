import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segui/screens/home/compact_screen.dart';
import 'package:segui/screens/home/components/navigation.dart';
import 'package:segui/screens/home/home.dart';
import 'package:segui/styles/themes.dart';

void main() {
  for (final bottomInset in [24.0, 48.0]) {
    testWidgets('Android controls avoid a $bottomInset system navigation inset',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      tester.view.padding = FakeViewPadding(top: 24, bottom: bottomInset);
      tester.view.viewPadding = FakeViewPadding(top: 24, bottom: bottomInset);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: SeguiTheme.lightTheme(null),
          home: const CompactScreenView(),
        ),
      ));
      await tester.pumpAndSettle();

      final title = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('SEGUL GUI'),
      );
      expect(tester.getTopLeft(title).dy, greaterThanOrEqualTo(24));
      final nav = find.byType(CompactScreenNavBar);
      for (final target in navigationTargets) {
        final label = find.descendant(
          of: nav,
          matching: find.text(target.label),
        );
        expect(tester.getBottomRight(label).dy,
            lessThanOrEqualTo(800 - bottomInset));
      }
      expect(tester.getBottomRight(find.byType(HomePage)).dy,
          lessThanOrEqualTo(tester.getTopLeft(nav).dy));
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }
}
