import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:segui/services/types.dart';

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

String showOutputDir(String outputDir) {
  if (Platform.isIOS) {
    return 'On My Devices/segui';
  } else {
    return outputDir;
  }
}

String getOutputFmt(String outputFormat, bool isInterleave) {
  if (isInterleave) {
    return '$outputFormat-int';
  } else {
    return outputFormat;
  }
}

String getPartitionFmt(String partitionFormat, bool isCodon) {
  if (isCodon) {
    return '$partitionFormat-codon';
  } else {
    return partitionFormat;
  }
}
