import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

void main() {
  Future<void> pumpForm(WidgetTester tester, List<Widget> children) {
    return tester.pumpWidget(MaterialApp(
      theme: SeguiTheme.lightTheme(),
      home: Scaffold(
        body: SingleChildScrollView(child: FormCard(children: children)),
      ),
    ));
  }

  testWidgets('Fields in a form card do not overlap', (tester) async {
    await pumpForm(tester, [
      DropdownButtonFormField<String>(
        key: const Key('method'),
        initialValue: 'a',
        decoration: const InputDecoration(labelText: 'Filter by'),
        items: const [DropdownMenuItem(value: 'a', child: Text('A'))],
        onChanged: (_) {},
      ),
      const TextField(
        key: Key('value'),
        decoration: InputDecoration(
          labelText: 'Minimum length',
          helperText: 'Keeps alignments with at least this many sites.',
        ),
      ),
    ]);

    final Rect method = tester.getRect(find.byKey(const Key('method')));
    final Rect value = tester.getRect(find.byKey(const Key('value')));
    expect(
        value.top - method.bottom, moreOrLessEquals(SeguiFormLayout.fieldGap));
  });

  testWidgets('Helper text sits closer to its field than to the next one',
      (tester) async {
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpForm(tester, [
      FieldWithHelper(
        helper: 'Output is unaligned FASTA.',
        child: Container(key: const Key('field'), height: 56),
      ),
      SharedTextField(
        key: const Key('next'),
        label: 'Prefix',
        hint: 'E.g., output',
        controller: controller,
      ),
    ]);

    final Rect field = tester.getRect(find.byKey(const Key('field')));
    final Rect helper = tester.getRect(find.text('Output is unaligned FASTA.'));
    final Rect next = tester.getRect(find.byKey(const Key('next')));
    final double helperGap = helper.top - field.bottom;
    final double fieldGap = next.top - helper.bottom;
    expect(helperGap, moreOrLessEquals(SeguiFormLayout.helperGap));
    expect(fieldGap, greaterThan(helperGap));
  });

  testWidgets('Segmented fields and switches show their helper text',
      (tester) async {
    await pumpForm(tester, [
      SharedDropdownField(
        value: 'Auto',
        label: 'Format',
        items: const ['Auto', 'FASTA'],
        helper: 'Detects the format from each file extension.',
        onChanged: (_) {},
      ),
      SwitchForm(
        label: 'Add all to a single file',
        helper: 'Every sequence is added to one destination file.',
        value: true,
        onPressed: (_) {},
      ),
    ]);

    expect(find.text('Detects the format from each file extension.'),
        findsOneWidget);
    expect(find.text('Every sequence is added to one destination file.'),
        findsOneWidget);
  });
}
