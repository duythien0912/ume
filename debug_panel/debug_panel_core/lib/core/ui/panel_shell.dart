import 'package:flutter/material.dart';
import 'package:debug_panel_core/core/pluggable.dart';
import 'package:debug_panel_core/core/red_dot.dart';
import 'package:debug_panel_core/core/ui/icon_button.dart';
import 'package:debug_panel_core/core/ui/theme.dart';

/// Height of the sheet when collapsed, as a share of the screen.
const double _collapsedShare = 0.72;

/// The open panel: a bottom sheet with a tool switcher, which can be
/// expanded to full height or collapsed again.
class PanelShell extends StatefulWidget {
  const PanelShell({
    super.key,
    required this.tools,
    required this.selected,
    required this.onSelect,
    required this.onClose,
  });

  final List<Pluggable> tools;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  @override
  State<PanelShell> createState() => _PanelShellState();
}

class _PanelShellState extends State<PanelShell> {
  /// Tools are built the first time they are shown and then kept alive.
  final Set<int> _built = <int>{};
  bool _expanded = false;

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -200) {
      setState(() => _expanded = true);
    } else if (velocity > 200) {
      _expanded ? setState(() => _expanded = false) : widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    _built.add(widget.selected);
    final media = MediaQuery.of(context);
    final height = _expanded
        ? media.size.height - media.padding.top
        : media.size.height * _collapsedShare;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: const ColoredBox(color: Color(0x66000000)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: DebugPanelColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(top: BorderSide(color: DebugPanelColors.border)),
              ),
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragEnd: _onDragEnd,
                      child: _Header(
                        tools: widget.tools,
                        selected: widget.selected,
                        expanded: _expanded,
                        onSelect: widget.onSelect,
                        onToggle: () => setState(() => _expanded = !_expanded),
                        onClose: widget.onClose,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: IndexedStack(
                        index: widget.selected,
                        children: <Widget>[
                          for (var i = 0; i < widget.tools.length; i++)
                            _built.contains(i)
                                ? widget.tools[i].buildWidget(context) ??
                                      const SizedBox.shrink()
                                : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tools,
    required this.selected,
    required this.expanded,
    required this.onSelect,
    required this.onToggle,
    required this.onClose,
  });

  final List<Pluggable> tools;
  final int selected;
  final bool expanded;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        children: <Widget>[
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: DebugPanelColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (var i = 0; i < tools.length; i++)
                        _ToolChip(
                          tool: tools[i],
                          selected: i == selected,
                          onTap: () => onSelect(i),
                        ),
                    ],
                  ),
                ),
              ),
              DebugPanelIconButton(
                icon: expanded
                    ? Icons.unfold_less_rounded
                    : Icons.unfold_more_rounded,
                tooltip: expanded ? 'Collapse' : 'Expand',
                onPressed: onToggle,
              ),
              const SizedBox(width: 6),
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

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.tool,
    required this.selected,
    required this.onTap,
  });

  final Pluggable tool;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? DebugPanelColors.surfaceMuted
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? DebugPanelColors.border : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  tool.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? DebugPanelColors.text
                        : DebugPanelColors.textMuted,
                  ),
                ),
                RedDot(pluginDatas: <Pluggable>[tool], size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
