import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export type NativeMetadata = Readonly<{
  nativeId: string;
  originalURL?: string;
  url?: string;
  title?: string;
  iconProvider?: Readonly<{
    nativeId: string;
    registeredTypeIdentifiers: string[];
  }>;
  imageProvider?: Readonly<{
    nativeId: string;
    registeredTypeIdentifiers: string[];
  }>;
  videoProvider?: Readonly<{
    nativeId: string;
    registeredTypeIdentifiers: string[];
  }>;
  remoteVideoURL?: string;
}>;

export interface Spec extends TurboModule {
  startFetchingMetadata(
    providerId: string,
    request: Object,
    timeout: number,
    shouldFetchSubresources: boolean,
  ): Promise<NativeMetadata>;
  cancel(providerId: string): void;
  createLinkMetadata(input: Object): Promise<NativeMetadata>;
  updateLinkMetadata(nativeId: string, patch: Object): Promise<NativeMetadata>;
  loadItemProvider(
    nativeId: string,
    typeIdentifier: string | null,
  ): Promise<Object>;
  releaseLinkMetadata(nativeId: string): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('RNLinkPresentation');
