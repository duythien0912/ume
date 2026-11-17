import 'package:flutter/material.dart';
import 'package:debug_panel_core/core/pluggable_message_service.dart';
import 'package:debug_panel_core/core/plugin_manager.dart';
import 'package:debug_panel_core/core/red_dot.dart';
import 'package:debug_panel_core/core/store_manager.dart';
import 'package:debug_panel_core/core/ui/panel_shell.dart';
import 'package:debug_panel_core/core/ui/theme.dart';
import 'package:debug_panel_core/core/pluggable.dart';
import 'package:debug_panel_core/util/binding_ambiguate.dart';
import 'package:debug_panel_core/util/constants.dart';
import 'global.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const defaultLocalizationsDelegates = const [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();

/// Wrap your App widget. If [enable] is false, the function will return [child].
class DebugPanel extends StatefulWidget {
  const DebugPanel({
    Key? key,
    required this.child,
    this.enable = true,
    this.supportedLocales,
    this.localizationsDelegates = defaultLocalizationsDelegates,
    this.initialTool = 'DioInspector',
  }) : super(key: key);

  final Widget child;
  final bool enable;
  final Iterable<Locale>? supportedLocales;
  final Iterable<LocalizationsDelegate> localizationsDelegates;

  /// [Pluggable.name] of the tool shown the first time the panel opens (the
  /// first registered tool when none has that name); later opens show the
  /// last used tool.
  final String? initialTool;

  /// Close the panel and the activated plugin, if any.
  ///
  /// Does nothing when the [DebugPanel] is not enabled or nothing is open.
  static void closeActivatedPlugin() {
    _debugPanelState?._contentPageKey.currentState?._close();
  }

  @override
  _DebugPanelState createState() => _DebugPanelState();
}

/// Hold the [_DebugPanelState] as a global variable.
_DebugPanelState? _debugPanelState;

class _DebugPanelState extends State<DebugPanel> {
  _DebugPanelState() {
    // Make sure only a single `DebugPanel` is being used.
    assert(
      _debugPanelState == null,
      'Only one `DebugPanel` can be used at the same time.',
    );
    if (_debugPanelState != null) {
      throw StateError('Only one `DebugPanel` can be used at the same time.');
    }
    _debugPanelState = this;
  }

  final GlobalKey<_ContentPageState> _contentPageKey = GlobalKey();
  bool _overlayEntryInserted = false;
  OverlayEntry _overlayEntry = OverlayEntry(
    builder: (_) => const SizedBox.shrink(),
  );

  @override
  void initState() {
    super.initState();
    _injectOverlay();
  }

  @override
  void dispose() {
    super.dispose();
    // Do the cleaning at last.
    _debugPanelState = null;
  }

  @override
  void didUpdateWidget(DebugPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.enable
        ? PluggableMessageService().resetListener()
        : PluggableMessageService().clearListener();
    if (widget.enable != oldWidget.enable && widget.enable) {
      _injectOverlay();
    }
    if (!widget.enable) {
      _removeOverlay();
    }
  }

  Widget _buildLayout(BuildContext context) {
    return Stack(
      children: <Widget>[
        RepaintBoundary(child: widget.child, key: rootKey),
        // Rebuilds on rotation, keyboard and other window metric changes.
        MediaQuery.fromView(
          view: View.of(context),
          child: Localizations(
            locale: widget.supportedLocales?.first ?? const Locale('en', 'US'),
            delegates: widget.localizationsDelegates.toList(),
            child: ScaffoldMessenger(child: Overlay(key: overlayKey)),
          ),
        ),
      ],
    );
  }

  void _removeOverlay() {
    // Call `remove` only when the entry has been inserted.
    if (_overlayEntryInserted) {
      _overlayEntry.remove();
      _overlayEntryInserted = false;
    }
  }

