#import <XCTest/XCTest.h>
#import "RNLPLinkView.h"
#import "RNLinkPresentationRegistry.h"

@interface RNLPLinkViewTests : XCTestCase
@end

@implementation RNLPLinkViewTests

- (void)testAcceptsURLPlaceholder
{
  RNLPLinkView *view = [RNLPLinkView new];
  view.url = @"https://example.com";
  XCTAssertEqualObjects(view.url, @"https://example.com");
  XCTAssertFalse(CGSizeEqualToSize(view.intrinsicContentSize, CGSizeZero));
}

- (void)testAcceptsRegisteredMetadata
{
  LPLinkMetadata *metadata = [LPLinkMetadata new];
  metadata.URL = [NSURL URLWithString:@"https://example.com"];
  metadata.title = @"Example";
  NSDictionary *stored = [[RNLinkPresentationRegistry shared] storeMetadata:metadata];
  RNLPLinkView *view = [RNLPLinkView new];
  view.metadataNativeId = stored[@"nativeId"];
  XCTAssertEqualObjects(view.metadataNativeId, stored[@"nativeId"]);
}

@end
