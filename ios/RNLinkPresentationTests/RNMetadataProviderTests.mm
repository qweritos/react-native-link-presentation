#import <XCTest/XCTest.h>
#import "RNLinkPresentation.h"

@interface RNLinkPresentation (Tests)
- (void)startFetchingMetadata:(NSString *)providerId
                      request:(NSDictionary *)request
                      timeout:(double)timeout
      shouldFetchSubresources:(BOOL)shouldFetchSubresources
                      resolve:(RCTPromiseResolveBlock)resolve
                       reject:(RCTPromiseRejectBlock)reject;
- (void)cancel:(NSString *)providerId;
@end

@interface RNLPFakeProvider : NSObject <RNLPMetadataProviding>
@property(nonatomic) NSTimeInterval timeout;
@property(nonatomic) BOOL shouldFetchSubresources;
@property(nonatomic) BOOL cancelled;
@property(nonatomic) NSURL *URL;
@property(nonatomic) NSURLRequest *request;
@property(nonatomic, copy) void (^completion)(LPLinkMetadata *, NSError *);
@end

@implementation RNLPFakeProvider
- (void)startFetchingMetadataForURL:(NSURL *)URL completionHandler:(void (^)(LPLinkMetadata *, NSError *))completionHandler
{
  self.URL = URL;
  self.completion = completionHandler;
}
- (void)startFetchingMetadataForRequest:(NSURLRequest *)request completionHandler:(void (^)(LPLinkMetadata *, NSError *))completionHandler
{
  self.request = request;
  self.completion = completionHandler;
}
- (void)cancel { self.cancelled = YES; }
@end

@interface RNMetadataProviderTests : XCTestCase
@end

@implementation RNMetadataProviderTests

- (RNLinkPresentation *)moduleWithFake:(RNLPFakeProvider **)fake
{
  RNLPFakeProvider *provider = [RNLPFakeProvider new];
  *fake = provider;
  return [[RNLinkPresentation alloc] initWithProviderFactory:^id<RNLPMetadataProviding> { return provider; }];
}

- (void)testURLFetchForwardsProviderConfigurationAndRedirectedMetadata
{
  RNLPFakeProvider *fake;
  RNLinkPresentation *module = [self moduleWithFake:&fake];
  __block NSDictionary *result;
  [module startFetchingMetadata:@"provider"
                        request:@{ @"url" : @"https://example.com", @"__useURLAPI" : @YES }
                        timeout:7
        shouldFetchSubresources:NO
                        resolve:^(id value) { result = value; }
                         reject:^(NSString *code, NSString *message, NSError *error) { XCTFail(@"Unexpected rejection: %@", code); }];

  XCTAssertEqualObjects(fake.URL.absoluteString, @"https://example.com");
  XCTAssertEqual(fake.timeout, 7);
  XCTAssertFalse(fake.shouldFetchSubresources);
  LPLinkMetadata *metadata = [LPLinkMetadata new];
  metadata.originalURL = fake.URL;
  metadata.URL = [NSURL URLWithString:@"https://www.example.com/redirected"];
  metadata.title = @"Title";
  fake.completion(metadata, nil);
  XCTAssertEqualObjects(result[@"url"], @"https://www.example.com/redirected");
}

- (void)testRequestOverloadForwardsRequestFields
{
  RNLPFakeProvider *fake;
  RNLinkPresentation *module = [self moduleWithFake:&fake];
  [module startFetchingMetadata:@"provider"
                        request:@{ @"url" : @"https://example.com", @"method" : @"POST", @"headers" : @{ @"X-Test" : @"yes" }, @"bodyBase64" : @"aGk=" }
                        timeout:30
        shouldFetchSubresources:YES
                        resolve:^(__unused id value) {}
                         reject:^(__unused NSString *code, __unused NSString *message, __unused NSError *error) {}];
  XCTAssertEqualObjects(fake.request.HTTPMethod, @"POST");
  XCTAssertEqualObjects([fake.request valueForHTTPHeaderField:@"X-Test"], @"yes");
  XCTAssertEqualObjects([[NSString alloc] initWithData:fake.request.HTTPBody encoding:NSUTF8StringEncoding], @"hi");
}

- (void)testCancellationAndErrorMappingSettleExactlyOnce
{
  RNLPFakeProvider *fake;
  RNLinkPresentation *module = [self moduleWithFake:&fake];
  __block NSUInteger rejectionCount = 0;
  __block NSString *rejectionCode;
  [module startFetchingMetadata:@"provider"
                        request:@{ @"url" : @"https://example.com", @"__useURLAPI" : @YES }
                        timeout:30
        shouldFetchSubresources:YES
                        resolve:^(__unused id value) { XCTFail(@"Unexpected resolve"); }
                         reject:^(NSString *code, __unused NSString *message, __unused NSError *error) {
                           rejectionCount += 1;
                           rejectionCode = code;
                         }];
  [module cancel:@"provider"];
  XCTAssertTrue(fake.cancelled);
  NSError *error = [NSError errorWithDomain:LPErrorDomain code:LPErrorMetadataFetchCancelled userInfo:nil];
  fake.completion(nil, error);
  fake.completion(nil, error);
  XCTAssertEqual(rejectionCount, 1u);
  XCTAssertEqualObjects(rejectionCode, @"LPErrorMetadataFetchCancelled");
}

- (void)testInvalidURLRejectsWithoutStartingProvider
{
  RNLPFakeProvider *fake;
  RNLinkPresentation *module = [self moduleWithFake:&fake];
  __block NSString *rejectionCode;
  [module startFetchingMetadata:@"provider"
                        request:@{ @"url" : @"not-a-url" }
                        timeout:30
        shouldFetchSubresources:YES
                        resolve:^(__unused id value) { XCTFail(@"Unexpected resolve"); }
                         reject:^(NSString *code, __unused NSString *message, __unused NSError *error) { rejectionCode = code; }];
  XCTAssertEqualObjects(rejectionCode, @"E_INVALID_URL");
  XCTAssertNil(fake.completion);
}

@end
