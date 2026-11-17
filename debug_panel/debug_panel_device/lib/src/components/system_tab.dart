import 'package:debug_panel_core/debug_panel_core.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'tab_template.dart';

class SystemTab extends TabTemplate {
  const SystemTab({super.key});

  @override
  String get title => 'System';

  @override
  bool get initiallyOpen => true;
  @override
  Future<List<ListTileItem>> getItemList() async {
    final systemInfo = await DeviceInfoPlugin().deviceInfo;
    return _parseData(systemInfo.data);
  }

  List<ListTileItem> _parseData(Map<String, dynamic> data) {
    return data.entries
        .map(
            (e) => ListTileItem(title: e.key, subtitle: _value(e.key, e.value)))
        .toList();
  }

  /// macOS reports memory in bytes; add a readable size next to it.
  static String _value(String key, Object? value) {
    if (key == 'memorySize' && value is int && value > 0) {
      return '$value (${debugPanelBytes(value)})';
    }
    return '$value';
  }
}
