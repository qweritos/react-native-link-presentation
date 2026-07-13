#import <React/RCTBridgeModule.h>
#import <React/RCTInvalidating.h>
#import <LinkPresentation/LinkPresentation.h>

@protocol RNLPMetadataProviding <NSObject>
@property(nonatomic) NSTimeInterval timeout;
@property(nonatomic) BOOL shouldFetchSubresources;
- (void)startFetchingMetadataForURL:(NSURL *)URL completionHandler:(void (^)(LPLinkMetadata *_Nullable, NSError *_Nullable))completionHandler;
- (void)startFetchingMetadataForRequest:(NSURLRequest *)request completionHandler:(void (^)(LPLinkMetadata *_Nullable, NSError *_Nullable))completionHandler;
- (void)cancel;
@end

typedef id<RNLPMetadataProviding> _Nonnull (^RNLPMetadataProviderFactory)(void);

#ifdef RCT_NEW_ARCH_ENABLED
#import <RNLinkPresentationSpec/RNLinkPresentationSpec.h>
@interface RNLinkPresentation : NSObject <NativeRNLinkPresentationSpec, RCTInvalidating>
#else
@interface RNLinkPresentation : NSObject <RCTBridgeModule, RCTInvalidating>
#endif
- (instancetype)initWithProviderFactory:(RNLPMetadataProviderFactory)providerFactory;
@end
