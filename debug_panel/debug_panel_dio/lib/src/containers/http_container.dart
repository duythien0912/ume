///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 4/13/21 2:49 PM
///
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart' show Response;

/// Keeps the latest responses, newest first, and notifies on change.
class HttpContainer extends ChangeNotifier {
  /// Older entries are dropped past this count so memory stays bounded.
  static const int maxRequests = 300;

  List<Response<dynamic>> get requests => UnmodifiableListView(_requests);
  final List<Response<dynamic>> _requests = <Response<dynamic>>[];

  void addRequest(Response<dynamic> response) {
    _requests.insert(0, response);
    if (_requests.length > maxRequests) {
      _requests.removeRange(maxRequests, _requests.length);
    }
    notifyListeners();
  }

  void clearRequests() {
    _requests.clear();
    notifyListeners();
  }
}
