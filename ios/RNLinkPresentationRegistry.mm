#import "RNLinkPresentationRegistry.h"

static NSString *const RNLPErrorDomain = @"RNLinkPresentationErrorDomain";

NSURL *RNLPURLFromString(id value)
{
  if (![value isKindOfClass:NSString.class] || [value length] == 0) return nil;
  NSURL *URL = [NSURL URLWithString:value];
  if (!URL || URL.scheme.length == 0) return nil;
  return URL;
}

NSString *RNLPErrorCode(NSError *error)
{
  if ([error.domain isEqualToString:LPErrorDomain]) {
    switch ((LPErrorCode)error.code) {
      case LPErrorUnknown: return @"LPErrorUnknown";
      case LPErrorMetadataFetchFailed: return @"LPErrorMetadataFetchFailed";
      case LPErrorMetadataFetchCancelled: return @"LPErrorMetadataFetchCancelled";
      case LPErrorMetadataFetchTimedOut: return @"LPErrorMetadataFetchTimedOut";
      case LPErrorMetadataFetchNotAllowed: return @"LPErrorMetadataFetchNotAllowed";
    }
  }
  return @"LPErrorMetadataFetchFailed";
}

NSError *RNLPBridgeError(NSString *code, NSString *message)
{
  return [NSError errorWithDomain:RNLPErrorDomain
                             code:0
                         userInfo:@{NSLocalizedDescriptionKey : message, @"bridgeCode" : code}];
}
