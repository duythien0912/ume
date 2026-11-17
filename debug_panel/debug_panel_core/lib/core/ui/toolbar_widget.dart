import 'dart:math';

import 'package:flutter/material.dart';
import 'package:debug_panel_core/core/pluggable.dart';
import 'package:debug_panel_core/core/store_manager.dart';
import 'package:debug_panel_core/core/ui/panel_action_define.dart';
import 'package:debug_panel_core/core/ui/icon_button.dart';
import 'package:debug_panel_core/core/ui/theme.dart';
import 'package:debug_panel_core/core/ui/tool_tile.dart';

const double _contentHeight = 160;

/// The compact panel: a bottom sheet with the tool row, draggable up and down.
class ToolBarWidget extends StatefulWidget {
  const ToolBarWidget({
    super.key,
    this.action,
    this.maximalAction,
    this.closeAction,
  });

  final MenuAction? action;
  final CloseAction? closeAction;
  final MaximalAction? maximalAction;

  @override
  State<ToolBarWidget> createState() => _ToolBarWidgetState();
}

class _ToolBarWidgetState extends State<ToolBarWidget> {
  /// Distance from the bottom of the screen; 0 keeps the sheet docked.
  double _lift = 0;
  List<Pluggable> _plugins = const <Pluggable>[];

  @override
  void initState() {
    super.initState();
    loadOrderedPlugins().then((plugins) {
      if (mounted) setState(() => _plugins = plugins);
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final bottomInset = padding.bottom;
    final height = _contentHeight + bottomInset;
    final maxLift =
        max(0.0, MediaQuery.sizeOf(context).height - height - padding.top);
    final lift = min(_lift, maxLift);
    return Positioned(
      left: 0,
      right: 0,
      bottom: lift,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: DebugPanelColors.surface,
          borderRadius: lift > 0
              ? BorderRadius.circular(20)
              : const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 16,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) => setState(() {
                _lift = (lift - details.delta.dy).clamp(0.0, maxLift);
              }),
              child: _Header(
                onExpand: widget.maximalAction,
                onClose: widget.closeAction,
              ),
            ),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                itemCount: _plugins.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final plugin = _plugins[index];
                  return SizedBox(
                    width: 76,
                    child: ToolTile(
                      pluggable: plugin,
                      onTap: () => widget.action?.call(plugin),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onExpand, this.onClose});

  final VoidCallback? onExpand;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      child: Column(
        children: <Widget>[
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: DebugPanelColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(
                Icons.bug_report_rounded,
                size: 20,
                color: DebugPanelColors.accent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Debug panel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DebugPanelColors.text,
                  ),
                ),
              ),
              DebugPanelIconButton(
                icon: Icons.open_in_full_rounded,
                tooltip: 'Expand',
                onPressed: onExpand,
              ),
              const SizedBox(width: 8),
              DebugPanelIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Close',
                onPressed: onClose,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
