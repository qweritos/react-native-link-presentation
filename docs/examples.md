# Usage examples

All URL loading and metadata extraction in these examples is performed by Apple's LinkPresentation framework.

## Fetch and display a preview

```tsx
import { useEffect, useState } from 'react';
import {
  getLinkMetadata,
  LPLinkView,
  releaseLinkMetadata,
  type LPLinkMetadata,
} from '@andreywtf/react-native-link-presentation';

export function LinkPreview({ url }: { url: string }) {
  const [metadata, setMetadata] = useState<LPLinkMetadata | null>(null);

  useEffect(() => {
    let active = true;
    let loaded: LPLinkMetadata | null = null;
    setMetadata(null);

    void getLinkMetadata(url)
      .then((result) => {
        if (!active) {
          releaseLinkMetadata(result);
          return;
        }
        loaded = result;
        setMetadata(result);
      })
      .catch(() => {});

    return () => {
      active = false;
      if (loaded) releaseLinkMetadata(loaded);
    };
  }, [url]);

  return metadata ? (
    <LPLinkView metadata={metadata} style={{ height: 180 }} />
  ) : null;
}
```

## Cancel a fetch

```ts
import { LPMetadataProvider } from '@andreywtf/react-native-link-presentation';

const provider = new LPMetadataProvider();
provider.timeout = 10;
provider.shouldFetchSubresources = true;

const pendingMetadata = provider.startFetchingMetadata('https://example.com');
provider.cancel();

await pendingMetadata; // rejects with LPErrorMetadataFetchCancelled
```

An `LPMetadataProvider` instance can start only one request. Create a new instance for every fetch.

## Use a custom URL request

```ts
import { LPMetadataProvider } from '@andreywtf/react-native-link-presentation';

const provider = new LPMetadataProvider();
const metadata = await provider.startFetchingMetadata({
  url: 'https://example.com/private-link',
  method: 'GET',
  headers: { Authorization: 'Bearer token' },
  timeoutInterval: 15,
  cachePolicy: 'reloadIgnoringLocalCacheData',
  allowsCellularAccess: true,
  allowsExpensiveNetworkAccess: true,
  allowsConstrainedNetworkAccess: true,
});
```

For a request body, pass its encoded bytes through `bodyBase64`.

## Display a URL placeholder

```tsx
import { LPLinkView } from '@andreywtf/react-native-link-presentation';

<LPLinkView url="https://example.com/article" style={{ height: 48 }} />;
```

This maps to Apple's `LPLinkView(url:)` initializer and does not fetch metadata.

## Materialize an icon or preview image

Fetched item providers stay native until explicitly loaded.

```tsx
import { Image } from 'react-native';
import { loadItemProvider } from '@andreywtf/react-native-link-presentation';

const item = metadata.imageProvider
  ? await loadItemProvider(metadata.imageProvider)
  : null;

const preview = item ? (
  <Image source={{ uri: item.fileURL }} style={{ width: 320, height: 180 }} />
) : null;
```

Request a specific provider type when needed:

```ts
const png = metadata.iconProvider
  ? await loadItemProvider(metadata.iconProvider, 'public.png')
  : null;
```

The returned cache URL is local. No JavaScript networking or metadata parsing is involved.

## Create custom metadata

Item providers for custom metadata are constructed from local files.

```tsx
import {
  createLinkMetadata,
  LPLinkView,
} from '@andreywtf/react-native-link-presentation';

const metadata = await createLinkMetadata({
  originalURL: 'https://example.com/article',
  url: 'https://example.com/article',
  title: 'Article title',
  iconProvider: { fileURL: 'file:///path/to/icon.png' },
  imageProvider: {
    fileURL: 'file:///path/to/preview.jpg',
    typeIdentifier: 'public.jpeg',
  },
});

<LPLinkView metadata={metadata} style={{ height: 180 }} />;
```

## Update and release metadata

```ts
import {
  releaseLinkMetadata,
  updateLinkMetadata,
} from '@andreywtf/react-native-link-presentation';

const updated = await updateLinkMetadata(metadata, {
  title: 'Updated article title',
  imageProvider: null,
});

releaseLinkMetadata(updated);
```

Release metadata only after every `LPLinkView` and item-provider operation using it has finished.
