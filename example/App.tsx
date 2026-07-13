import React, { useEffect, useState } from 'react';
import {
  Image,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  loadItemProvider,
  LPLinkView,
  LPMetadataProvider,
  releaseLinkMetadata,
  type LPLinkMetadata,
} from '@andreywtf/react-native-link-presentation';

export default function App() {
  const [url, setURL] = useState('https://www.apple.com/iphone/');
  const [metadata, setMetadata] = useState<LPLinkMetadata | null>(null);
  const [images, setImages] = useState<{
    iconURL: string | null;
    previewURL: string | null;
  }>({ iconURL: null, previewURL: null });
  const [message, setMessage] = useState('Waiting to load…');

  useEffect(() => {
    let active = true;
    let provider: LPMetadataProvider | null = null;
    let loadedMetadata: LPLinkMetadata | null = null;
    setMetadata(null);
    setImages({ iconURL: null, previewURL: null });
    setMessage('Waiting to load…');

    const timer = setTimeout(async () => {
      provider = new LPMetadataProvider();
      provider.timeout = 30;
      provider.shouldFetchSubresources = true;
      setMessage('Loading with LPMetadataProvider…');

      try {
        const result = await provider.startFetchingMetadata(url);
        if (!active) {
          releaseLinkMetadata(result);
          return;
        }
        loadedMetadata = result;
        setMetadata(result);
        setMessage(result.title ?? 'Loaded without a title');

        const [icon, preview] = await Promise.all([
          result.iconProvider
            ? loadItemProvider(result.iconProvider).catch(() => null)
            : null,
          result.imageProvider
            ? loadItemProvider(result.imageProvider).catch(() => null)
            : null,
        ]);
        if (!active) return;
        setImages({
          iconURL: icon?.fileURL ?? null,
          previewURL: preview?.fileURL ?? null,
        });
      } catch (error: any) {
        if (!active) return;
        setMessage(`${error.code ?? 'Error'}: ${error.message}`);
      }
    }, 500);

    return () => {
      active = false;
      clearTimeout(timer);
      provider?.cancel();
      if (loadedMetadata) releaseLinkMetadata(loadedMetadata);
    };
  }, [url]);

  return (
    <SafeAreaView style={styles.safeArea}>
      <ScrollView contentContainerStyle={styles.content}>
        <TextInput
          autoCapitalize="none"
          autoCorrect={false}
          onChangeText={setURL}
          style={styles.input}
          value={url}
        />
        <Text style={styles.status}>{message}</Text>

        <Text style={styles.label}>URL placeholder</Text>
        <View style={styles.placeholderContainer}>
          <LPLinkView url={url} style={styles.inlinePreview} />
        </View>

        {metadata ? (
          <>
            <Text style={styles.label}>Fetched metadata</Text>
            <LPLinkView metadata={metadata} style={styles.preview} />
            {images.iconURL || images.previewURL ? (
              <View style={styles.imageRow}>
                {images.iconURL ? (
                  <View style={[styles.assetGroup, styles.iconGroup]}>
                    <Text style={styles.assetCaption}>Icon</Text>
                    <Image
                      resizeMode="contain"
                      source={{ uri: images.iconURL }}
                      style={styles.providerIcon}
                    />
                  </View>
                ) : null}
                {images.previewURL ? (
                  <View style={[styles.assetGroup, styles.previewGroup]}>
                    <Text style={styles.assetCaption}>Image</Text>
                    <Image
                      resizeMode="cover"
                      source={{ uri: images.previewURL }}
                      style={styles.providerPreview}
                    />
                  </View>
                ) : null}
              </View>
            ) : null}
            <Text style={styles.label}>Metadata JSON</Text>
            <Text selectable style={styles.metadataJSON}>
              {JSON.stringify(metadata, null, 2)}
            </Text>
          </>
        ) : null}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: { flex: 1 },
  content: { gap: 8, padding: 16 },
  input: { borderColor: '#999', borderRadius: 8, borderWidth: 1, padding: 8 },
  status: { color: '#555', fontSize: 13 },
  label: { color: '#777', fontSize: 11, fontWeight: '500', marginTop: 4 },
  placeholderContainer: {
    height: 52,
    justifyContent: 'center',
    width: '100%',
  },
  inlinePreview: { height: 48, width: '100%' },
  preview: { height: 180, width: '100%' },
  imageRow: {
    alignItems: 'flex-start',
    flexDirection: 'row',
    gap: 8,
    height: 115,
    marginTop: 4,
    width: '100%',
  },
  assetGroup: { gap: 4 },
  assetCaption: { color: '#777', fontSize: 11, fontWeight: '500' },
  iconGroup: { width: 72 },
  previewGroup: { flex: 1 },
  providerIcon: {
    backgroundColor: '#eee',
    borderRadius: 12,
    height: 72,
    width: 72,
  },
  providerPreview: {
    backgroundColor: '#eee',
    borderRadius: 12,
    height: 96,
    width: '100%',
  },
  metadataJSON: {
    alignSelf: 'stretch',
    flexShrink: 1,
    fontFamily: 'Menlo',
    fontSize: 8,
    lineHeight: 10,
    maxWidth: '100%',
  },
});
