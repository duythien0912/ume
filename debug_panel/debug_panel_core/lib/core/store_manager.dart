import 'package:flutter/foundation.dart';
import 'package:debug_panel_core/core/pluggable.dart';
import 'package:debug_panel_core/core/plugin_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';

class PluginStoreManager {
  final String _pluginStoreKey = 'PluginStoreKey';
  final String _minimalToolbarSwitch = 'MinimalToolbarSwitch';
  final String _floatingDotPos = 'FloatingDotPos';

  Future<SharedPreferences> _sharedPref = SharedPreferences.getInstance();

  Future<List<String>?> fetchStorePlugins() async {
    final SharedPreferences prefs = await _sharedPref;
    return prefs.getStringList(_pluginStoreKey);
  }

  void storePlugins(List<String> plugins) async {
    if (plugins.isEmpty) {
      return;
    }
    final SharedPreferences prefs = await _sharedPref;
    await prefs.setStringList(_pluginStoreKey, plugins);
  }

  Future<bool?> fetchMinimalToolbarSwitch() async {
    final SharedPreferences prefs = await _sharedPref;
    return prefs.getBool(_minimalToolbarSwitch);
  }

  void storeMinimalToolbarSwitch(bool value) async {
    final SharedPreferences prefs = await _sharedPref;
    await prefs.setBool(_minimalToolbarSwitch, value);
  }

  Future<String?> fetchFloatingDotPos() async {
    final SharedPreferences prefs = await _sharedPref;
    return prefs.getString(_floatingDotPos);
  }

  void storeFloatingDotPos(double x, double y) async {
    final SharedPreferences prefs = await _sharedPref;
    prefs.setString(_floatingDotPos, "$x,$y");
  }
}

/// Registered plugins in the order the user last arranged them.
Future<List<Pluggable>> loadOrderedPlugins() async {
  final plugins = PluginManager.instance.pluginsMap;
  final stored = await PluginStoreManager().fetchStorePlugins() ?? <String>[];
  final ordered = <Pluggable>[
    for (final name in stored)
      if (plugins[name] != null) plugins[name]!,
    for (final entry in plugins.entries)
      if (!stored.contains(entry.key) && entry.value != null) entry.value!,
  ];
  final names = ordered.map((p) => p.name).toList();
  if (!listEquals(names, stored)) PluginStoreManager().storePlugins(names);
  return ordered;
}
