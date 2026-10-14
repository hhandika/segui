import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/equal_height_grid.dart';
import 'package:segui/styles/decoration.dart';

void main() {
  test('Grid column count grows with width up to the maximum', () {
    int columns(double width) =>
        gridColumnCount(width, minItemWidth: 300, maxColumns: 6);
    expect(columns(200), 1);
    expect(columns(611), 1);
    expect(columns(612), 2);
    expect(columns(1068), 3);
    // Content area beside the navigation drawer on a 2560 px monitor.
    expect(columns(2200), 6);
    expect(columns(4000), 6);
  });

  testWidgets('Equal height grid sizes every child like the tallest',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 612,
          child: EqualHeightGrid(
            columns: 2,
            children: [
              const SizedBox(key: Key('short'), height: 40),
              const SizedBox(key: Key('tall'), height: 90),
              Container(key: const Key('flex'), color: const Color(0xFF00FF00)),
            ],
          ),
        ),
      ),
    ));

    for (final key in ['short', 'tall', 'flex']) {
      expect(tester.getSize(find.byKey(Key(key))), const Size(300, 90));
    }
    expect(tester.getTopLeft(find.byKey(const Key('tall'))).dx, 312);
    expect(tester.getTopLeft(find.byKey(const Key('flex'))).dy, 102);
    expect(tester.getSize(find.byType(EqualHeightGrid)).height, 192);
  });
}
