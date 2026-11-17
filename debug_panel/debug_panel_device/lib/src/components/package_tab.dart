import 'package:package_info_plus/package_info_plus.dart';

import 'tab_template.dart';

class PackageTab extends TabTemplate {
  const PackageTab({super.key});

  @override
  String get title => 'App';

  @override
  bool get initiallyOpen => true;

  @override
  Future<List<ListTileItem>> getItemList() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return [
      ListTileItem(
        title: 'App Name',
        subtitle: packageInfo.appName,
      ),
      ListTileItem(
        title: 'Package Name',
        subtitle: packageInfo.packageName,
      ),
      ListTileItem(
        title: 'Version',
        subtitle: packageInfo.version,
      ),
      ListTileItem(
        title: 'Build Number',
        subtitle: packageInfo.buildNumber,
      ),
      ListTileItem(
        title: 'Build Signature',
        subtitle: packageInfo.buildSignature,
      ),
      ListTileItem(
        title: 'Installer Store',
        subtitle: packageInfo.installerStore ?? 'Unknown',
      ),
    ];
  }
}
