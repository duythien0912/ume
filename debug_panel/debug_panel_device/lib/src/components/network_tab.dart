import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'tab_template.dart';

class NetworkTab extends TabTemplate {
  const NetworkTab({super.key});

  @override
  Future<List<ListTileItem>> getItemList() async {
    final info = NetworkInfo();
    final connectivity = Connectivity().checkConnectivity();
    final values = await Future.wait(<Future<String?>>[
      info.getWifiName(),
      info.getWifiBSSID(),
      info.getWifiIP(),
      info.getWifiIPv6(),
      info.getWifiSubmask(),
      info.getWifiBroadcast(),
      info.getWifiGatewayIP(),
    ]);
    const titles = <String>[
      'Network name',
      'BSSID',
      'IP address',
      'IPv6 address',
      'Submask',
      'Broadcast',
      'Gateway',
    ];
    return [
      ListTileItem(
        title: 'Connectivity',
        subtitle: (await connectivity).map((r) => r.name).join(', '),
      ),
      for (var i = 0; i < titles.length; i++)
        ListTileItem(title: titles[i], subtitle: values[i] ?? 'Unavailable'),
    ];
  }
}
