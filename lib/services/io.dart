import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:segui/screens/shared/types.dart';

PlatformType get runningPlatform {
  if (Platform.isAndroid || Platform.isIOS) {
    return PlatformType.isMobile;
  } else {
    return PlatformType.isDesktop;
  }
}

Future<String> getOutputDir(String? outputCtr) async {
  if (Platform.isIOS || outputCtr == null) {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir.path;
  } else {
    return outputCtr;
  }
}
