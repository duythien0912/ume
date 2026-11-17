///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/8/6 11:25
///
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:debug_panel_core/debug_panel_core.dart';

import '../constants/extensions.dart';
import '../instances.dart';
import '../models/request_text.dart';
import '../pluggable.dart';

/// Longer bodies are cut on screen; copying always gives the full text.
const int _maxShownChars = 20000;

class DioPluggableState extends State<DioInspector> {
  @override
  void initState() {
    super.initState();
    InspectorInstance.httpContainer.addListener(_listener);
  }

  @override
  void dispose() {
    InspectorInstance.httpContainer.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    // Requests can land mid-frame; rebuild on the next microtask instead.
    Future.microtask(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final requests = InspectorInstance.httpContainer.requests;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    return Material(
      color: Colors.black38,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: size.height * 0.85,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: DebugPanelColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Header(count: requests.length),
              const Divider(height: 1),
              Expanded(
                child: requests.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: EdgeInsets.only(bottom: padding.bottom),
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, int index) {
                          final response = requests[index];
                          return _RequestTile(
                            key: ObjectKey(response),
                            response: response,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: <Widget>[
          const Text(
            'Network',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DebugPanelColors.text,
            ),
          ),
          const SizedBox(width: 8),
          _Chip(label: '$count', color: DebugPanelColors.textMuted),
          const Spacer(),
          DebugPanelIconButton(
            icon: Icons.delete_sweep_outlined,
            tooltip: 'Clear',
            onPressed: count == 0
                ? null
                : InspectorInstance.httpContainer.clearRequests,
          ),
          const SizedBox(width: 8),
          const DebugPanelIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Close',
            onPressed: DebugPanel.closeActivatedPlugin,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.wifi_tethering, size: 48, color: DebugPanelColors.textMuted),
          SizedBox(height: 12),
          Text(
            'No requests yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DebugPanelColors.text,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Requests made through Dio show up here.',
            style: TextStyle(fontSize: 13, color: DebugPanelColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatefulWidget {
  const _RequestTile({super.key, required this.response});

  final Response<dynamic> response;

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  late final RequestText _text = RequestText(widget.response);
  bool _expanded = false;

  Color get _statusColor {
    final code = _text.statusCode;
    if (code == null) return DebugPanelColors.danger;
    if (code < 300) return DebugPanelColors.success;
    if (code < 400) return DebugPanelColors.info;
    if (code < 500) return DebugPanelColors.warning;
    return DebugPanelColors.danger;
  }

  String get _subtitle {
    final parts = <String>[_text.uri.host];
    final start = widget.response.startTime;
    if (start != null) parts.add(_hms(start));
    final duration = widget.response.duration;
    if (duration != null) parts.add('${duration.inMilliseconds} ms');
    return parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final uri = _text.uri;
    final path =
        '${uri.path.isEmpty ? '/' : uri.path}'
        '${uri.hasQuery ? '?${uri.query}' : ''}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _expanded ? const Color(0xFFF9FAFB) : DebugPanelColors.surface,
        border: Border(
          left: BorderSide(
            color: _expanded ? DebugPanelColors.accent : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            _Chip(
                              label: _text.method,
                              color: DebugPanelColors.accent,
                            ),
                            const SizedBox(width: 6),
                            _Chip(
                              label: _text.statusCode?.toString() ?? 'ERR',
                              color: _statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          path,
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DebugPanelColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DebugPanelColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DebugPanelCopyButton(
                    tooltip: 'Copy request and response',
                    icon: Icons.copy_all_rounded,
                    color: DebugPanelColors.accent,
                    text: () => _text.fullText,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: DebugPanelColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) _Details(text: _text),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.text});

  final RequestText text;

  @override
  Widget build(BuildContext context) {
    final error = text.statusCode == null ? text.statusLabel() : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DebugPanelCopyAction(
                  icon: Icons.copy_all_rounded,
                  label: 'Copy all',
                  text: () => text.fullText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DebugPanelCopyAction(
                  icon: Icons.terminal_rounded,
                  label: 'Copy cURL',
                  text: () => text.curl,
                ),
              ),
            ],
          ),
          if (error != null) _Section(title: 'Error', body: error),
          _Section(title: 'URL', body: '${text.uri}'),
          _Section(title: 'Request headers', body: text.requestHeaders),
          _Section(title: 'Request body', body: text.requestBody),
          _Section(title: 'Response headers', body: text.responseHeaders),
          _Section(title: 'Response body', body: text.responseBody),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    if (body == null || body.isEmpty) return const SizedBox.shrink();
    final truncated = body.length > _maxShownChars;
    final shown = truncated
        ? body.characters.take(_maxShownChars).toString()
        : body;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DebugPanelColors.text,
                  ),
                ),
              ),
              DebugPanelCopyButton(
                tooltip: 'Copy $title',
                text: () => body,
                size: 18,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DebugPanelColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              truncated
                  ? '$shown\n… '
                        '(${body.length - shown.length} more characters, '
                        'copy to get all)'
                  : body,
              style: debugPanelMonoStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

String _hms(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}:'
    '${t.second.toString().padLeft(2, '0')}';
