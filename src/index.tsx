import React from 'react';
import { Platform, requireNativeComponent, type ViewProps } from 'react-native';
import { nativeModule, unsupportedError } from './native';
import type {
  LinkPresentationRequest,
  LPMaterializedItem,
  LPItemProvider,
  LPLinkMetadata,
  LPLinkMetadataInput,
} from './types';

export * from './types';

let nextProviderId = 1;

const nullable = <T,>(value: T | undefined): T | null => value ?? null;

function normalizeMetadata(value: any): LPLinkMetadata {
  return {
    nativeId: value.nativeId,
    originalURL: nullable(value.originalURL),
    url: nullable(value.url),
    title: nullable(value.title),
    iconProvider: nullable(value.iconProvider),
    imageProvider: nullable(value.imageProvider),
    videoProvider: nullable(value.videoProvider),
    remoteVideoURL: nullable(value.remoteVideoURL),
  };
}

export class LPMetadataProvider {
  timeout = 30;
  shouldFetchSubresources = true;
  readonly nativeId = `lp-provider-${Date.now()}-${nextProviderId++}`;
  private started = false;

  startFetchingMetadata(
    input: string | LinkPresentationRequest,
  ): Promise<LPLinkMetadata> {
    if (this.started) {
      return Promise.reject(
        Object.assign(
          new Error('LPMetadataProvider instances are single-use'),
          {
            code: 'E_PROVIDER_ALREADY_STARTED',
          },
        ),
      );
    }
    this.started = true;
    const request =
      typeof input === 'string' ? { url: input, __useURLAPI: true } : input;
    try {
      return nativeModule()
        .startFetchingMetadata(
          this.nativeId,
          request,
          this.timeout,
          this.shouldFetchSubresources,
        )
        .then(normalizeMetadata);
    } catch (error) {
      return Promise.reject(error);
    }
  }

  cancel(): void {
    if (Platform.OS === 'ios') {
      nativeModule().cancel(this.nativeId);
    }
  }
}

export function getLinkMetadata(url: string): Promise<LPLinkMetadata> {
  return new LPMetadataProvider().startFetchingMetadata(url);
}

export async function createLinkMetadata(
  input: LPLinkMetadataInput,
): Promise<LPLinkMetadata> {
  try {
    return normalizeMetadata(await nativeModule().createLinkMetadata(input));
  } catch (error) {
    return Promise.reject(error);
  }
}

export async function updateLinkMetadata(
  metadata: LPLinkMetadata,
  patch: LPLinkMetadataInput,
): Promise<LPLinkMetadata> {
  try {
    return normalizeMetadata(
      await nativeModule().updateLinkMetadata(metadata.nativeId, patch),
    );
  } catch (error) {
    return Promise.reject(error);
  }
}

export async function loadItemProvider(
  provider: LPItemProvider,
  typeIdentifier?: string,
): Promise<LPMaterializedItem> {
  try {
    return (await nativeModule().loadItemProvider(
      provider.nativeId,
      typeIdentifier ?? null,
    )) as LPMaterializedItem;
  } catch (error) {
    return Promise.reject(error);
  }
}

export function releaseLinkMetadata(metadata: LPLinkMetadata): void {
  if (Platform.OS === 'ios') {
    nativeModule().releaseLinkMetadata(metadata.nativeId);
  }
}

type LPLinkViewProps = ViewProps &
  (
    | { url: string; metadata?: never }
    | { metadata: LPLinkMetadata; url?: never }
  );

let NativeLPLinkView: React.ComponentType<any> | undefined;

function nativeLinkView(): React.ComponentType<any> {
  if (NativeLPLinkView) return NativeLPLinkView;
  const isFabric = Boolean((globalThis as any).nativeFabricUIManager);
  NativeLPLinkView = isFabric
    ? require('./LPLinkViewNativeComponent').default
    : requireNativeComponent('RNLPLinkView');
  return NativeLPLinkView as React.ComponentType<any>;
}

export function LPLinkView(props: LPLinkViewProps): React.ReactElement | null {
  if (Platform.OS !== 'ios') {
    return null;
  }
  const Component = nativeLinkView();
  if ('metadata' in props && props.metadata) {
    const { metadata, ...rest } = props;
    return <Component {...rest} metadataNativeId={metadata.nativeId} />;
  }
  return <Component {...props} />;
}

export function assertLinkPresentationAvailable(): void {
  if (Platform.OS !== 'ios') {
    throw unsupportedError();
  }
}
