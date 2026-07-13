import Foundation
import LinkPresentation

@objc(RNLinkPresentationRegistry)
final class RNLinkPresentationRegistry: NSObject {
  @objc static let shared = RNLinkPresentationRegistry()

  private var metadata: [String: LPLinkMetadata] = [:]
  private var providers: [String: NSItemProvider] = [:]
  private var metadataProviders: [String: Set<String>] = [:]

  @objc(storeMetadata:)
  func store(_ value: LPLinkMetadata) -> NSDictionary {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

    let identifier = UUID().uuidString
    var providerIDs = Set<String>()
    var result: [String: Any] = ["nativeId": identifier]

    result["originalURL"] = value.originalURL?.absoluteString
    result["url"] = value.url?.absoluteString
    result["title"] = value.title
    result["remoteVideoURL"] = value.remoteVideoURL?.absoluteString
    result["iconProvider"] = storeProvider(value.iconProvider, owner: &providerIDs)
    result["imageProvider"] = storeProvider(value.imageProvider, owner: &providerIDs)
    result["videoProvider"] = storeProvider(value.videoProvider, owner: &providerIDs)

    metadata[identifier] = value
    metadataProviders[identifier] = providerIDs
    return result as NSDictionary
  }

  @objc(metadataForIdentifier:)
  func metadata(for identifier: String) -> LPLinkMetadata? {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }
    return metadata[identifier]
  }

  @objc(itemProviderForIdentifier:)
  func itemProvider(for identifier: String) -> NSItemProvider? {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }
    return providers[identifier]
  }

  @objc(releaseMetadata:)
  func releaseMetadata(_ identifier: String) {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }
    metadataProviders.removeValue(forKey: identifier)?.forEach {
      providers.removeValue(forKey: $0)
    }
    metadata.removeValue(forKey: identifier)
  }

  @objc func removeAll() {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }
    metadata.removeAll()
    providers.removeAll()
    metadataProviders.removeAll()
  }

  private func storeProvider(
    _ provider: NSItemProvider?,
    owner: inout Set<String>
  ) -> NSDictionary? {
    guard let provider else { return nil }
    let identifier = UUID().uuidString
    providers[identifier] = provider
    owner.insert(identifier)
    return [
      "nativeId": identifier,
      "registeredTypeIdentifiers": provider.registeredTypeIdentifiers,
    ] as NSDictionary
  }
}
