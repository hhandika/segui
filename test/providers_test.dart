import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/io/file.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/providers/navigation.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('File input keeps earlier files when adding more', () async {
    final notifier = container.read(fileInputProvider.notifier);
    await notifier.addFiles(
      [XFile(p.join('test', 'files', 'first.fas'))],
      sequenceTypeGroup,
    );
    await notifier.addMoreFiles(
      [XFile(p.join('test', 'files', 'second.fas'))],
      sequenceTypeGroup,
    );

    final files = container.read(fileInputProvider).value!;
    expect(files.map((f) => p.basename(f.file.path)), [
      'first.fas',
      'second.fas',
    ]);
  });

  test('Changing tabs resets selected input files', () async {
    await container.read(fileInputProvider.notifier).addFiles(
      [XFile(p.join('test', 'files', 'first.fas'))],
      sequenceTypeGroup,
    );
    container.read(tabSelectionProvider.notifier).setTab(2);

    expect(container.read(tabSelectionProvider), 2);
    expect(await container.read(fileInputProvider.future), isEmpty);
  });
}
