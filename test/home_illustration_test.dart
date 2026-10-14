import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/home/components/illustration.dart';
import 'package:segui/styles/themes.dart';

void main() {
  test('Illustration placeholders map to theme colors', () {
    const mapper = HomeIllustrationColors(
      line: Color(0xFF111111),
      accent: Color(0xFF222222),
      fill: Color(0xFF333333),
    );
    Color map(Color color) => mapper.substitute(null, 'path', 'fill', color);
    expect(map(HomeIllustrationColors.lineKey), const Color(0xFF111111));
    expect(map(HomeIllustrationColors.accentKey), const Color(0xFF222222));
    expect(map(HomeIllustrationColors.fillKey), const Color(0xFF333333));
    expect(map(const Color(0xFFC0FFEE)), const Color(0xFFC0FFEE));
  });

  for (final theme in [SeguiTheme.lightTheme(), SeguiTheme.darkTheme()]) {
    testWidgets(
        '${theme.brightness.name} illustration is decorative and '
        'shows the whole sketch on phones', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(body: HomeIllustration()),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);
      final Size size = tester.getSize(find.byType(HomeIllustration));
      expect(size.width, 360);
      expect(size.height, closeTo(360 * 196 / 1200, 0.01));
      expect(
        find.descendant(
          of: find.byType(HomeIllustration),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  }

  testWidgets('Illustration stays capped on wide monitors', (tester) async {
    tester.view.physicalSize = const Size(2200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: SeguiTheme.lightTheme(),
      home: const Scaffold(body: HomeIllustration()),
    ));
    await tester.pumpAndSettle();
    final Size size = tester.getSize(find.byType(SvgPicture));
    expect(size.width, 1200);
    expect(size.height, closeTo(196, 0.01));
  });
}
