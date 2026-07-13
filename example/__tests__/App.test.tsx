/**
 * @format
 */

import React from 'react';
import ReactTestRenderer from 'react-test-renderer';
import App from '../App';

test('renders correctly and cleans up its debounced request', () => {
  jest.useFakeTimers();
  let renderer: ReactTestRenderer.ReactTestRenderer;

  ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });
  ReactTestRenderer.act(() => {
    renderer.unmount();
  });
  jest.runOnlyPendingTimers();
  jest.useRealTimers();
});
