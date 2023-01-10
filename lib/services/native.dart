import 'dart:ffi';
import 'dart:io';

import 'package:segui/bridge_generated.dart';

const _base = 'api';

final _dylib = Platform.isWindows ? '$_base.dll' : 'lib$_base.so';

final api = ApiImpl(Platform.isIOS || Platform.isMacOS
    ? DynamicLibrary.process()
    : DynamicLibrary.open(_dylib));
