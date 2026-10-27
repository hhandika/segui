import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:segui/src/rust/api/common.dart';
import 'package:segui/src/rust/frb_generated.dart';

/// The Rust library path that Flutter native assets bundle into the app.
///
/// Returns null on Android, where the library lives inside the APK.
String? bundledRustLibraryPath() {
  final executableDir = p.dirname(Platform.resolvedExecutable);
  if (Platform.isLinux) {
    return p.join(executableDir, 'lib', 'librust_lib.so');
  }
  if (Platform.isWindows) {
    return p.join(executableDir, 'rust_lib.dll');
  }
  if (Platform.isMacOS) {
    // The executable sits in Contents/MacOS; frameworks sit in Contents.
    return p.join(p.dirname(executableDir), 'Frameworks', 'rust_lib.framework',
        'rust_lib');
  }
  if (Platform.isIOS) {
    return p.join(
        executableDir, 'Frameworks', 'rust_lib.framework', 'rust_lib');
  }
  return null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => RustLib.init());

  tearDownAll(RustLib.dispose);

  test('Default loader opens the Rust library', () async {
    expect(await getApiVersion(), isNotEmpty);
  });

  test('Native assets bundle the Rust library with the app', () {
    final path = bundledRustLibraryPath()!;
    expect(File(path).existsSync(), isTrue, reason: path);
  }, skip: Platform.isAndroid ? 'The library lives inside the APK' : false);

  test('The process maps the bundled library, not a Cargo build', () async {
    final bundled = File(bundledRustLibraryPath()!).resolveSymbolicLinksSync();
    final maps = await File(p.join('/proc', 'self', 'maps')).readAsLines();
    final mapped = {
      for (final line in maps)
        if (line.endsWith('librust_lib.so'))
          File(line.substring(line.indexOf('/'))).resolveSymbolicLinksSync(),
    };
    expect(mapped, {bundled});
  }, skip: Platform.isLinux ? false : 'Only Linux exposes /proc/self/maps');
}
