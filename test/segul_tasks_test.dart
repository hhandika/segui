import 'package:flutter_test/flutter_test.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/tasks/alignment.dart';
import 'package:segui/services/tasks/sequences.dart';
import 'package:segui/services/types.dart';

void main() {
  test('Proportions and counts reject out-of-range values', () {
    expect(isValidProportion('0'), isTrue);
    expect(isValidProportion(' 0.5 '), isTrue);
    expect(isValidProportion('1'), isTrue);
    expect(isValidProportion('1.2'), isFalse);
    expect(isValidProportion('-0.1'), isFalse);
    expect(isValidProportion(''), isFalse);

    expect(isValidCount('0'), isTrue);
    expect(isValidCount('120'), isTrue);
    expect(isValidCount('1.5'), isFalse);
    expect(isValidCount('-3'), isFalse);
    expect(isValidCount('abc'), isFalse);
  });

  test('Filtering values match the selected option', () {
    expect(isValidFilteringValue(FilteringOptions.missingData, '0.3'), isTrue);
    expect(isValidFilteringValue(FilteringOptions.missingData, '30'), isFalse);
    expect(
        isValidFilteringValue(FilteringOptions.maximalLength, '5000'), isTrue);
    expect(isValidFilteringValue(FilteringOptions.maximalParsimonyInf, '0.5'),
        isFalse);

    expect(isValidTrimmingValue(TrimmingOptions.missingData, '0.5'), isTrue);
    expect(isValidTrimmingValue(TrimmingOptions.parsimonyInf, '2'), isTrue);
    expect(isValidTrimmingValue(TrimmingOptions.parsimonyInf, '0.5'), isFalse);

    expect(
        isValidSequenceFilteringValue(
            SequenceFilteringOptions.maximalGap, '0.5'),
        isTrue);
    expect(
        isValidSequenceFilteringValue(
            SequenceFilteringOptions.minimalLength, '0.5'),
        isFalse);
  });

  test('Distance models follow SEGUL data type rules', () {
    expect(distanceModelsFor('DNA'), containsAll(['p', 'jc69', 'k2p', 'tn93']));
    expect(distanceModelsFor('DNA'), isNot(contains('poisson')));
    expect(distanceModelsFor('AA'), ['p', 'jc69', 'poisson']);
    expect(distanceModelsFor('Ignore'), isEmpty);
    for (final models in [distanceModelsFor('DNA'), distanceModelsFor('AA')]) {
      expect(distanceModels.keys, containsAll(models));
    }
  });

  test('Every translation table maps to an NCBI table number', () {
    expect(translationTableMap, hasLength(translationTable.length));
    final int echinoderm =
        translationTable.indexOf('Echinoderm and Flatworm Mitochondrial Code');
    expect(translationTableMap[echinoderm], '9');
    expect(translationTableMap[translationTable.length - 1], '33');
  });

  test('New input groups map to distinct file types', () {
    expect(
        matchTypeByXTypeGroup(sequenceTypeGroup), SegulType.standardSequence);
    expect(matchTypeByXTypeGroup(destinationSequenceTypeGroup),
        SegulType.destinationSequence);
    expect(matchTypeByXTypeGroup(mafTypeGroup), SegulType.multipleAlignment);
    expect(matchTypeByXTypeGroup(bedTypeGroup), SegulType.bed);
  });

  test('Every task has a default output directory', () {
    expect(defaultOutputDir.keys, containsAll(SupportedTask.values));
    expect(defaultOutputDir.values.toSet(),
        hasLength(SupportedTask.values.length));
  });

  test('Interleaved output appends the SEGUL suffix', () {
    expect(getOutputFmt('FASTA', true), 'FASTA-int');
    expect(getOutputFmt('PHYLIP', false), 'PHYLIP');
  });
}
