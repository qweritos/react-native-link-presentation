import { Platform } from 'react-native';
import type { Spec } from './NativeRNLinkPresentation';

let moduleValue: Spec | undefined;

export function nativeModule(): Spec {
  if (Platform.OS !== 'ios') {
    const error = new Error('LinkPresentation is only available on iOS');
    Object.assign(error, { code: 'E_UNSUPPORTED_PLATFORM' });
    throw error;
  }
  moduleValue ??= require('./NativeRNLinkPresentation').default as Spec;
  return moduleValue;
}

export function unsupportedError(): Error & { code: string } {
  return Object.assign(new Error('LinkPresentation is only available on iOS'), {
    code: 'E_UNSUPPORTED_PLATFORM',
  });
}
