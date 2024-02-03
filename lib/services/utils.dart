import 'package:url_launcher/url_launcher.dart';

const String segulDocUrl = 'https://www.segul.app/';

/// Material You design system recommend screen size
/// Desktop/Expanded screen: 840dp
/// Tablet/Medium screen: 600dp
/// Mobile/Compact screen: 360dp
const double expandedScreenSize = 840;
const double mediumScreenSize = 600;
const double compactScreenSize = 360;

String get greeting {
  int hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good morning!';
  } else if (hour < 18) {
    return 'Good afternoon!';
  } else {
    return 'Good evening!';
  }
}

String get greetingIconPack {
  int hour = DateTime.now().hour;
  if (hour < 12) {
    return 'assets/images/sunrise.svg';
  } else if (hour < 18) {
    return 'assets/images/afternoon.svg';
  } else {
    return 'assets/images/night.svg';
  }
}

String get emptyDirIcon {
  return 'assets/images/empty-folder.svg';
}

void launchSegulDocUrl() {
  String url = segulDocUrl;
  Uri uri = Uri.parse(url);
  launchUrl(uri);
}
