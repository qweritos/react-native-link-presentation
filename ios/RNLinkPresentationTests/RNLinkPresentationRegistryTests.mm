#import <XCTest/XCTest.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "RNLinkPresentationRegistry.h"

@interface RNLinkPresentationRegistryTests : XCTestCase
@end

@implementation RNLinkPresentationRegistryTests

- (void)setUp
{
  [[RNLinkPresentationRegistry shared] removeAll];
}

- (void)testStoresEveryPublicMetadataProperty
{
  LPLinkMetadata *metadata = [LPLinkMetadata new];
  metadata.originalURL = [NSURL URLWithString:@"https://example.com/original"];
  metadata.URL = [NSURL URLWithString:@"https://example.com/redirected"];
  metadata.title = @"Example";
  metadata.remoteVideoURL = [NSURL URLWithString:@"https://example.com/video.mp4"];
  metadata.imageProvider = [[NSItemProvider alloc] initWithItem:@"image" typeIdentifier:UTTypePlainText.identifier];

  NSDictionary *value = [[RNLinkPresentationRegistry shared] storeMetadata:metadata];

  XCTAssertEqualObjects(value[@"title"], @"Example");
  XCTAssertEqualObjects(value[@"originalURL"], @"https://example.com/original");
  XCTAssertEqualObjects(value[@"url"], @"https://example.com/redirected");
  XCTAssertEqualObjects(value[@"remoteVideoURL"], @"https://example.com/video.mp4");
  XCTAssertEqualObjects(value[@"imageProvider"][@"registeredTypeIdentifiers"], (@[ UTTypePlainText.identifier ]));
  XCTAssertEqual([[RNLinkPresentationRegistry shared] metadataForIdentifier:value[@"nativeId"]], metadata);
}

- (void)testReleaseAlsoReleasesOwnedProviders
{
  LPLinkMetadata *metadata = [LPLinkMetadata new];
  metadata.iconProvider = [[NSItemProvider alloc] initWithItem:@"icon" typeIdentifier:UTTypePlainText.identifier];
  NSDictionary *value = [[RNLinkPresentationRegistry shared] storeMetadata:metadata];
  NSString *providerId = value[@"iconProvider"][@"nativeId"];

  [[RNLinkPresentationRegistry shared] releaseMetadata:value[@"nativeId"]];

  XCTAssertNil([[RNLinkPresentationRegistry shared] metadataForIdentifier:value[@"nativeId"]]);
  XCTAssertNil([[RNLinkPresentationRegistry shared] itemProviderForIdentifier:providerId]);
}

- (void)testURLValidation
{
  XCTAssertNotNil(RNLPURLFromString(@"https://example.com"));
  XCTAssertNotNil(RNLPURLFromString(@"file:///tmp/item"));
  XCTAssertNil(RNLPURLFromString(@"example.com"));
  XCTAssertNil(RNLPURLFromString(@""));
}

- (void)testLinkPresentationErrorMapping
{
  NSError *cancelled = [NSError errorWithDomain:LPErrorDomain code:LPErrorMetadataFetchCancelled userInfo:nil];
  NSError *timeout = [NSError errorWithDomain:LPErrorDomain code:LPErrorMetadataFetchTimedOut userInfo:nil];
  XCTAssertEqualObjects(RNLPErrorCode(cancelled), @"LPErrorMetadataFetchCancelled");
  XCTAssertEqualObjects(RNLPErrorCode(timeout), @"LPErrorMetadataFetchTimedOut");
}

@end
