#import <React/RCTViewManager.h>
#import "RNLPLinkView.h"

@interface RNLPLinkViewManager : RCTViewManager
@end

@implementation RNLPLinkViewManager

RCT_EXPORT_MODULE(RNLPLinkView)

+ (BOOL)requiresMainQueueSetup { return YES; }

- (UIView *)view { return [RNLPLinkView new]; }

RCT_EXPORT_VIEW_PROPERTY(url, NSString)
RCT_EXPORT_VIEW_PROPERTY(metadataNativeId, NSString)

@end
