import 'package:flutter/material.dart';
import 'package:debug_panel_core/core/pluggable.dart';

class IconCache {
  static final Map<String, Widget> _icons = <String, Widget>{};

  static Widget icon({required Pluggable pluggableInfo}) => _icons.putIfAbsent(
        pluggableInfo.name,
        () => Image(image: pluggableInfo.iconImageProvider),
      );
}
