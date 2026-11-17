import 'package:battery_plus/battery_plus.dart';

import 'tab_template.dart';

class BatteryTab extends TabTemplate {
  const BatteryTab({super.key});

  @override
  Future<List<ListTileItem>> getItemList() async {
    final battery = Battery();

    return [
      ListTileItem(
        title: 'Level',
        subtitle: '${await battery.batteryLevel}%',
      ),
      ListTileItem(
        title: 'State',
        subtitle: (await battery.batteryState).name,
      ),
      ListTileItem(
        title: 'Save Mode',
        subtitle: '${await battery.isInBatterySaveMode}',
      ),
    ];
  }
}
