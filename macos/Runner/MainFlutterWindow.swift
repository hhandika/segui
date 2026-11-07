import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    FolderAccessPlugin.register(
      with: flutterViewController.registrar(forPlugin: "FolderAccessPlugin"))

    super.awakeFromNib()
  }
}

/// Folders SEGUI may open again after a restart.
///
/// The sandbox grants access to a folder only while the app runs, after the user picks it. A
/// security-scoped bookmark of the folder keeps that access, so SEGUI asks once per folder.
/// Access to a folder covers everything inside it.
class FolderAccessPlugin: NSObject, FlutterPlugin {
  private static let storageKey = "segui.folderAccessBookmarks"

  /// Folders with active access, keyed by path.
  private var accessed: [String: URL] = [:]

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "segui/folder_access", binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(FolderAccessPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "restore":
      result(restore())
    case "list":
      result(storedBookmarks().keys.sorted())
    case "remember":
      let paths = args?["paths"] as? [String] ?? []
      result(paths.filter { remember(URL(fileURLWithPath: $0)) })
    case "grant":
      grant(initialPath: args?["initialPath"] as? String, result: result)
    case "forget":
      if let path = args?["path"] as? String {
        forget(path: path)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: Private

  /// Starts access to every saved folder and returns the folders that are still available.
  private func restore() -> [String] {
    var bookmarks = storedBookmarks()
    for (path, data) in bookmarks {
      var isStale = false
      guard
        let url = try? URL(
          resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil,
          bookmarkDataIsStale: &isStale)
      else {
        // The folder was deleted or moved somewhere SEGUI cannot follow.
        bookmarks.removeValue(forKey: path)
        continue
      }
      startAccess(url)
      if isStale || url.path != path {
        bookmarks.removeValue(forKey: path)
        if let fresh = bookmarkData(for: url) {
          bookmarks[url.path] = fresh
        }
      }
    }
    save(bookmarks)
    return bookmarks.keys.sorted()
  }

  /// Saves a bookmark for a folder the app can open now. Returns false for files and for folders
  /// the sandbox does not allow.
  private func remember(_ url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
      isDirectory.boolValue, let data = bookmarkData(for: url)
    else {
      return false
    }
    var bookmarks = storedBookmarks()
    bookmarks[url.path] = data
    save(bookmarks)
    startAccess(url)
    return true
  }

  private func grant(initialPath: String?, result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.canCreateDirectories = false
    panel.allowsMultipleSelection = false
    panel.prompt = "Allow"
    panel.message = "Choose a folder SEGUI can open without asking again."
    panel.directoryURL = URL(
      fileURLWithPath: initialPath ?? FileManager.default.homeDirectoryForCurrentUser.path)
    panel.begin { [weak self] response in
      guard response == .OK, let url = panel.url, let self = self else {
        result(nil)
        return
      }
      result(self.remember(url) ? url.path : nil)
    }
  }

  private func forget(path: String) {
    if let url = accessed.removeValue(forKey: path) {
      url.stopAccessingSecurityScopedResource()
    }
    var bookmarks = storedBookmarks()
    bookmarks.removeValue(forKey: path)
    save(bookmarks)
  }

  private func startAccess(_ url: URL) {
    guard accessed[url.path] == nil else { return }
    if url.startAccessingSecurityScopedResource() {
      accessed[url.path] = url
    }
  }

  private func bookmarkData(for url: URL) -> Data? {
    return try? url.bookmarkData(
      options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
  }

  private func storedBookmarks() -> [String: Data] {
    return UserDefaults.standard.dictionary(forKey: FolderAccessPlugin.storageKey)
      as? [String: Data] ?? [:]
  }

  private func save(_ bookmarks: [String: Data]) {
    UserDefaults.standard.set(bookmarks, forKey: FolderAccessPlugin.storageKey)
  }
}
