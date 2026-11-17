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
- The panel is a dark bottom sheet. Chips at the top switch tools; the expand button (or a drag on the header) toggles full height.
- It opens on the tool named by `initialTool` (the Dio inspector by default), or the first registered tool.
- `DebugPanel.closeActivatedPlugin()` closes the panel from code.
- `debugPanelTheme`, `DebugPanelColors`, `DebugPanelIconButton`, `DebugPanelCopyButton`, `DebugPanelCopyAction` and `debugPanelCopy` let tools match the panel.

## Credits

Based on [UME](https://github.com/insightop/ume) (`ume_core`). MIT license; see LICENSE.
