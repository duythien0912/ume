import 'package:flutter/material.dart';
import 'package:debug_panel_core/debug_panel_core.dart';

import 'components/battery_tab.dart';
import 'components/network_tab.dart';
import 'components/package_tab.dart';
import 'components/system_tab.dart';
import 'components/copyright_tab.dart';
import 'components/platform_tab.dart';

class DeviceInfo extends StatefulWidget implements Pluggable {
  @override
  _DeviceInfoState createState() => _DeviceInfoState();

  @override
  Widget buildWidget(BuildContext? context) => this;

  @override
  String get name => 'DeviceInfo';

  @override
  String get displayName => 'Device info';

  @override
  void onTrigger() {}
}

class _DeviceInfoState extends State<DeviceInfo> {
  bool _licenses = false;

  @override
  Widget build(BuildContext context) {
    // Both stay built, so open sections survive a trip to Licenses.
    return IndexedStack(
      index: _licenses ? 1 : 0,
      children: <Widget>[_sections(context), _licensesView()],
    );
  }

  Widget _licensesView() {
    if (!_licenses) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _licenses = false),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Device info'),
            style: TextButton.styleFrom(foregroundColor: DebugPanelColors.text),
          ),
        ),
        const Divider(),
        const Expanded(child: CopyrightTab()),
      ],
    );
  }

  Widget _sections(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: 4,
        bottom: MediaQuery.paddingOf(context).bottom + 8,
      ),
      children: <Widget>[
        const SystemTab(),
        const PackageTab(),
        const NetworkTab(),
        const BatteryTab(),
        const PlatformTab(),
        DebugPanelSectionHeader(
          title: 'Licenses',
          open: false,
          indent: 8,
          onTap: () => setState(() => _licenses = true),
        ),
      ],
    );
  }
}
