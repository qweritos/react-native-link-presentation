import {
  codegenNativeComponent,
  type HostComponent,
  type ViewProps,
} from 'react-native';

export interface NativeProps extends ViewProps {
  url?: string;
  metadataNativeId?: string;
}

export default codegenNativeComponent<NativeProps>(
  'RNLPLinkView',
) as HostComponent<NativeProps>;
