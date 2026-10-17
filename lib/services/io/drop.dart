import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/types.dart';

/// Whether files can be dropped onto the app. Only desktop apps get drops.
bool get isFileDropSupported => runningPlatform == PlatformType.isDesktop;

/// Paths of [items] dropped onto the app.
///
/// On macOS, the sandbox needs security-scoped access to read files dropped
/// from outside the app. Access is kept for the session because tools read
/// the files after the drop.
Future<List<String>> openDroppedItems(List<DropItem> items) async {
  if (Platform.isMacOS) {
    for (final DropItem item in items) {
      final bookmark = item.extraAppleBookmark;
      if (bookmark != null && bookmark.isNotEmpty) {
        await DesktopDrop.instance
            .startAccessingSecurityScopedResource(bookmark: bookmark);
      }
    }
  }
  return items.map((e) => e.path).toList();
}
