import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/constants.dart';
import '../constants/extensions.dart';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');
const int _maxPrettyChars = 512 * 1024;

/// Bodies bigger than this are measured and formatted on a background
/// isolate instead of the UI thread.
const int _bigChars = 32 * 1024;
const int _bigNodes = 2000;

/// A formatted body and its size on the wire, when known.
class BodyText {
  const BodyText(this.text, this.bytes);

  final String text;
  final int? bytes;
}

/// One body, measured and formatted once: on a background isolate when
/// big, or right away when small or copied first.
class _LazyBody {
  _LazyBody(this.data);

  final Object? data;
  late final bool _big = RequestText._isBig(data);

  /// Known without formatting for small bodies; null for big ones.
  late final int? quickBytes = _big ? null : RequestText._size(data);

  BodyText? _done;
  Future<BodyText?>? _pending;

  FutureOr<BodyText?> load() {
    final done = _done;
    if (done != null) return done;
    if (!_big) {
      return _done = _withSize(RequestText.formatBody(data), quickBytes);
    }
    // Data that can't cross isolates (files, native handles) is formatted here.
    return _pending ??= compute(RequestText.formatBodyWithSize, data)
        .catchError((Object _) => RequestText.formatBodyWithSize(data))
        .then((body) => _done ??= body);
  }

  static BodyText? _withSize(String? text, int? bytes) =>
      text == null ? null : BodyText(text, bytes);
}

/// Text forms of one recorded request, for display and copying.
class RequestText {
  RequestText(this.response);

  static final Expando<RequestText> _cache = Expando<RequestText>();
  static final Expando<({String error, String? trace})> _errors =
      Expando<({String error, String? trace})>();

  /// Keeps the Dio error's type, cause and call site behind [response].
  static void recordError(Response<dynamic> response, DioException e) {
    // Dio points the trace at the app code that sent the request.
    final trace = '${e.stackTrace}'.trimRight();
    _errors[response] = (
      error: <String>[
        '${e.type.name}${e.message == null ? '' : ': ${e.message}'}',
        if (e.error != null) 'Cause: ${e.error}',
      ].join('\n'),
      trace: trace.isEmpty ? null : trace,
    );
  }

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

  late final _LazyBody _requestBody = _LazyBody(_request.data);
  late final _LazyBody _responseBody = _LazyBody(response.data);

  bool get hasRequestBody => _hasData(_request.data);

  bool get hasResponseBody => _hasData(response.data);

  /// Decoded size when known without formatting; null for big bodies.
  int? get requestBytes => _requestBody.quickBytes;

  /// Decoded size; the Content-Length header (often compressed) is the
  /// fallback for big bodies until they are formatted.
  late final int? responseBytes =
      _responseBody.quickBytes ??
      int.tryParse(response.headers.value(Headers.contentLengthHeader) ?? '');

  /// The formatted request body; big ones are formatted off the UI thread.
  FutureOr<BodyText?> requestBodyText() => _requestBody.load();

  FutureOr<BodyText?> responseBodyText() => _responseBody.load();

  /// Dio's error type, message and underlying cause; null on success.
  String? get error =>
      _errors[response]?.error ??
      (statusCode == null ? response.statusMessage : null);

  /// Where a failed request was sent from; null on success.
  String? get stackTrace => _errors[response]?.trace;

  /// The URL the response finally came from, when redirects changed it.
  late final Uri? finalUri = _buildFinalUri();

  /// One line per redirect followed, or null when there were none.
  late final String? redirects = response.redirects.isEmpty
      ? null
      : response.redirects
            .map((r) => '${r.statusCode} ${r.method} ${r.location}')
            .join('\n');

  /// Request settings beyond headers and body, one `name: value` per line.
  late final String options = _buildOptions();

  late final String? responseHeaders = _headerLines(responseHeaderEntries);

  /// A shell command that replays the request. Built on demand, so the
  /// body isn't kept twice.
  String get curl => _buildCurl();

