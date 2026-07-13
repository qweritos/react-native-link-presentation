#import "RNLinkPresentation.h"
#import "RNLinkPresentationRegistry.h"
#import "react_native_link_presentation-Swift.h"

@interface RNLinkPresentation ()
@property(nonatomic) NSMutableDictionary<NSString *, id<RNLPMetadataProviding>> *activeProviders;
@property(nonatomic) NSMutableSet<NSString *> *usedProviderIds;
@property(nonatomic, copy) RNLPMetadataProviderFactory providerFactory;
@property(nonatomic) RNLPLinkPresentationCore *core;
@end

@implementation RNLinkPresentation

RCT_EXPORT_MODULE(RNLinkPresentation)

+ (BOOL)requiresMainQueueSetup { return NO; }

- (instancetype)init
{
  return [self initWithProviderFactory:^id<RNLPMetadataProviding> {
    return (id<RNLPMetadataProviding>)[LPMetadataProvider new];
  }];
}

- (instancetype)initWithProviderFactory:(RNLPMetadataProviderFactory)providerFactory
{
  if ((self = [super init])) {
    _activeProviders = [NSMutableDictionary new];
    _usedProviderIds = [NSMutableSet new];
    _providerFactory = [providerFactory copy];
    _core = [RNLPLinkPresentationCore new];
  }
  return self;
}

- (void)reject:(RCTPromiseRejectBlock)reject error:(NSError *)error
{
  NSString *bridgeCode = error.userInfo[@"bridgeCode"];
  reject(bridgeCode ?: RNLPErrorCode(error), error.localizedDescription, error);
}

- (NSURLRequestCachePolicy)cachePolicy:(NSString *)value
{
  if ([value isEqualToString:@"reloadIgnoringLocalCacheData"]) return NSURLRequestReloadIgnoringLocalCacheData;
  if ([value isEqualToString:@"reloadIgnoringLocalAndRemoteCacheData"]) return NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
  if ([value isEqualToString:@"returnCacheDataElseLoad"]) return NSURLRequestReturnCacheDataElseLoad;
  if ([value isEqualToString:@"returnCacheDataDontLoad"]) return NSURLRequestReturnCacheDataDontLoad;
  if ([value isEqualToString:@"reloadRevalidatingCacheData"]) return NSURLRequestReloadRevalidatingCacheData;
  return NSURLRequestUseProtocolCachePolicy;
}

- (NSMutableURLRequest *)requestFromDictionary:(NSDictionary *)dictionary error:(NSError **)error
{
  NSURL *URL = RNLPURLFromString(dictionary[@"url"]);
  if (!URL) {
    *error = RNLPBridgeError(@"E_INVALID_URL", @"Expected an absolute URL with a scheme");
    return nil;
  }
  NSTimeInterval timeout = [dictionary[@"timeoutInterval"] doubleValue];
  NSMutableURLRequest *request = [NSMutableURLRequest
      requestWithURL:URL
         cachePolicy:[self cachePolicy:dictionary[@"cachePolicy"]]
     timeoutInterval:timeout > 0 ? timeout : 60];
  if ([dictionary[@"method"] isKindOfClass:NSString.class]) request.HTTPMethod = dictionary[@"method"];
  if ([dictionary[@"headers"] isKindOfClass:NSDictionary.class]) {
    for (NSString *key in dictionary[@"headers"]) {
      id value = dictionary[@"headers"][key];
      if ([key isKindOfClass:NSString.class] && [value isKindOfClass:NSString.class]) {
        [request setValue:value forHTTPHeaderField:key];
      }
    }
  }
  if ([dictionary[@"bodyBase64"] isKindOfClass:NSString.class]) {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:dictionary[@"bodyBase64"] options:0];
    if (!data) {
      *error = RNLPBridgeError(@"E_INVALID_REQUEST", @"bodyBase64 is not valid base64");
      return nil;
    }
    request.HTTPBody = data;
  }
  if (dictionary[@"allowsCellularAccess"] != nil) request.allowsCellularAccess = [dictionary[@"allowsCellularAccess"] boolValue];
  if (dictionary[@"allowsExpensiveNetworkAccess"] != nil) request.allowsExpensiveNetworkAccess = [dictionary[@"allowsExpensiveNetworkAccess"] boolValue];
  if (dictionary[@"allowsConstrainedNetworkAccess"] != nil) request.allowsConstrainedNetworkAccess = [dictionary[@"allowsConstrainedNetworkAccess"] boolValue];
  return request;
}

