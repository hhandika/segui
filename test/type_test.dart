// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/types.dart';

void main() {
  test('Test NCBI table map', () {
    // Get index of "Standard Code" in NCBI table
    final int index = translationTable.indexOf("Standard Code");
    // Get NCBI table map
    final String? indexStr = translationTableMap[index];

    expect(indexStr, "1");
  });

  test('Supported file test', () {
    final File file = File("test.txt");
    bool supported = FileAssociation(file: file).isSupportedViewExtension;
    expect(supported, true);
  });
}
