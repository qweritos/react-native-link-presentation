# JavaScript API reference

The package is iOS-only. On other platforms, functions reject with `E_UNSUPPORTED_PLATFORM`, `assertLinkPresentationAvailable()` throws, and `LPLinkView` renders `null`.

## `getLinkMetadata(url)`

```ts
function getLinkMetadata(url: string): Promise<LPLinkMetadata>;
```

Fetches metadata through a new native `LPMetadataProvider` using Apple's defaults: a 30-second timeout and subresource fetching enabled. Use the `LPMetadataProvider` class when the request needs cancellation or configuration.

## `LPMetadataProvider`

```ts
class LPMetadataProvider {
  timeout: number;
  shouldFetchSubresources: boolean;
  readonly nativeId: string;

  startFetchingMetadata(
    input: string | LinkPresentationRequest,
  ): Promise<LPLinkMetadata>;
  cancel(): void;
}
```

| Member                    | Description                                                               |
| ------------------------- | ------------------------------------------------------------------------- |
| `timeout`                 | Native provider timeout in seconds. Defaults to `30`.                     |
| `shouldFetchSubresources` | Whether LinkPresentation may fetch subresources. Defaults to `true`.      |
| `nativeId`                | Runtime-only native provider handle. Treat it as opaque.                  |
| `startFetchingMetadata`   | Starts the native fetch from a URL string or bridge-safe request object.  |
| `cancel`                  | Cancels an active native fetch. The pending promise rejects as cancelled. |

Each instance is single-use. Calling `startFetchingMetadata` again rejects with `E_PROVIDER_ALREADY_STARTED`.

## `LPLinkView`

```tsx
type LPLinkViewProps = ViewProps &
  (
    | { url: string; metadata?: never }
    | { metadata: LPLinkMetadata; url?: never }
  );

function LPLinkView(props: LPLinkViewProps): React.ReactElement | null;
```

Exactly one of `url` or `metadata` is required.

- `url` creates Apple's native URL placeholder. It does not fetch metadata.
- `metadata` displays the retained native `LPLinkMetadata`, preserving content and interactions that do not cross the JavaScript bridge.

The component accepts standard React Native `ViewProps`, including `style`.

## `createLinkMetadata(input)`

```ts
function createLinkMetadata(
  input: LPLinkMetadataInput,
): Promise<LPLinkMetadata>;
```

Creates a native `LPLinkMetadata` object. Item providers are created from local file URLs; remote item-provider URLs are not loaded by JavaScript.

## `updateLinkMetadata(metadata, patch)`

```ts
function updateLinkMetadata(
  metadata: LPLinkMetadata,
  patch: LPLinkMetadataInput,
): Promise<LPLinkMetadata>;
```

Updates writable properties on the retained native object and returns a refreshed serializable snapshot. Omitted properties remain unchanged; nullable properties may be cleared with `null`.

## `loadItemProvider(provider, typeIdentifier?)`

```ts
function loadItemProvider(
  provider: LPItemProvider,
  typeIdentifier?: string,
): Promise<LPMaterializedItem>;
```

Loads an `NSItemProvider` natively and copies the result into the module cache before Apple's temporary URL becomes invalid. If `typeIdentifier` is omitted, the native implementation selects a registered type. The returned `fileURL` is suitable for React Native's `Image` source.

## `releaseLinkMetadata(metadata)`

```ts
function releaseLinkMetadata(metadata: LPLinkMetadata): void;
```

Releases the native metadata handle and its retained item-provider handles. Call it after the metadata is no longer displayed or used. Runtime handles are not persistable and must not be reused after release.

## `assertLinkPresentationAvailable()`

```ts
function assertLinkPresentationAvailable(): void;
```

Returns on iOS and throws an error with code `E_UNSUPPORTED_PLATFORM` elsewhere.

## Types

### `LPLinkMetadata`

```ts
type LPLinkMetadata = {
  nativeId: string;
  originalURL: string | null;
  url: string | null;
  title: string | null;
  iconProvider: LPItemProvider | null;
  imageProvider: LPItemProvider | null;
  videoProvider: LPItemProvider | null;
  remoteVideoURL: string | null;
};
```

This is the bridge-safe subset of Apple's `LPLinkMetadata`. `nativeId` refers to the complete retained native object used by `LPLinkView`.

### `LPItemProvider`

```ts
type LPItemProvider = {
  nativeId: string;
  registeredTypeIdentifiers: string[];
};
```

Represents a retained native `NSItemProvider` without eagerly materializing its data.

### `LPLinkMetadataInput`

```ts
type LPItemProviderSource = {
  fileURL: string;
  typeIdentifier?: string;
};

type LPLinkMetadataInput = {
  originalURL?: string | null;
  url?: string | null;
  title?: string | null;
  iconProvider?: LPItemProviderSource | null;
  imageProvider?: LPItemProviderSource | null;
  videoProvider?: LPItemProviderSource | null;
  remoteVideoURL?: string | null;
};
```

`fileURL` must refer to a local file accessible to the application.

### `LinkPresentationRequest`

```ts
type LinkPresentationRequest = {
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
```

The object is translated to `URLRequest` and passed to LinkPresentation. Supported cache policies are:

```ts
type URLRequestCachePolicy =
  | 'useProtocolCachePolicy'
  | 'reloadIgnoringLocalCacheData'
  | 'reloadIgnoringLocalAndRemoteCacheData'
  | 'returnCacheDataElseLoad'
  | 'returnCacheDataDontLoad'
  | 'reloadRevalidatingCacheData';
```

### `LPMaterializedItem`

```ts
type LPMaterializedItem = {
  fileURL: string;
  typeIdentifier: string;
};
```

### `LPErrorCode`

```ts
const LPErrorCode = {
  unknown: 'LPErrorUnknown',
  metadataFetchFailed: 'LPErrorMetadataFetchFailed',
  metadataFetchCancelled: 'LPErrorMetadataFetchCancelled',
  metadataFetchTimedOut: 'LPErrorMetadataFetchTimedOut',
  metadataFetchNotAllowed: 'LPErrorMetadataFetchNotAllowed',
} as const;

type LPErrorCodeValue = (typeof LPErrorCode)[keyof typeof LPErrorCode];
```

Native failures reject with an `Error` carrying a `code` property. Apple's `LPErrorDomain` values use the constants above. Bridge errors include:

- `E_UNSUPPORTED_PLATFORM`
- `E_INVALID_URL`
- `E_INVALID_REQUEST`
- `E_PROVIDER_ALREADY_STARTED`
- `E_INVALID_METADATA`
- `E_METADATA_RELEASED`
- `E_INVALID_ITEM_PROVIDER`
- `E_ITEM_PROVIDER_RELEASED`
- `E_ITEM_PROVIDER_TYPE`
- `E_ITEM_PROVIDER_LOAD_FAILED`
