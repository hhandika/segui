import UIKit
import Flutter
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MobileIoPlugin") {
      MobileIoPlugin.register(with: registrar)
    }
  }
}

/// Folder picking and shared files for SEGUI on iOS.
///
/// A picked folder opens in place with security-scoped access, so nothing is copied and Rust
/// reads the files by path. Access lasts until Dart releases the folders. Files opened in or
/// shared to SEGUI wait until Dart takes them, and are copied into the folder Dart chooses.
class MobileIoPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  FlutterSceneLifeCycleDelegate, UIDocumentPickerDelegate
{
  private var channel: FlutterMethodChannel?
  private var pendingResult: FlutterResult?
  private var accessedFolders: [URL] = []
  private var pendingShared: [URL] = []

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MobileIoPlugin()
    let channel = FlutterMethodChannel(
      name: "segui/mobile_io", binaryMessenger: registrar.messenger())
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    // iOS opens folders in place, so it never reports copy progress.
    FlutterEventChannel(
      name: "segui/mobile_io/progress", binaryMessenger: registrar.messenger()
    ).setStreamHandler(instance)
    registrar.addSceneDelegate(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickFolder":
      pickFolder(result: result)
    case "cancelCopy":
      result(nil)
    case "releaseFolders":
      releaseFolders()
      result(nil)
    case "pendingSharedCount":
      result(pendingShared.count)
    case "takeSharedFiles":
      let args = call.arguments as? [String: Any]
      guard let destination = args?["destination"] as? String else {
        result(FlutterError(code: "bad_args", message: "Missing destination folder", details: nil))
        return
      }
      takeSharedFiles(destination: URL(fileURLWithPath: destination), result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }

  // MARK: Scene life cycle

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let contexts = connectionOptions?.urlContexts, !contexts.isEmpty else {
      return false
    }
    queueShared(contexts.map { $0.url })
    return true
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    let urls = URLContexts.map { $0.url }.filter { $0.isFileURL }
    if urls.isEmpty {
      return false
    }
    queueShared(urls)
    return true
  }

  // MARK: Document picker

  func documentPicker(
    _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
  ) {
    guard let result = pendingResult else { return }
    pendingResult = nil
    guard let folder = urls.first else {
      result(nil)
      return
    }
    if folder.startAccessingSecurityScopedResource() {
      accessedFolders.append(folder)
    }
    result(folder.path)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingResult?(nil)
    pendingResult = nil
  }

  // MARK: Private

  private func pickFolder(result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "busy", message: "A folder picker is already open", details: nil))
      return
    }
    guard let presenter = topViewController() else {
      result(FlutterError(code: "no_view", message: "No view to show the picker", details: nil))
      return
    }
    pendingResult = result
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.delegate = self
    picker.allowsMultipleSelection = false
    presenter.present(picker, animated: true)
  }

  private func releaseFolders() {
    for folder in accessedFolders {
      folder.stopAccessingSecurityScopedResource()
    }
    accessedFolders.removeAll()
  }

  private func queueShared(_ urls: [URL]) {
    for url in urls where !pendingShared.contains(url) {
      pendingShared.append(url)
    }
    channel?.invokeMethod("sharedFilesAvailable", arguments: pendingShared.count)
  }

  private func takeSharedFiles(destination: URL, result: @escaping FlutterResult) {
    let urls = pendingShared
    pendingShared.removeAll()
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let manager = FileManager.default
        try manager.createDirectory(at: destination, withIntermediateDirectories: true)
        var paths: [String] = []
        var usedNames = Set<String>()
        for url in urls {
          let scoped = url.startAccessingSecurityScopedResource()
          defer {
            if scoped { url.stopAccessingSecurityScopedResource() }
          }
          var name = url.lastPathComponent
          var index = 1
          while usedNames.contains(name) {
            name = "\(index)_\(url.lastPathComponent)"
            index += 1
          }
          usedNames.insert(name)
          let target = destination.appendingPathComponent(name)
          try manager.copyItem(at: url, to: target)
          // The system copies opened files into Documents/Inbox; that copy is no longer needed.
          if url.path.contains("/Documents/Inbox/") {
            try? manager.removeItem(at: url)
          }
          paths.append(target.path)
        }
        DispatchQueue.main.async { result(paths) }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "shared_copy_failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}
