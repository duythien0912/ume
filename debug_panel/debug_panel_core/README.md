# debug_panel_core

An in-app debug panel for Flutter. Wrap the app, register tools, and open the panel from a floating button.

## Usage

```dart
import 'package:debug_panel_core/debug_panel_core.dart';
import 'package:debug_panel_device/debug_panel_device.dart';
import 'package:debug_panel_dio/debug_panel_dio.dart';

void main() {
  PluginManager.instance
    ..register(DeviceInfo())
    ..register(DioInspector(dio: dio));
  runApp(DebugPanel(enable: true, child: const MyApp()));
}
```

- Tap the floating button to open the panel. Drag it to move it.
- The compact panel shows the tools in a row; expand it to see them in a grid and long-press to reorder.
- A tool that draws its own close button implements `PluggableWithCloseButton` and calls `DebugPanel.closeActivatedPlugin()`; the floating button hides while it is open.
- `debugPanelTheme`, `DebugPanelColors`, `DebugPanelIconButton`, `DebugPanelCopyButton` and `DebugPanelCopyAction` let tools match the panel.

## Credits

Based on [UME](https://github.com/insightop/ume) (`ume_core`). MIT license; see LICENSE.
