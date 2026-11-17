import 'package:flutter/material.dart';
import 'package:debug_panel_core/debug_panel_core.dart';

class ListTileItem {
  final String title;
  final String subtitle;

  const ListTileItem({required this.title, required this.subtitle});
}

/// A section that opens and closes; its rows load the first time it opens.
abstract class TabTemplate extends StatefulWidget {
  const TabTemplate({super.key});

  String get title;

  bool get initiallyOpen => false;

  Future<List<ListTileItem>> getItemList();

  @override
  State<TabTemplate> createState() => _TabTemplateState();
}

class _TabTemplateState extends State<TabTemplate> {
  late bool _open = widget.initiallyOpen;
  Future<List<ListTileItem>>? _items;

  @override
  Widget build(BuildContext context) {
    if (_open) _items ??= widget.getItemList();
    return FutureBuilder<List<ListTileItem>>(
      future: _items,
      builder: (context, snapshot) {
        final items = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            InkWell(
              // Closing drops the result, so reopening reads fresh values.
              onTap: () => setState(() {
                _open = !_open;
                if (!_open) _items = null;
              }),
              child: SizedBox(
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 12),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        _open
                            ? Icons.expand_more_rounded
                            : Icons.chevron_right_rounded,
                        size: 20,
                        color: DebugPanelColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: DebugPanelColors.text,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (items != null)
                        Text(
                          '${items.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: DebugPanelColors.textMuted,
                          ),
                        ),
                      const Spacer(),
                      if (_open && items != null && items.isNotEmpty)
                        DebugPanelCopyButton(
                          tooltip: 'Copy ${widget.title.toLowerCase()} info',
                          size: 15,
                          dense: true,
                          text: () => items
                              .map((e) => '${e.title}: ${e.subtitle}')
                              .join('\n'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (_open)
              if (snapshot.hasError)
                _Message('Could not read this info: ${snapshot.error}')
              else if (items == null)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (items.isEmpty)
                const _Message('Nothing to show')
              else
                for (final item in items) _Row(item: item),
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final ListTileItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => debugPanelCopy(
        context,
        '${item.title}: ${item.subtitle}',
        message: 'Copied ${humanize(item.title)}',
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 5, 12, 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Text(
                humanize(item.title),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: DebugPanelColors.textMuted,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                item.subtitle.isEmpty ? '—' : item.subtitle,
                style: debugPanelMonoStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const Map<String, String> _acronyms = <String, String>{
  'os': 'OS',
  'cpu': 'CPU',
  'cpus': 'CPUs',
  'id': 'ID',
  'ip': 'IP',
  'url': 'URL',
  'sdk': 'SDK',
  'ssid': 'SSID',
  'bssid': 'BSSID',
  'abi': 'ABI',
  'abis': 'ABIs',
};

/// "systemGUID" → "System GUID", "Platform Version" → "Platform version".
String humanize(String key) {
  final words = key
      .replaceAll('_', ' ')
      .split(RegExp(r'(?<=[a-z0-9])(?=[A-Z])|\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return key;
  return <String>[
    for (var i = 0; i < words.length; i++)
      words[i] == words[i].toUpperCase() && words[i].length > 1
          ? words[i]
          : _acronyms.containsKey(words[i].toLowerCase())
              ? _acronyms[words[i].toLowerCase()]!
              : i == 0
                  ? '${words[i][0].toUpperCase()}${words[i].substring(1).toLowerCase()}'
                  : words[i].toLowerCase(),
  ].join(' ');
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 4, 12, 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: DebugPanelColors.textMuted),
      ),
    );
  }
}
