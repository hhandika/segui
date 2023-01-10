import 'dart:ffi';
import 'dart:io';

import 'package:segul_gui/bridge_generated.dart';

const _base = 'native';

final _dylib = Platform.isWindows ? '$_base.dll' : 'lib$_base.so';

final api = NativeImpl(Platform.isIOS || Platform.isMacOS
    ? DynamicLibrary.process()
    : DynamicLibrary.open(_dylib));
