import LinkPresentation
import UIKit

@objc(RNLPLinkView)
final class RNLPLinkView: UIView {
  @objc var url: String? {
    didSet {
      guard url != oldValue else { return }
      guard let url, let value = RNLPURLFromString(url) else {
        install(nil)
        return
      }
      install(LPLinkView(url: value))
    }
  }

  @objc var metadataNativeId: String? {
    didSet {
      guard metadataNativeId != oldValue else { return }
      guard
        let metadataNativeId,
        let metadata = RNLinkPresentationRegistry.shared.metadata(for: metadataNativeId)
      else {
        install(nil)
        return
      }
      install(LPLinkView(metadata: metadata))
    }
  }

  private var linkView: LPLinkView?

  override func layoutSubviews() {
    super.layoutSubviews()
    linkView?.frame = bounds
  }

  override var intrinsicContentSize: CGSize {
    guard let linkView else { return .zero }
    guard bounds.width > 0 else { return linkView.intrinsicContentSize }
    return linkView.sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    linkView?.sizeThatFits(size) ?? .zero
  }

  private func install(_ value: LPLinkView?) {
    linkView?.removeFromSuperview()
    linkView = value
    if let value { addSubview(value) }
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }
}