  /// Everything about the request and its response in one block of text;
  /// big bodies are formatted off the UI thread first.
  Future<String> fullText() async {
    final request = await requestBodyText();
    final response = await responseBodyText();
    return _buildFullText(request?.text, response?.text);
  }

  Uri? _buildFinalUri() {
    // A redirect location can be relative to the request URL.
    final real = uri.resolveUri(response.realUri);
    return real.toString() == uri.toString() ? null : real;
  }

  String _buildOptions() {
    final o = _request;
    final extra = <String, dynamic>{
      for (final entry in o.extra.entries)
        if (!_ownExtras.contains(entry.key)) entry.key: entry.value,
    };
    return <String>[
      'baseUrl: ${o.baseUrl.isEmpty ? '-' : o.baseUrl}',
      'path: ${o.path}',
      'queryParameters: ${_tryJson(o.queryParameters) ?? o.queryParameters}',
      'contentType: ${o.contentType ?? '-'}',
      'responseType: ${o.responseType.name}',
      'connectTimeout: ${_ms(o.connectTimeout)}',
      'sendTimeout: ${_ms(o.sendTimeout)}',
      'receiveTimeout: ${_ms(o.receiveTimeout)}',
      'followRedirects: ${o.followRedirects} (max ${o.maxRedirects})',
      'persistentConnection: ${o.persistentConnection}',
      'listFormat: ${o.listFormat.name}',
      if (extra.isNotEmpty) 'extra: ${_tryJson(extra) ?? extra}',
      'isRedirect: ${response.isRedirect}',
      if (response.extra.isNotEmpty)
        'responseExtra: ${_tryJson(response.extra) ?? response.extra}',
    ].join('\n');
  }

  static const Set<String> _ownExtras = <String>{
    DIO_EXTRA_START_TIME,
    DIO_EXTRA_END_TIME,
  };

  static String _ms(Duration? d) => d == null ? '-' : '${d.inMilliseconds} ms';