RCT_EXPORT_METHOD(startFetchingMetadata:(NSString *)providerId
                  request:(NSDictionary *)request
                  timeout:(double)timeout
                  shouldFetchSubresources:(BOOL)shouldFetchSubresources
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  @synchronized(self) {
    if ([self.usedProviderIds containsObject:providerId]) {
      [self reject:reject error:RNLPBridgeError(@"E_PROVIDER_ALREADY_STARTED", @"LPMetadataProvider instances are single-use")];
      return;
    }
    [self.usedProviderIds addObject:providerId];
  }

  NSError *requestError;
  NSMutableURLRequest *URLRequest = [self requestFromDictionary:request error:&requestError];
  if (!URLRequest) {
    [self reject:reject error:requestError];
    return;
  }

  id<RNLPMetadataProviding> provider = self.providerFactory();
  provider.timeout = timeout > 0 ? timeout : 30;
  provider.shouldFetchSubresources = shouldFetchSubresources;
  @synchronized(self) { self.activeProviders[providerId] = provider; }

  __weak __typeof(self) weakSelf = self;
  __block BOOL settled = NO;
  void (^completion)(LPLinkMetadata *, NSError *) = ^(LPLinkMetadata *metadata, NSError *error) {
    @synchronized(provider) {
      if (settled) return;
      settled = YES;
    }
    __typeof(self) strongSelf = weakSelf;
    if (!strongSelf) return;
    @synchronized(strongSelf) { [strongSelf.activeProviders removeObjectForKey:providerId]; }
    if (error) {
      [strongSelf reject:reject error:error];
    } else if (!metadata) {
      [strongSelf reject:reject error:RNLPBridgeError(@"LPErrorMetadataFetchFailed", @"The system returned no link metadata")];
    } else {
      resolve([[RNLinkPresentationRegistry shared] storeMetadata:metadata]);
    }
  };
  if ([request[@"__useURLAPI"] boolValue]) {
    [provider startFetchingMetadataForURL:URLRequest.URL completionHandler:completion];
  } else {
    [provider startFetchingMetadataForRequest:URLRequest completionHandler:completion];
  }
}

RCT_EXPORT_METHOD(cancel:(NSString *)providerId)
{
  id<RNLPMetadataProviding> provider;
  @synchronized(self) { provider = self.activeProviders[providerId]; }
  [provider cancel];
}

RCT_EXPORT_METHOD(createLinkMetadata:(NSDictionary *)input
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [self.core createLinkMetadata:input resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(updateLinkMetadata:(NSString *)nativeId
                  patch:(NSDictionary *)patch
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [self.core updateLinkMetadata:nativeId patch:patch resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(loadItemProvider:(NSString *)nativeId
                  typeIdentifier:(NSString *)typeIdentifier
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [self.core loadItemProvider:nativeId typeIdentifier:typeIdentifier resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(releaseLinkMetadata:(NSString *)nativeId)
{
  [self.core releaseLinkMetadata:nativeId];
}

- (void)invalidate
{
  NSArray<id<RNLPMetadataProviding>> *providers;
  @synchronized(self) {
    providers = self.activeProviders.allValues;
    [self.activeProviders removeAllObjects];
  }
  for (id<RNLPMetadataProviding> provider in providers) [provider cancel];
  [self.core invalidate];
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeRNLinkPresentationSpecJSI>(params);
}
#endif

@end
