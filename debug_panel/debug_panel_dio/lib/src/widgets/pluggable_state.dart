import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:debug_panel_core/debug_panel_core.dart';

import '../constants/extensions.dart';
import '../instances.dart';
import '../models/request_text.dart';
import '../pluggable.dart';
import 'code_view.dart';

class DioPluggableState extends State<DioInspector> {
  /// The one request shown expanded; opening another collapses it.
  Response<dynamic>? _expanded;

  /// The list as it was when [_expanded] opened, so new requests don't push
  /// the open one away while it is being read.
  List<Response<dynamic>>? _frozen;

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
    final all = InspectorInstance.httpContainer.requests;
    final requests = _frozen ?? all;
    final waiting = all.length - requests.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  waiting > 0
                      ? '${requests.length} requests · $waiting new'
                      : '${requests.length} requests',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DebugPanelColors.textMuted,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: all.isEmpty
                    ? null
                    : () {
                        setState(() => _expanded = _frozen = null);
                        InspectorInstance.httpContainer.clearRequests();
                      },
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: DebugPanelColors.text,
                  disabledForegroundColor: DebugPanelColors.border,
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: requests.isEmpty
              ? const EmptyHint(
                  'No requests yet. Dio calls show up here.',
                  icon: Icons.wifi_tethering_rounded,
                )
              : ListView.separated(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 8,
                  ),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, int index) {
                    final response = requests[index];
                    final expanded = identical(response, _expanded);
                    return _RequestRow(
                      key: ObjectKey(response),
                      response: response,
                      expanded: expanded,
                      onTap: (rowContext) {
                        setState(() {
                          _expanded = expanded ? null : response;
                          _frozen = expanded ? null : List.of(all);
                        });
                        if (expanded) return;
                        // Bring the opened request to the top of the sheet.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (rowContext.mounted) {
                            Scrollable.ensureVisible(
                              rowContext,
                              duration: const Duration(milliseconds: 200),
                            );
                          }
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    super.key,
    required this.response,
    required this.expanded,
    required this.onTap,
  });

  final Response<dynamic> response;
  final bool expanded;
  final ValueChanged<BuildContext> onTap;

  @override
  Widget build(BuildContext context) {
    final text = RequestText.of(response);
    final uri = text.uri;
    final start = response.startTime;
    final duration = response.duration;
    return Container(
      decoration: BoxDecoration(
        color: expanded ? DebugPanelColors.surface : null,
        border: Border(
          left: BorderSide(
            color: expanded ? DebugPanelColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: () => onTap(context),
            onLongPress: () => debugPanelCopy(
              context,
              text.fullText,
              message: 'Copied request and response',
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Tag(
                      label: text.method,
                      color: DebugPanelColors.method(text.method),
                      width: 58,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${uri.path.isEmpty ? '/' : uri.path}'
                          '${uri.hasQuery ? '?${uri.query}' : ''}',
                          maxLines: expanded ? null : 1,
                          overflow: expanded ? null : TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DebugPanelColors.text,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              TextSpan(
                                text: text.statusCode == null
                                    ? 'Failed'
                                    : text.statusLabel(),
                                style: TextStyle(
                                  color: DebugPanelColors.status(
                                    text.statusCode,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (duration != null)
                                TextSpan(
                                  text: '  ·  ${duration.inMilliseconds} ms',
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: DebugPanelColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (start != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 1),
                      child: Text(
                        hms(start),
                        style: const TextStyle(
                          fontSize: 11,
                          color: DebugPanelColors.textMuted,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (expanded) _Details(text: text),
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
    final error = text.statusCode == null ? text.response.statusMessage : null;
    final start = text.response.startTime;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (error != null) _Field(label: 'Error', value: error, danger: true),
          _Field(label: 'URL', value: '${text.uri}'),
          Row(
            children: <Widget>[
              Expanded(
                child: start == null
                    ? const SizedBox.shrink()
                    : _Field(label: 'Started', value: dateTime(start)),
              ),
              DebugPanelCopyButton(
                tooltip: 'Copy request and response',
                icon: Icons.copy_all_rounded,
                size: 17,
                dense: true,
                color: DebugPanelColors.text,
                text: () => text.fullText,
              ),
              DebugPanelCopyButton(
                tooltip: 'Copy as cURL',
                icon: Icons.terminal_rounded,
                size: 17,
                dense: true,
                color: DebugPanelColors.text,
                text: () => text.curl,
              ),
            ],
          ),
          _Section(
            title: 'Request headers',
            count: text.requestHeaderEntries.length,
            body: text.requestHeaders,
            headers: true,
          ),
          _Section(title: 'Request body', body: text.requestBody),
          _Section(
            title: 'Response headers',
            count: text.responseHeaderEntries.length,
            body: text.responseHeaders,
            headers: true,
          ),
          _Section(
            title: 'Response body',
            body: text.responseBody,
            initiallyOpen: true,
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.danger = false});

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: DebugPanelColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: debugPanelMonoStyle.copyWith(
                color: danger ? DebugPanelColors.danger : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled block that opens and closes, with a copy button.
class _Section extends StatefulWidget {
  const _Section({
    required this.title,
    required this.body,
    this.count,
    this.headers = false,
    this.initiallyOpen = false,
  });

  final String title;
  final String? body;
  final int? count;
  final bool headers;
  final bool initiallyOpen;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  late bool _open = widget.initiallyOpen;

  /// Reused so list rebuilds don't re-tokenize a large body.
  late final Widget _block = CodeBlock(
    text: widget.body!,
    headers: widget.headers,
  );

  @override
  Widget build(BuildContext context) {
    final body = widget.body;
    if (body == null || body.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 34,
            child: Row(
              children: <Widget>[
                Icon(
                  _open
                      ? Icons.expand_more_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                  color: DebugPanelColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: DebugPanelColors.text,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.count == null ? '' : '${widget.count}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DebugPanelColors.textMuted,
                  ),
                ),
                const Spacer(),
                DebugPanelCopyButton(
                  tooltip: 'Copy ${widget.title.toLowerCase()}',
                  size: 15,
                  dense: true,
                  text: () => body,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(padding: const EdgeInsets.only(bottom: 4), child: _block),
      ],
    );
  }
}

String hms(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}:'
    '${t.second.toString().padLeft(2, '0')}';

String dateTime(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${hms(t)}'
      '.${t.millisecond.toString().padLeft(3, '0')}';
}
