import 'package:package_info_plus/package_info_plus.dart';
import 'package:segui/src/rust/api/common.dart';
import 'package:url_launcher/url_launcher.dart';

const String segulDocUrl = 'https://www.segul.app/';

/// The SEGUL paper to cite, as on the documentation website.
const String segulArticleUrl = 'https://doi.org/10.1111/1755-0998.13964';

/// Citation authors and year, before the title.
const String segulCitationAuthors = 'Handika, H., and J. A. Esselstyn. 2024.';
const String segulCitationTitle = 'SEGUL: Ultrafast, memory-efficient and '
    'mobile-friendly software for manipulating and summarizing '
    'phylogenomic datasets.';
const String segulCitationJournal = 'Molecular Ecology Resources';
const String segulCitationIssue = '24(7)';

/// Plain-text citation for copying.
const String segulCitation = '$segulCitationAuthors $segulCitationTitle '
    '$segulCitationJournal, $segulCitationIssue. $segulArticleUrl';

const String _greetingDir = 'assets/images/greeting';

/// Time of day for the home greeting and its gull scene.
///
/// Every asset shares a 96 x 96 view box so the layers stack exactly.
enum GreetingTime {
  morning(
    message: 'Good morning!',
    skyAsset: '$_greetingDir/sun_morning.svg',
    sceneAsset: '$_greetingDir/scene_morning.svg',
  ),
  afternoon(
    message: 'Good afternoon!',
    skyAsset: '$_greetingDir/sun_afternoon.svg',
    sceneAsset: '$_greetingDir/scene_afternoon.svg',
  ),
  evening(
    message: 'Good evening!',
    skyAsset: '$_greetingDir/moon_evening.svg',
    sceneAsset: '$_greetingDir/scene_evening.svg',
    starsAsset: '$_greetingDir/stars_evening.svg',
  );

  const GreetingTime({
    required this.message,
    required this.skyAsset,
    required this.sceneAsset,
    this.starsAsset,
  });

  final String message;

  /// Sun or moon layer, animated on entrance.
  final String skyAsset;

  /// Static horizon, sea, and clouds.
  final String sceneAsset;

  /// Stars that fade in after the moon, if any.
  final String? starsAsset;

  static const String postAsset = '$_greetingDir/post.svg';
  static const String gullBodyAsset = '$_greetingDir/gull_body.svg';
  static const String gullWingAsset = '$_greetingDir/gull_wing.svg';

  /// Greeting for the hour of [time].
  static GreetingTime of(DateTime time) {
    if (time.hour < 12) {
      return GreetingTime.morning;
    } else if (time.hour < 18) {
      return GreetingTime.afternoon;
    }
    return GreetingTime.evening;
  }

  /// Every asset the scene for this time draws.
  List<String> get assets => [
        skyAsset,
        sceneAsset,
        if (starsAsset != null) starsAsset!,
        postAsset,
        gullBodyAsset,
        gullWingAsset,
      ];
}

String get emptyDirIcon {
  return 'assets/images/sad-gull.svg';
}

void launchSegulArticleUrl() {
  launchUrl(Uri.parse(segulArticleUrl));
}

void launchSegulDocUrl() {
  String url = segulDocUrl;
  Uri uri = Uri.parse(url);
  launchUrl(uri);
}

/// Opens the feature guides on the SEGUL website.
void launchSegulFeaturesUrl() {
  launchUrl(Uri.parse('${segulDocUrl}docs/features/'));
}

class SegulVersion {
  SegulVersion({
    required this.name,
    required this.version,
    required this.buildNumber,
    required this.apiVersion,
  });

  String name;
  String version;
  String buildNumber;
  String apiVersion;

  factory SegulVersion.empty() {
    return SegulVersion(
      name: '',
      version: '',
      buildNumber: '',
      apiVersion: '',
    );
  }

  Future<void> getVersions() async {
    PackageInfo guiPackageInfo = await PackageInfo.fromPlatform();
    String api = await getApiVersion();
    name = guiPackageInfo.appName;
    version = guiPackageInfo.version;
    buildNumber = guiPackageInfo.buildNumber;
    apiVersion = api;
  }
}
