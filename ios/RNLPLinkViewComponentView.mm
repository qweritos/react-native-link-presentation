#ifdef RCT_NEW_ARCH_ENABLED

#import "RNLPLinkViewComponentView.h"
#import "RNLPLinkView.h"

#import <react/renderer/components/RNLinkPresentationSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNLinkPresentationSpec/Props.h>
#import <react/renderer/components/RNLinkPresentationSpec/RCTComponentViewHelpers.h>

using namespace facebook::react;

@interface RNLPLinkViewComponentView () <RCTRNLPLinkViewViewProtocol>
@end

@implementation RNLPLinkViewComponentView {
  RNLPLinkView *_linkView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNLPLinkViewComponentDescriptor>();
}

- (instancetype)init
{
  if ((self = [super init])) {
    static const auto defaultProps = std::make_shared<const RNLPLinkViewProps>();
    _props = defaultProps;
    _linkView = [RNLPLinkView new];
    self.contentView = _linkView;
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<const RNLPLinkViewProps>(_props);
  const auto &newViewProps = *std::static_pointer_cast<const RNLPLinkViewProps>(props);

  if (oldViewProps.url != newViewProps.url) {
    _linkView.url = newViewProps.url.empty() ? nil : [NSString stringWithUTF8String:newViewProps.url.c_str()];
  }
  if (oldViewProps.metadataNativeId != newViewProps.metadataNativeId) {
    _linkView.metadataNativeId = newViewProps.metadataNativeId.empty()
        ? nil
        : [NSString stringWithUTF8String:newViewProps.metadataNativeId.c_str()];
  }
  [super updateProps:props oldProps:oldProps];
}

@end

Class<RCTComponentViewProtocol> RNLPLinkViewCls(void)
{
  return RNLPLinkViewComponentView.class;
}

#endif
