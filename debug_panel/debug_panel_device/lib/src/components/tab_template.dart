import 'package:flutter/material.dart';
import 'package:debug_panel_core/debug_panel_core.dart';

class ListTileItem {
  final String title;
  final String subtitle;

  const ListTileItem({required this.title, required this.subtitle});
}

/// A tab that loads a list of label and value rows once and shows them.
abstract class TabTemplate extends StatefulWidget {
  const TabTemplate({super.key});

  Future<List<ListTileItem>> getItemList();

  @override
  State<TabTemplate> createState() => _TabTemplateState();
}

class _TabTemplateState extends State<TabTemplate>
    with AutomaticKeepAliveClientMixin {
  late final Future<List<ListTileItem>> _items = widget.getItemList();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<ListTileItem>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Message('Could not read this info:\n${snapshot.error}');
        }
        final items = snapshot.data;
        if (items == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) return const _Message('Nothing to show');
        return ListView.separated(
          padding: EdgeInsets.only(
            top: 4,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
          ),
          itemCount: items.length + 1,
          separatorBuilder: (_, index) => index == 0
              ? const SizedBox.shrink()
              : const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${items.length} items',
                        style: const TextStyle(
                          fontSize: 13,
                          color: DebugPanelColors.textMuted,
                        ),
                      ),
                    ),
                    DebugPanelCopyAction(
                      icon: Icons.copy_all_rounded,
                      label: 'Copy all',
                      text: () => items
                          .map((e) => '${e.title}: ${e.subtitle}')
                          .join('\n'),
                    ),
                  ],
                ),
              );
            }
            return _Row(item: items[index - 1]);
          },
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DebugPanelColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                if (item.subtitle.isEmpty)
                  Text(
                    'Empty',
                    style: debugPanelMonoStyle.copyWith(
                      color: DebugPanelColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  SelectableText(item.subtitle, style: debugPanelMonoStyle),
              ],
            ),
          ),
          if (item.subtitle.isNotEmpty)
            DebugPanelCopyButton(
            tooltip: 'Copy ${item.title}',
            text: () => '${item.title}: ${item.subtitle}',
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: DebugPanelColors.textMuted),
        ),
      ),
    );
  }
}