  String _buildCurl() {
    final parts = <String>['curl -X $method ${_quote('$uri')}'];
    for (final header in requestHeaderEntries) {
      parts.add('-H ${_quote('${header.key}: ${header.value}')}');
    }
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
    } else if (data is List<int> && _text(data) == null) {
      parts.add('--data-binary @body.bin');
    } else if (data != null) {
      final urlEncoded = (_request.contentType ?? '').contains(
        Headers.formUrlEncodedContentType,
      );
      final body = data is String
          ? data
          : data is List<int>
          ? _text(data)!
          : urlEncoded && data is Map<String, dynamic>
          ? Transformer.urlEncodeMap(data, _request.listFormat)
          : _tryJson(data) ?? '$data';
      parts.add('--data-raw ${_quote(body)}');
    }
    parts.add('--compressed');
    return parts.join(' \\\n  ');
  }

  String _buildFullText(String? requestBody, String? responseBody) {
    final buffer = StringBuffer()
      ..writeln('$method $uri')
      ..writeln('Status: ${statusLabel()}');
    final start = response.startTime;
    final end = response.endTime;
    if (start != null) {
      buffer.writeln(
        'Time: ${start.toUtc().toIso8601String()}'
        '${end == null ? '' : ' → ${end.toUtc().toIso8601String()} '
                  '(${response.duration!.inMilliseconds} ms)'}',
      );
    }
    if (finalUri != null) buffer.writeln('Final URL: $finalUri');
    final requestSize = requestBytes;
    final responseSize = responseBytes;
    if (requestSize != null) buffer.writeln('Request size: $requestSize bytes');
    if (responseSize != null) {
      buffer.writeln('Response size: $responseSize bytes');
    }
    void section(String title, String? body) {
      if (body == null || body.isEmpty) return;
      buffer
        ..writeln()
        ..writeln('--- $title ---')
        ..writeln(body);
    }

    section('Error', error);
    section('Redirects', redirects);
    section('Options', options);
    section('Request headers', requestHeaders);
    section('Request body', requestBody);
    section('Response headers', responseHeaders);
    section('Response body', responseBody);
    section('Stack trace', stackTrace);
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

  static bool _hasData(Object? data) =>
      data != null &&
      !(data is String && data.isEmpty) &&
      !(data is List<int> && data.isEmpty);

  /// Exact decoded size in bytes, or null when it can't be measured.
  static int? _size(Object? data) {
    if (data is String) return data.isEmpty ? null : utf8.encode(data).length;
    if (data is List<int>) return data.length;
    if (data is FormData) return data.length;
    if (data is Map || data is List) {
      try {
        return JsonUtf8Encoder().convert(data).length;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Whether measuring or formatting [data] could stall the UI thread:
  /// many JSON nodes, or long strings, even inside a small map.
  static bool _isBig(Object? data) {
    if (data is String) return data.length > _bigChars;
    // Bytes are only labelled, never walked.
    if (data is List<int> || (data is! Map && data is! List)) return false;
    var nodes = 0;
    var chars = 0;
    final stack = <Object?>[data];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      if (++nodes >= _bigNodes) return true;
      if (node is String && (chars += node.length) > _bigChars) return true;
      // Push only as many children as could still fit under the limit.
      final children = node is Map
          ? node.values
          : node is List
          ? node
          : const <Object?>[];
      stack.addAll(children.take(_bigNodes - nodes));
    }
    return false;
  }

  /// [formatBody] plus the body's size; runs on a background isolate too.
  static BodyText? formatBodyWithSize(Object? data) {
    final text = formatBody(data);
    if (text == null) return null;
    return BodyText(text, _size(data));
  }

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
    if (data is List<int>) return _text(data) ?? _hexDump(data);
    if (data is FormData) {
      return <String>[
        for (final field in data.fields) '${field.key}: ${field.value}',
        for (final file in data.files)
          '${file.key}: <file ${file.value.filename ?? ''}, ${file.value.length} bytes>',
      ].join('\n');
    }
    return _tryJson(data, pretty: true) ?? '$data';
  }

  /// [bytes] as text when they are UTF-8 without control characters.
  static String? _text(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > _maxPrettyChars) return null;
    try {
      final text = utf8.decode(bytes);
      return text.contains(_controlChars) ? null : formatBody(text);
    } on FormatException {
      return null;
    }
  }

  static final RegExp _controlChars = RegExp(r'[\x00-\x08\x0E-\x1F]');

  /// The first bytes as hex and ASCII, 16 per line.
  static String _hexDump(List<int> bytes) {
    const shown = 256;
    final lines = <String>['<binary, ${bytes.length} bytes>'];
    for (var i = 0; i < bytes.length && i < shown; i += 16) {
      final row = bytes.sublist(
        i,
        i + 16 > bytes.length ? bytes.length : i + 16,
      );
      final hex = row.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      final ascii = String.fromCharCodes(
        row.map((b) => b >= 0x20 && b < 0x7F ? b : 0x2E),
      );
      lines.add(
        '${i.toRadixString(16).padLeft(4, '0')}  ${hex.padRight(47)}  $ascii',
      );
    }
    if (bytes.length > shown) lines.add('… ${bytes.length - shown} more bytes');
    return lines.join('\n');
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
    // One line per value, as on the wire (e.g. repeated set-cookie).
    for (final entry in headers.entries)
      if (entry.value is Iterable)
        for (final value in entry.value as Iterable)
          MapEntry<String, String>(entry.key, '$value')
      else if (entry.value != null)
        MapEntry<String, String>(entry.key, '${entry.value}'),
  ];

  static String? _headerLines(List<MapEntry<String, String>> entries) =>
      entries.isEmpty
      ? null
      : entries.map((e) => '${e.key}: ${e.value}').join('\n');

  static String _quote(String value) => "'${value.replaceAll("'", r"'\''")}'";
}
