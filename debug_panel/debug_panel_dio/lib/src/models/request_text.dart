import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/extensions.dart';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');
const int _maxPrettyChars = 512 * 1024;

/// Text forms of one recorded request, for display and copying.
class RequestText {
  RequestText(this.response);

  static final Expando<RequestText> _cache = Expando<RequestText>();

  /// One shared instance per response, so text is formatted only once.
  static RequestText of(Response<dynamic> response) =>
      _cache[response] ??= RequestText(response);

  final Response<dynamic> response;

  RequestOptions get _request => response.requestOptions;

  /// Null when the request never got a response (network error, timeout).
  int? get statusCode => response.statusCode;

  String get method => _request.method.toUpperCase();

  Uri get uri => _request.uri;

  late final List<MapEntry<String, String>> requestHeaderEntries =
      _headerEntries(_request.headers);

  late final List<MapEntry<String, String>> responseHeaderEntries =
      _headerEntries(response.headers.map);

  late final String? requestHeaders = _headerLines(requestHeaderEntries);

  late final String? requestBody = formatBody(_request.data);

  late final String? responseHeaders = _headerLines(responseHeaderEntries);

  late final String? responseBody = formatBody(response.data);

  /// A shell command that replays the request.
  late final String curl = _buildCurl();

  /// Everything about the request and its response in one block of text.
  late final String fullText = _buildFullText();

  String _buildCurl() {
    final parts = <String>['curl -X $method ${_quote('$uri')}'];
    _request.headers.forEach((key, value) {
      if (value == null) return;
      parts.add('-H ${_quote('$key: ${_headerValue(value)}')}');
    });
    final data = _request.data;
    if (data is FormData) {
      for (final field in data.fields) {
        parts.add('-F ${_quote('${field.key}=${field.value}')}');
      }
      for (final file in data.files) {
        parts.add(
          '-F ${_quote('${file.key}=@${file.value.filename ?? 'file'}')}',
        );
      }
    } else if (data != null) {
      final urlEncoded = (_request.contentType ?? '').contains(
        Headers.formUrlEncodedContentType,
      );
      final body = data is String
          ? data
          : urlEncoded && data is Map<String, dynamic>
          ? Transformer.urlEncodeMap(data, _request.listFormat)
          : _tryJson(data) ?? '$data';
      parts.add('--data-raw ${_quote(body)}');
    }
    return parts.join(' \\\n  ');
  }

  String _buildFullText() {
    final buffer = StringBuffer()
      ..writeln('$method $uri')
      ..writeln('Status: ${statusLabel()}');
    final start = response.startTime;
    final duration = response.duration;
    if (start != null) {
      buffer.writeln(
        'Time: ${start.toUtc().toIso8601String()}'
        '${duration == null ? '' : ' (${duration.inMilliseconds} ms)'}',
      );
    }
    void section(String title, String? body) {
      if (body == null || body.isEmpty) return;
      buffer
        ..writeln()
        ..writeln('--- $title ---')
        ..writeln(body);
    }

    section('Request headers', requestHeaders);
    section('Request body', requestBody);
    section('Response headers', responseHeaders);
    section('Response body', responseBody);
    section('cURL', curl);
    return buffer.toString().trimRight();
  }

  /// "200 OK", or the error message when there was no response.
  String statusLabel() {
    final code = statusCode;
    final message = response.statusMessage;
    if (code == null)
      return 'No response${message == null ? '' : ': $message'}';
    final reason = message == null || message.isEmpty
        ? _reasons[code]
        : message;
    return reason == null ? '$code' : '$code $reason';
  }

  static const Map<int, String> _reasons = <int, String>{
    200: 'OK',
    201: 'Created',
    202: 'Accepted',
    204: 'No Content',
    301: 'Moved Permanently',
    302: 'Found',
    304: 'Not Modified',
    400: 'Bad Request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not Found',
    405: 'Method Not Allowed',
    408: 'Request Timeout',
    409: 'Conflict',
    422: 'Unprocessable Entity',
    429: 'Too Many Requests',
    500: 'Internal Server Error',
    502: 'Bad Gateway',
    503: 'Service Unavailable',
    504: 'Gateway Timeout',
  };

  static String? formatBody(Object? data) {
    if (data == null) return null;
    if (data is String) {
      if (data.isEmpty) return null;
      // Pretty-printing multi-megabyte JSON would stall the UI thread.
      if (data.length > _maxPrettyChars) return data;
      try {
        return _encoder.convert(jsonDecode(data));
      } catch (_) {
        return data;
      }
    }
    if (data is List<int>) return '<binary, ${data.length} bytes>';
    if (data is FormData) {
      return <String>[
        for (final field in data.fields) '${field.key}: ${field.value}',
        for (final file in data.files)
          '${file.key}: <file ${file.value.filename ?? ''}, ${file.value.length} bytes>',
      ].join('\n');
    }
    return _tryJson(data, pretty: true) ?? '$data';
  }

  static String? _tryJson(Object data, {bool pretty = false}) {
    if (data is! Map && data is! List) return null;
    try {
      return pretty ? _encoder.convert(data) : jsonEncode(data);
    } catch (_) {
      return null;
    }
  }

  static List<MapEntry<String, String>> _headerEntries(
    Map<String, dynamic> headers,
  ) => <MapEntry<String, String>>[
    for (final entry in headers.entries)
      if (entry.value != null)
        MapEntry<String, String>(entry.key, _headerValue(entry.value)),
  ];

  static String? _headerLines(List<MapEntry<String, String>> entries) =>
      entries.isEmpty
      ? null
      : entries.map((e) => '${e.key}: ${e.value}').join('\n');

  static String _headerValue(Object value) =>
      value is Iterable ? value.join(', ') : '$value';

  static String _quote(String value) => "'${value.replaceAll("'", r"'\''")}'";
}
