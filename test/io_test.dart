import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/io.dart';

void main() {
  test('Test find files in dir', () {
    // Get index of "Standard Code" in NCBI table
    final Directory dir = Directory("test/files");
    // Get NCBI table map
    final List<({File file, bool isNew})> files =
        DirectoryCrawler(dir).crawl(recursive: false);

    expect(files.length, 2);
  });

  test('Supported file test', () {
    final File file = File("test/files/test.txt");
    bool supported = FileAssociation(file: file).isSupportedViewExtension;
    expect(supported, true);
  });

  test('Supported view test', () {
    final File file = File("test/files/test.txt");
    bool supported = FileAssociation(file: file).isSupportedViewExtension;
    expect(supported, true);
  });

  test('Format file size test', () {
    const int fileSize = 1024;
    const int fileSize2 = 1024 * 1024;
    FileUtils utils = FileUtils();
    String size = utils.formatSize(fileSize);
    String size2 = utils.formatSize(fileSize2);
    expect(size, "1.00 Kb");
    expect(size2, "1.00 Mb");
  });
}
