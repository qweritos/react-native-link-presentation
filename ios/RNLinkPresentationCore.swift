import Foundation
import LinkPresentation
import React
import UniformTypeIdentifiers

@objc(RNLPLinkPresentationCore)
public final class RNLPLinkPresentationCore: NSObject {
  private var activeLoads: [String: Progress] = [:]

  @objc public override init() {
    super.init()
  }

  @objc(createLinkMetadata:resolve:reject:)
  public func createLinkMetadata(
    _ input: NSDictionary,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    let metadata = LPLinkMetadata()
    do {
      try apply(input, to: metadata)
      resolve(RNLinkPresentationRegistry.shared.store(metadata))
    } catch {
      rejectError(error, reject: reject)
    }
  }

  @objc(updateLinkMetadata:patch:resolve:reject:)
  public func updateLinkMetadata(
    _ nativeID: String,
    patch: NSDictionary,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    guard
      let stored = RNLinkPresentationRegistry.shared.metadata(for: nativeID),
      let metadata = stored.copy() as? LPLinkMetadata
    else {
      rejectBridge("E_METADATA_RELEASED", "The metadata handle is no longer available", reject)
      return
    }

    do {
      try apply(patch, to: metadata)
      resolve(RNLinkPresentationRegistry.shared.store(metadata))
    } catch {
      rejectError(error, reject: reject)
    }
  }

  @objc(loadItemProvider:typeIdentifier:resolve:reject:)
  public func loadItemProvider(
    _ nativeID: String,
    typeIdentifier requestedType: String?,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    guard let provider = RNLinkPresentationRegistry.shared.itemProvider(for: nativeID) else {
      rejectBridge("E_ITEM_PROVIDER_RELEASED", "The item provider handle is no longer available", reject)
      return
    }
    guard
      let type = requestedType?.isEmpty == false ? requestedType : provider.registeredTypeIdentifiers.first,
      provider.hasItemConformingToTypeIdentifier(type)
    else {
      rejectBridge("E_ITEM_PROVIDER_TYPE", "The requested type is not registered by this provider", reject)
      return
    }

    let loadID = UUID().uuidString
    let progress = provider.loadFileRepresentation(forTypeIdentifier: type) { [weak self] source, error in
      guard let self else { return }
      synchronized { self.activeLoads.removeValue(forKey: loadID) }
      guard let source else {
        rejectError(
          error ?? bridgeError("E_ITEM_PROVIDER_LOAD_FAILED", "The item provider returned no file"),
          reject: reject
        )
        return
      }

      do {
        let destination = try destination(for: provider, type: type, source: source)
        try FileManager.default.copyItem(at: source, to: destination)
        resolve(["fileURL": destination.absoluteString, "typeIdentifier": type])
      } catch {
        rejectError(error, reject: reject)
      }
    }
    synchronized { activeLoads[loadID] = progress }
  }

  @objc(releaseLinkMetadata:)
  public func releaseLinkMetadata(_ nativeID: String) {
    RNLinkPresentationRegistry.shared.releaseMetadata(nativeID)
  }

  @objc public func invalidate() {
    let loads = synchronized { () -> [Progress] in
      let values = Array(activeLoads.values)
      activeLoads.removeAll()
      return values
    }
    loads.forEach { $0.cancel() }
    RNLinkPresentationRegistry.shared.removeAll()
    try? FileManager.default.removeItem(at: cacheDirectory)
  }

  private func apply(_ input: NSDictionary, to metadata: LPLinkMetadata) throws {
    if let value = input["originalURL"] {
      metadata.originalURL = try optionalURL(value, key: "originalURL")
    }
    if let value = input["url"] {
      metadata.url = try optionalURL(value, key: "url")
    }
    if let value = input["remoteVideoURL"] {
      metadata.remoteVideoURL = try optionalURL(value, key: "remoteVideoURL")
    }
    if let value = input["title"] {
      guard value is NSNull || value is String else {
        throw bridgeError("E_INVALID_METADATA", "title must be a string or null")
      }
      metadata.title = value is NSNull ? nil : value as? String
    }
    if let value = input["iconProvider"] {
      metadata.iconProvider = try optionalProvider(value)
    }
    if let value = input["imageProvider"] {
      metadata.imageProvider = try optionalProvider(value)
    }
    if let value = input["videoProvider"] {
      metadata.videoProvider = try optionalProvider(value)
    }
  }

  private func optionalURL(_ value: Any, key: String) throws -> URL? {
    if value is NSNull { return nil }
    guard let string = value as? String, let url = RNLPURLFromString(string) else {
      throw bridgeError("E_INVALID_URL", "\(key) must be an absolute URL")
    }
    return url
  }

  private func optionalProvider(_ value: Any) throws -> NSItemProvider? {
    if value is NSNull { return nil }
    guard
      let input = value as? NSDictionary,
      let string = input["fileURL"] as? String,
      let fileURL = RNLPURLFromString(string),
      fileURL.isFileURL
    else {
      throw bridgeError("E_INVALID_ITEM_PROVIDER", "Item providers require a file URL")
    }

    let type = (input["typeIdentifier"] as? String)
      ?? UTType(filenameExtension: fileURL.pathExtension)?.identifier
      ?? UTType.data.identifier
    let provider = NSItemProvider()
    provider.registerFileRepresentation(
      forTypeIdentifier: type,
      fileOptions: [],
      visibility: .all
    ) { completion in
      completion(fileURL, false, nil)
      return nil
    }
    provider.suggestedName = fileURL.lastPathComponent
    return provider
  }

  private func destination(
    for provider: NSItemProvider,
    type: String,
    source: URL
  ) throws -> URL {
    try FileManager.default.createDirectory(
      at: cacheDirectory,
      withIntermediateDirectories: true
    )
    let directory = cacheDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    var name = provider.suggestedName ?? source.lastPathComponent
    if name.isEmpty {
      let ext = UTType(type)?.preferredFilenameExtension
      name = ext.map { "item.\($0)" } ?? "item"
    }
    return directory.appendingPathComponent((name as NSString).lastPathComponent)
  }

  private var cacheDirectory: URL {
    FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("RNLinkPresentation", isDirectory: true)
  }

  private func rejectBridge(
    _ code: String,
    _ message: String,
    _ reject: RCTPromiseRejectBlock
  ) {
    rejectError(bridgeError(code, message), reject: reject)
  }

  private func rejectError(_ error: Error, reject: RCTPromiseRejectBlock) {
    let value = error as NSError
    let bridgeCode = value.userInfo["bridgeCode"] as? String
    reject(bridgeCode ?? RNLPErrorCode(value), value.localizedDescription, value)
  }

  private func bridgeError(_ code: String, _ message: String) -> NSError {
    RNLPBridgeError(code, message) as NSError
  }

  @discardableResult
  private func synchronized<T>(_ body: () -> T) -> T {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }
    return body()
  }
}
