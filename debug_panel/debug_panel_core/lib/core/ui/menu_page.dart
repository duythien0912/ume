import 'package:flutter/material.dart';
import 'package:debug_panel_core/core/pluggable.dart';
import 'package:debug_panel_core/core/store_manager.dart';
import 'package:debug_panel_core/core/ui/panel_action_define.dart';
import 'package:debug_panel_core/core/ui/icon_button.dart';
import 'package:debug_panel_core/core/ui/theme.dart';
import 'package:debug_panel_core/core/ui/tool_tile.dart';
import 'dragable_widget.dart';

/// The expanded panel: every tool in a grid the user can reorder.
class MenuPage extends StatefulWidget {
  const MenuPage({
    super.key,
    this.action,
    this.minimalAction,
    this.closeAction,
  });

  final MenuAction? action;
  final MinimalAction? minimalAction;
  final CloseAction? closeAction;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<Pluggable>? _plugins;

  @override
  void initState() {
    super.initState();
    loadOrderedPlugins().then((plugins) {
      if (mounted) setState(() => _plugins = plugins);
    });
  }

  @override
  Widget build(BuildContext context) {
    final plugins = _plugins;
    return ColoredBox(
      color: DebugPanelColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.bug_report_rounded,
                    size: 24,
                    color: DebugPanelColors.accent,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Debug panel',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: DebugPanelColors.text,
                      ),
                    ),
                  ),
                  DebugPanelIconButton(
                    icon: Icons.close_fullscreen_rounded,
                    tooltip: 'Collapse',
                    onPressed: widget.minimalAction,
                  ),
                  const SizedBox(width: 8),
                  DebugPanelIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    onPressed: widget.closeAction,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Tap a tool to open it. Long-press and drag to reorder.',
                style: TextStyle(
                  fontSize: 13,
                  color: DebugPanelColors.textMuted,
                ),
              ),
            ),
            Expanded(
              child: plugins == null
                  ? const SizedBox.shrink()
                  : plugins.isEmpty
                  ? const Center(
                      child: Text(
                        'No tools registered',
                        style: TextStyle(color: DebugPanelColors.textMuted),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DragableGridView<Pluggable>(
                        plugins,
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        dragCompletion: (dataList) {
                          final names = dataList.map((p) => p.name).toList();
                          PluginStoreManager().storePlugins(names);
                        },
                        itemBuilder: (context, plugin) => ToolTile(
                          pluggable: plugin,
                          iconBoxSize: 72,
                          onTap: () => widget.action?.call(plugin),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
