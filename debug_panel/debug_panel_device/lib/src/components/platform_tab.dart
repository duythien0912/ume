import 'dart:io';

import 'tab_template.dart';

class PlatformTab extends TabTemplate {
  const PlatformTab({super.key});

  @override
  Future<List<ListTileItem>> getItemList() async {
    return [
      ListTileItem(
        title: 'Hostname',
        subtitle: Platform.localHostname,
      ),
      ListTileItem(
        title: 'Locale',
        subtitle: Platform.localeName,
      ),
      ListTileItem(
        title: 'Platform',
        subtitle: Platform.operatingSystem,
      ),
      ListTileItem(
        title: 'Platform Version',
        subtitle: Platform.operatingSystemVersion,
      ),
      ListTileItem(
        title: 'Version',
        subtitle: Platform.version,
      ),
      ListTileItem(
        title: 'Environment',
        subtitle: Platform.environment.toString().replaceAll('\n', '\n\n'),
      ),
      ListTileItem(
        title: 'Executable Arguments',
        subtitle: Platform.executableArguments.join('\n'),
      ),
      ListTileItem(
        title: 'Processor Count',
        subtitle: Platform.numberOfProcessors.toString(),
      ),
      ListTileItem(
        title: 'Script',
        subtitle: Platform.script.toString(),
      ),
      ListTileItem(
        title: 'Package Config',
        subtitle: Platform.packageConfig.toString(),
      ),
    ];
  }
}
