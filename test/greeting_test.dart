import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/home/components/greeting.dart';
import 'package:segui/services/utils.dart';
import 'package:segui/styles/themes.dart';

void main() {
  test('Greeting follows the hour of day', () {
    expect(GreetingTime.of(DateTime(2026, 1, 1, 0)), GreetingTime.morning);
    expect(GreetingTime.of(DateTime(2026, 1, 1, 11, 59)), GreetingTime.morning);
    expect(GreetingTime.of(DateTime(2026, 1, 1, 12)), GreetingTime.afternoon);
    expect(
        GreetingTime.of(DateTime(2026, 1, 1, 17, 59)), GreetingTime.afternoon);
    expect(GreetingTime.of(DateTime(2026, 1, 1, 18)), GreetingTime.evening);
    expect(GreetingTime.of(DateTime(2026, 1, 1, 23, 59)), GreetingTime.evening);
  });

  test('Every greeting layer is bundled', () {
    for (final time in GreetingTime.values) {
      for (final asset in time.assets) {
        // Asset keys always use POSIX separators.
        final List<String> parts = p.posix.split(asset);
        expect(parts.take(3), ['assets', 'images', 'greeting'], reason: asset);
        expect(File(p.joinAll(parts)).existsSync(), isTrue, reason: asset);
      }
    }
  });

  for (final theme in [SeguiTheme.lightTheme(), SeguiTheme.darkTheme()]) {
    for (final time in GreetingTime.values) {
      testWidgets(
          '${theme.brightness.name} ${time.name} greeting plays once and '
          'replays the flap on tap', (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(body: Center(child: GreetingIllustration(time: time))),
        ));
        expect(tester.hasRunningAnimations, isTrue);
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);

        await tester.tap(find.byType(GreetingIllustration));
        await tester.pump();
        expect(tester.hasRunningAnimations, isTrue);
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.getSize(find.byType(GreetingIllustration)),
            const Size.square(56));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Reduced motion shows the final pose without animating',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: GreetingIllustration(time: GreetingTime.evening),
        ),
      ),
    ));
    expect(tester.hasRunningAnimations, isFalse);

    await tester.tap(find.byType(GreetingIllustration));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });
}
