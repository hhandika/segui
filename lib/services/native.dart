import 'dart:ffi';
import 'dart:io';

import '../bridge_generated.dart';

export 'package:segui/bridge_generated.dart';

const _base = 'segul_api';

final _dylib = Platform.isWindows ? '$_base.dll' : 'lib$_base.so';

final segulApi = SegulApiImpl(Platform.isIOS || Platform.isMacOS
    ? DynamicLibrary.process()
    : DynamicLibrary.open(_dylib));
