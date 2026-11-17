# debug_panel_dio

Dio network inspector for [`debug_panel_core`](https://pub.dev/packages/debug_panel_core).

- Lists the latest 300 requests, newest first, with method, status, duration, host and time.
- Tap a request to expand it in place: URL, start time, then request and response headers and bodies in sections that open and close. JSON bodies get line numbers and colors.
- Requests that never got a response (network errors, timeouts) show as `ERR`, with the error message when expanded.
- Long-press a row, or tap Copy all, to copy the whole request: URL, status, headers, bodies and a cURL command. Each section can also be copied on its own.

## Usage

```dart
final dio = Dio();
PluginManager.instance.register(DioInspector(dio: dio));
```

`DioInspector` adds `DebugPanelDioInterceptor` to the given `Dio`.

## Credits

Based on UME (`ume_kit_dio`). MIT license; see LICENSE.