  void _injectOverlay() {
    bindingAmbiguate(WidgetsBinding.instance)?.addPostFrameCallback((_) {
      if (_overlayEntryInserted) {
        return;
      }
      if (widget.enable) {
        _overlayEntry = OverlayEntry(
          builder: (_) => Theme(
            data: debugPanelTheme,
            child: Material(
              type: MaterialType.transparency,
              child: _ContentPage(
                key: _contentPageKey,
                initialTool: widget.initialTool,
                refreshChildLayout: () => setState(() {}),
              ),
            ),
          ),
        );
        overlayKey.currentState?.insert(_overlayEntry);
        _overlayEntryInserted = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget layout = _buildLayout(context);
    final activated = PluginManager
        .instance
        .pluginsMap[PluginManager.instance.activatedPluggableName];
    if (activated is PluggableWithNestedWidget) {
      layout = activated.buildNestedWidget(layout);
    }
    return Directionality(textDirection: TextDirection.ltr, child: layout);
  }
}

class _ContentPage extends StatefulWidget {
  const _ContentPage({Key? key, this.initialTool, this.refreshChildLayout})
    : super(key: key);

  final String? initialTool;
  final VoidCallback? refreshChildLayout;

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<_ContentPage> {
  final PluginStoreManager _storeManager = PluginStoreManager();
  Size _windowSize = windowSize;
  double _dx = 0;
  double _dy = 0;

  /// Tools in bottom bar order; filled when the panel first opens.
  List<Pluggable> _tools = const <Pluggable>[];
  int _selected = 0;
  bool _panelOpen = false;

  /// A [PluggableWithNestedWidget] wraps the app, so it runs with the panel
  /// closed and the floating button closes it.
  Pluggable? _nestedTool;

  void dragEvent(DragUpdateDetails details) {
    _dx = details.globalPosition.dx - dotSize.width / 2;
    _dy = details.globalPosition.dy - dotSize.height / 2;
    setState(() {});
  }

  void dragEnd(DragEndDetails details) {
    if (_dx + dotSize.width / 2 < _windowSize.width / 2) {
      _dx = margin;
    } else {
      _dx = _windowSize.width - dotSize.width - margin;
    }
    if (_dy + dotSize.height > _windowSize.height) {
      _dy = _windowSize.height - dotSize.height - margin;
    } else if (_dy < 0) {
      _dy = margin;
    }

    _storeManager.storeFloatingDotPos(_dx, _dy);

    setState(() {});
  }

  List<Pluggable> _orderedTools() {
    final tools = PluginManager.instance.pluginsMap.values
        .whereType<Pluggable>()
        .toList();
    final initial = tools.indexWhere((t) => t.name == widget.initialTool);
    if (initial > 0) tools.insert(0, tools.removeAt(initial));
    return tools;
  }

  void _onDotTap() {
    if (_nestedTool != null) {
      _close();
      return;
    }
    final tools = _orderedTools();
    if (tools.isEmpty) return;
    // Keep the last tool across openings while the tool list is unchanged.
    final keep =
        _selected < _tools.length &&
        _selected < tools.length &&
        _tools[_selected].name == tools[_selected].name;
    _tools = tools;
    final first = tools.indexWhere(_opensInPanel);
    if (first < 0) return;
    _panelOpen = true;
    _select(keep && _opensInPanel(tools[_selected]) ? _selected : first);
  }

  static bool _opensInPanel(Pluggable tool) =>
      tool is! PluggableWithAnywhereDoor && tool is! PluggableWithNestedWidget;

  Future<void> _select(int index) async {
    final tool = _tools[index];
    if (tool is PluggableWithAnywhereDoor) {
      _close();
      dynamic result;
      if (tool.routeNameAndArgs != null) {
        result = await tool.navigator?.pushNamed(
          tool.routeNameAndArgs!.item1,
          arguments: tool.routeNameAndArgs!.item2,
        );
      } else if (tool.route != null) {
        result = await tool.navigator?.push(tool.route!);
      }
      tool.popResultReceive(result);
      return;
    }
    if (tool is PluggableWithNestedWidget) {
      _close();
      _nestedTool = tool;
      PluginManager.instance.activatePluggable(tool);
      widget.refreshChildLayout?.call();
      tool.onTrigger();
      setState(() {});
      return;
    }
    PluggableMessageService().resetCounter(tool);
    setState(() => _selected = index);
    PluginManager.instance.activatePluggable(tool);
    tool.onTrigger();
  }

  @override
  void dispose() {
    // Don't leave a tool wrapping the app once the panel is gone.
    final active = _nestedTool ?? (_panelOpen ? _tools[_selected] : null);
    if (active != null) PluginManager.instance.deactivatePluggable(active);
    super.dispose();
  }

  void _close() {
    final active = _nestedTool ?? (_panelOpen ? _tools[_selected] : null);
    if (active != null) PluginManager.instance.deactivatePluggable(active);
    if (_nestedTool != null) {
      _nestedTool = null;
      widget.refreshChildLayout?.call();
    }
    if (mounted) setState(() => _panelOpen = false);
  }

  @override
  void initState() {
    super.initState();
    _storeManager.fetchFloatingDotPos().then((value) {
      if (value == null || value.split(',').length != 2) {
        return;
      }
      final x = double.parse(value.split(',').first);
      final y = double.parse(value.split(',').last);
      if (!mounted ||
          MediaQuery.of(context).size.height - dotSize.height < y ||
          MediaQuery.of(context).size.width - dotSize.width < x) {
        return;
      }
      _dx = x;
      _dy = y;
      setState(() {});
    });
    _dx = _windowSize.width - dotSize.width - margin * 4;
    _dy = _windowSize.height - dotSize.height - bottomDistance;
  }

  @override
  Widget build(BuildContext context) {
    if (_windowSize.isEmpty) {
      _dx = MediaQuery.of(context).size.width - dotSize.width - margin * 4;
      _dy =
          MediaQuery.of(context).size.height - dotSize.height - bottomDistance;
      _windowSize = MediaQuery.of(context).size;
    }
    final nestedOpen = _nestedTool != null;
    return SizedBox(
      width: _windowSize.width,
      height: _windowSize.height,
      child: Stack(
        children: <Widget>[
          if (_panelOpen)
            Positioned.fill(
              child: PanelShell(
                tools: _tools,
                selected: _selected,
                onSelect: _select,
                onClose: _close,
              ),
            ),
          if (!_panelOpen)
            Positioned(
              left: _dx,
              top: _dy,
              child: Tooltip(
                message: nestedOpen ? 'Close tool' : 'Open debug panel',
                child: GestureDetector(
                  onTap: _onDotTap,
                  onVerticalDragEnd: dragEnd,
                  onHorizontalDragEnd: dragEnd,
                  onHorizontalDragUpdate: dragEvent,
                  onVerticalDragUpdate: dragEvent,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: nestedOpen
                          ? DebugPanelColors.accent
                          : DebugPanelColors.fab,
                      border: Border.all(
                        color: DebugPanelColors.accent,
                        width: 2,
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x59000000),
                          offset: Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    width: dotSize.width,
                    height: dotSize.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Icon(
                            nestedOpen
                                ? Icons.close_rounded
                                : Icons.bug_report_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: RedDot(
                            pluginDatas: PluginManager
                                .instance
                                .pluginsMap
                                .values
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
