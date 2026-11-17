///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/8/6 13:58
///
import 'package:dio/dio.dart' show Response;

import 'constants.dart';

extension ResponseExtension on Response<dynamic> {
  /// When the request was sent, or null if the inspector didn't see it start.
  DateTime? get startTime => _time(DIO_EXTRA_START_TIME);

  /// When the response or error arrived.
  DateTime? get endTime => _time(DIO_EXTRA_END_TIME);

  Duration? get duration {
    final start = startTime;
    final end = endTime;
    return start == null || end == null ? null : end.difference(start);
  }

  DateTime? _time(String key) {
    final value = requestOptions.extra[key];
    return value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
  }
}
