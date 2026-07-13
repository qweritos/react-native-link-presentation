export type LPItemProvider = {
  nativeId: string;
  registeredTypeIdentifiers: string[];
};

export type LPLinkMetadata = {
  nativeId: string;
  originalURL: string | null;
  url: string | null;
  title: string | null;
  iconProvider: LPItemProvider | null;
  imageProvider: LPItemProvider | null;
  videoProvider: LPItemProvider | null;
  remoteVideoURL: string | null;
};

export type LPItemProviderSource = {
  fileURL: string;
  typeIdentifier?: string;
};

export type LPLinkMetadataInput = {
  originalURL?: string | null;
  url?: string | null;
  title?: string | null;
  iconProvider?: LPItemProviderSource | null;
  imageProvider?: LPItemProviderSource | null;
  videoProvider?: LPItemProviderSource | null;
  remoteVideoURL?: string | null;
};

export type URLRequestCachePolicy =
  | 'useProtocolCachePolicy'
  | 'reloadIgnoringLocalCacheData'
  | 'reloadIgnoringLocalAndRemoteCacheData'
  | 'returnCacheDataElseLoad'
  | 'returnCacheDataDontLoad'
  | 'reloadRevalidatingCacheData';

export type LinkPresentationRequest = {
  url: string;
  method?: string;
  headers?: Record<string, string>;
  bodyBase64?: string;
  timeoutInterval?: number;
  cachePolicy?: URLRequestCachePolicy;
  allowsCellularAccess?: boolean;
  allowsExpensiveNetworkAccess?: boolean;
  allowsConstrainedNetworkAccess?: boolean;
};

export type LPMaterializedItem = {
  fileURL: string;
  typeIdentifier: string;
};

export const LPErrorCode = {
  unknown: 'LPErrorUnknown',
  metadataFetchFailed: 'LPErrorMetadataFetchFailed',
  metadataFetchCancelled: 'LPErrorMetadataFetchCancelled',
  metadataFetchTimedOut: 'LPErrorMetadataFetchTimedOut',
  metadataFetchNotAllowed: 'LPErrorMetadataFetchNotAllowed',
} as const;

export type LPErrorCodeValue = (typeof LPErrorCode)[keyof typeof LPErrorCode];
