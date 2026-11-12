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

/// Folder and file picking and shared files for SEGUI on iOS.
///
/// A picked folder opens in place with security-scoped access, so nothing is copied and Rust
/// reads the files by path. Access lasts until Dart releases the folders. Picked files, and files
/// opened in or shared to SEGUI, are copied into the folder Dart chooses with progress events.
class MobileIoPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  FlutterSceneLifeCycleDelegate, UIDocumentPickerDelegate
{
  /// What the open document picker is for.
  private enum PickRequest {
    case folder(FlutterResult)
    case files(FlutterResult, destination: URL)
  }

  private static let bufferSize = 1024 * 1024

  private var channel: FlutterMethodChannel?
  private var pendingPick: PickRequest?
  private var accessedFolders: [URL] = []
  private var pendingShared: [URL] = []
  private var eventSink: FlutterEventSink?
  private let cancelFlag = CancelFlag()

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MobileIoPlugin()
    let channel = FlutterMethodChannel(
      name: "segui/mobile_io", binaryMessenger: registrar.messenger())
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    // Folders open in place; picked and shared files report copy progress.
    FlutterEventChannel(
      name: "segui/mobile_io/progress", binaryMessenger: registrar.messenger()
    ).setStreamHandler(instance)
    registrar.addSceneDelegate(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickFolder":
      pickFolder(result: result)
    case "pickFiles":
      let args = call.arguments as? [String: Any]
      guard let destination = args?["destination"] as? String else {
        result(FlutterError(code: "bad_args", message: "Missing destination folder", details: nil))
        return
      }
      pickFiles(
        multiple: args?["multiple"] as? Bool ?? true,
        typeIdentifiers: args?["typeIdentifiers"] as? [String] ?? [],
        extensions: args?["extensions"] as? [String] ?? [],
        destination: URL(fileURLWithPath: destination),
        result: result)
    case "cancelCopy":
      cancelFlag.set(true)
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
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
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
    guard let request = pendingPick else { return }
    pendingPick = nil
    switch request {
    case .folder(let result):
      guard let folder = urls.first else {
        result(nil)
        return
      }
      if folder.startAccessingSecurityScopedResource() {
        accessedFolders.append(folder)
      }
      result(folder.path)
    case .files(let result, let destination):
      if urls.isEmpty {
        result(nil)
        return
      }
      copyFiles(urls, to: destination) { outcome in
        switch outcome {
        case .success(let paths):
          result(["paths": paths, "skipped": 0])
        case .failure(let error):
          result(
            FlutterError(
              code: "file_copy_failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    switch pendingPick {
    case .folder(let result), .files(let result, _):
      result(nil)
    case nil:
      break
    }
    pendingPick = nil
  }

  // MARK: Private

  private func pickFolder(result: @escaping FlutterResult) {
    presentPicker(types: [.folder], multiple: false, request: .folder(result), result: result)
  }

  /// Opens the picked files in place, without the system copy, so SEGUI copies them itself and
  /// reports progress.
  private func pickFiles(
    multiple: Bool, typeIdentifiers: [String], extensions: [String], destination: URL,
    result: @escaping FlutterResult
  ) {
    var types = typeIdentifiers.compactMap { UTType($0) }
    if types.isEmpty {
      types = extensions.compactMap { UTType(filenameExtension: $0) }
    }
    if types.isEmpty {
      types = [.item]
    }
    presentPicker(
      types: types, multiple: multiple, request: .files(result, destination: destination),
      result: result)
  }

  private func presentPicker(
    types: [UTType], multiple: Bool, request: PickRequest, result: @escaping FlutterResult
  ) {
    guard pendingPick == nil else {
      result(FlutterError(code: "busy", message: "A picker is already open", details: nil))
      return
    }
    guard let presenter = topViewController() else {
      result(FlutterError(code: "no_view", message: "No view to show the picker", details: nil))
      return
    }
    pendingPick = request
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: false)
    picker.delegate = self
    picker.allowsMultipleSelection = multiple
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
    copyFiles(urls, to: destination) { outcome in
      switch outcome {
      case .success(let paths):
        result(paths)
      case .failure(let error):
        result(
          FlutterError(
            code: "shared_copy_failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  /// Copies [urls] into [destination] on a background queue with progress events, and calls
  /// [completion] on the main queue with the copied paths. A cancelled copy keeps the files
  /// finished so far.
  private func copyFiles(
    _ urls: [URL], to destination: URL,
    completion: @escaping (Result<[String], Error>) -> Void
  ) {
    cancelFlag.set(false)
    sendEvent(["copied": 0, "total": 0])
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let manager = FileManager.default
        try manager.createDirectory(at: destination, withIntermediateDirectories: true)
        let sizes = urls.map { MobileIoPlugin.fileSize(of: $0) }
        let totalBytes: Int64 = sizes.contains(nil) ? 0 : sizes.reduce(0) { $0 + ($1 ?? 0) }
        let progress = CopyProgress(totalFiles: urls.count, totalBytes: totalBytes) {
          [weak self] event in
          self?.sendEvent(event)
        }
        var paths: [String] = []
        var usedNames = Set<String>()
        for url in urls {
          var name = url.lastPathComponent
          var index = 1
          while usedNames.contains(name) {
            name = "\(index)_\(url.lastPathComponent)"
            index += 1
          }
          usedNames.insert(name)
          let target = destination.appendingPathComponent(name)
          guard try self.copyFile(from: url, to: target, progress: progress) else {
            break
          }
          progress.fileDone()
          // The system copies opened files into Documents/Inbox; that copy is no longer needed.
          if url.path.contains("/Documents/Inbox/") {
            try? manager.removeItem(at: url)
          }
          paths.append(target.path)
        }
        DispatchQueue.main.async { completion(.success(paths)) }
      } catch {
        DispatchQueue.main.async { completion(.failure(error)) }
      }
    }
  }

  /// Copies one file in chunks, counting bytes in [progress]. Returns false when the copy was
  /// cancelled, after deleting the partial file.
  private func copyFile(from source: URL, to target: URL, progress: CopyProgress) throws -> Bool {
    if cancelFlag.get() {
      return false
    }
    let scoped = source.startAccessingSecurityScopedResource()
    defer {
      if scoped { source.stopAccessingSecurityScopedResource() }
    }
    let manager = FileManager.default
    if manager.fileExists(atPath: target.path) {
      try manager.removeItem(at: target)
    }
    guard manager.createFile(atPath: target.path, contents: nil) else {
      throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: target.path])
    }
    let reader = try FileHandle(forReadingFrom: source)
    defer { try? reader.close() }
    let writer = try FileHandle(forWritingTo: target)
    defer { try? writer.close() }
    while true {
      if cancelFlag.get() {
        try? writer.close()
        try? manager.removeItem(at: target)
        return false
      }
      let chunk = try autoreleasepool { try reader.read(upToCount: MobileIoPlugin.bufferSize) }
      guard let chunk, !chunk.isEmpty else {
        break
      }
      try writer.write(contentsOf: chunk)
      progress.addBytes(Int64(chunk.count))
    }
    return true
  }

  private func sendEvent(_ event: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(event)
    }
  }

  private static func fileSize(of url: URL) -> Int64? {
    let scoped = url.startAccessingSecurityScopedResource()
    defer {
      if scoped { url.stopAccessingSecurityScopedResource() }
    }
    guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
      return nil
    }
    return Int64(size)
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

/// A flag shared between the main queue, which cancels, and the copy queue, which checks it.
private final class CancelFlag {
  private let lock = NSLock()
  private var value = false

  func get() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return value
  }

  func set(_ newValue: Bool) {
    lock.lock()
    value = newValue
    lock.unlock()
  }
}

/// Counts copied files and bytes and sends progress events, at most one per interval except the
/// first and the last. A total size of zero means some sizes are unknown, so Dart follows the
/// file count. Used from one copy queue at a time.
private final class CopyProgress {
  private let totalFiles: Int
  private let totalBytes: Int64
  private let send: ([String: Any]) -> Void
  private var files = 0
  private var bytes: Int64 = 0
  private var lastSent = Date.distantPast

  init(totalFiles: Int, totalBytes: Int64, send: @escaping ([String: Any]) -> Void) {
    self.totalFiles = totalFiles
    self.totalBytes = totalBytes
    self.send = send
    emit(force: true)
  }

  func addBytes(_ count: Int64) {
    bytes += count
    emit(force: false)
  }

  func fileDone() {
    files += 1
    emit(force: files == totalFiles)
  }

  private func emit(force: Bool) {
    let now = Date()
    if !force && now.timeIntervalSince(lastSent) < 0.1 {
      return
    }
    lastSent = now
    send([
      "copied": files, "total": totalFiles, "bytesCopied": bytes, "bytesTotal": totalBytes,
    ])
  }
}
