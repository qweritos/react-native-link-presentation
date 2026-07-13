const path = require('path');
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

const packageRoot = path.resolve(__dirname, '..');

module.exports = mergeConfig(getDefaultConfig(__dirname), {
  watchFolders: [packageRoot],
  resolver: {
    disableHierarchicalLookup: true,
    extraNodeModules: {
      '@andreywtf/react-native-link-presentation': packageRoot,
      react: path.resolve(__dirname, 'node_modules/react'),
      'react-native': path.resolve(__dirname, 'node_modules/react-native'),
    },
    nodeModulesPaths: [path.resolve(__dirname, 'node_modules')],
  },
});
