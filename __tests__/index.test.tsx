const mockStartFetchingMetadata = jest.fn();
const mockCancel = jest.fn();
const mockCreateLinkMetadataNative = jest.fn();
const mockUpdateLinkMetadataNative = jest.fn();
const mockLoadItemProviderNative = jest.fn();
const mockReleaseLinkMetadataNative = jest.fn();

jest.mock('../src/NativeRNLinkPresentation', () => ({
  __esModule: true,
  default: {
    startFetchingMetadata: mockStartFetchingMetadata,
    cancel: mockCancel,
    createLinkMetadata: mockCreateLinkMetadataNative,
    updateLinkMetadata: mockUpdateLinkMetadataNative,
    loadItemProvider: mockLoadItemProviderNative,
    releaseLinkMetadata: mockReleaseLinkMetadataNative,
  },
}));

jest.mock('../src/LPLinkViewNativeComponent', () => {
  const ReactValue = require('react');
  return {
    __esModule: true,
    default: (props: object) => ReactValue.createElement('LPLinkView', props),
  };
});

import {
  createLinkMetadata,
  getLinkMetadata,
  loadItemProvider,
  LPLinkView,
  LPMetadataProvider,
  releaseLinkMetadata,
  updateLinkMetadata,
} from '../src';
import { Platform } from 'react-native';

const metadata = {
  nativeId: 'metadata-1',
  originalURL: 'https://example.com',
  url: 'https://www.example.com',
  title: 'Example',
};

beforeEach(() => jest.clearAllMocks());

it('fetches with Apple defaults and normalizes optional fields', async () => {
  mockStartFetchingMetadata.mockResolvedValue(metadata);
  await expect(getLinkMetadata('https://example.com')).resolves.toEqual({
    ...metadata,
    iconProvider: null,
    imageProvider: null,
    videoProvider: null,
    remoteVideoURL: null,
  });
  expect(mockStartFetchingMetadata).toHaveBeenCalledWith(
    expect.stringMatching(/^lp-provider-/),
    { url: 'https://example.com', __useURLAPI: true },
    30,
    true,
  );
});

it('forwards provider options and permits only one fetch', async () => {
  mockStartFetchingMetadata.mockResolvedValue(metadata);
  const provider = new LPMetadataProvider();
  provider.timeout = 4;
  provider.shouldFetchSubresources = false;
  await provider.startFetchingMetadata({ url: 'file:///tmp/item' });
  await expect(
    provider.startFetchingMetadata('https://example.com'),
  ).rejects.toMatchObject({
    code: 'E_PROVIDER_ALREADY_STARTED',
  });
  expect(mockStartFetchingMetadata).toHaveBeenCalledWith(
    provider.nativeId,
    { url: 'file:///tmp/item' },
    4,
    false,
  );
});

it('cancels by native provider id', () => {
  const provider = new LPMetadataProvider();
  provider.cancel();
  expect(mockCancel).toHaveBeenCalledWith(provider.nativeId);
});

it('forwards metadata and item-provider operations', async () => {
  mockCreateLinkMetadataNative.mockResolvedValue(metadata);
  mockUpdateLinkMetadataNative.mockResolvedValue({
    ...metadata,
    title: 'Changed',
  });
  mockLoadItemProviderNative.mockResolvedValue({
    fileURL: 'file:///tmp/image.jpg',
    typeIdentifier: 'public.jpeg',
  });

  const created = await createLinkMetadata({ title: 'Example' });
  await updateLinkMetadata(created, { title: 'Changed' });
  await loadItemProvider({
    nativeId: 'provider-1',
    registeredTypeIdentifiers: ['public.jpeg'],
  });
  releaseLinkMetadata(created);

  expect(mockUpdateLinkMetadataNative).toHaveBeenCalledWith('metadata-1', {
    title: 'Changed',
  });
  expect(mockLoadItemProviderNative).toHaveBeenCalledWith('provider-1', null);
  expect(mockReleaseLinkMetadataNative).toHaveBeenCalledWith('metadata-1');
});

it('passes only the native metadata handle to LPLinkView', () => {
  const element = LPLinkView({
    metadata: {
      ...metadata,
      iconProvider: null,
      imageProvider: null,
      videoProvider: null,
      remoteVideoURL: null,
    },
  });
  const props = element?.props as {
    metadataNativeId?: string;
    metadata?: unknown;
  };
  expect(props.metadataNativeId).toBe('metadata-1');
  expect(props.metadata).toBeUndefined();
});

it('imports safely and rejects imperative calls outside iOS', async () => {
  const originalOS = Platform.OS;
  Object.defineProperty(Platform, 'OS', {
    configurable: true,
    value: 'android',
  });
  expect(LPLinkView({ url: 'https://example.com' })).toBeNull();
  await expect(getLinkMetadata('https://example.com')).rejects.toMatchObject({
    code: 'E_UNSUPPORTED_PLATFORM',
  });
  Object.defineProperty(Platform, 'OS', {
    configurable: true,
    value: originalOS,
  });
});
