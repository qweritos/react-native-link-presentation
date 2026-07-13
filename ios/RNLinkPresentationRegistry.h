#import <Foundation/Foundation.h>
#import <LinkPresentation/LinkPresentation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RNLinkPresentationRegistry : NSObject

+ (instancetype)shared;

- (NSDictionary *)storeMetadata:(LPLinkMetadata *)metadata;
- (nullable LPLinkMetadata *)metadataForIdentifier:(NSString *)identifier;
- (nullable NSItemProvider *)itemProviderForIdentifier:(NSString *)identifier;
- (void)releaseMetadata:(NSString *)identifier;
- (void)removeAll;

@end

FOUNDATION_EXPORT NSURL *_Nullable RNLPURLFromString(id _Nullable value);
FOUNDATION_EXPORT NSString *RNLPErrorCode(NSError *error);
FOUNDATION_EXPORT NSError *RNLPBridgeError(NSString *code, NSString *message);

NS_ASSUME_NONNULL_END
