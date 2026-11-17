///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/8/6 11:24
///

import 'package:flutter/material.dart';
import 'package:dio/dio.dart' show Dio;
import 'package:debug_panel_core/core/pluggable.dart';

import 'models/http_interceptor.dart';
import 'widgets/pluggable_state.dart';

/// Implement a [Pluggable] to integrate with the debug panel.
class DioInspector extends StatefulWidget implements Pluggable {
  DioInspector({Key? key, required this.dio}) : super(key: key) {
    dio.interceptors.add(DebugPanelDioInterceptor());
  }

  final Dio dio;

  @override
  DioPluggableState createState() => DioPluggableState();

  @override
  String get name => 'DioInspector';

  @override
  String get displayName => 'Network';

  @override
  void onTrigger() {}

  @override
  Widget buildWidget(BuildContext? context) => this;
}
