import 'package:flutter/material.dart';
import 'package:debug_panel_core/core/pluggable_message_service.dart';
import 'package:debug_panel_core/core/ui/panel_action_define.dart';
import 'package:debug_panel_core/core/plugin_manager.dart';
import 'package:debug_panel_core/core/red_dot.dart';
import 'package:debug_panel_core/core/store_manager.dart';
import 'package:debug_panel_core/core/ui/theme.dart';
import 'package:debug_panel_core/core/ui/toolbar_widget.dart';
import 'package:debug_panel_core/core/pluggable.dart';
import 'package:debug_panel_core/util/binding_ambiguate.dart';
import 'package:debug_panel_core/util/constants.dart';
import './menu_page.dart';
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
  }) : super(key: key);

  final Widget child;
  final bool enable;
  final Iterable<Locale>? supportedLocales;
  final Iterable<LocalizationsDelegate> localizationsDelegates;

  /// Close the activated plugin if any.
  ///
  /// The method does not have side-effects whether the [DebugPanel]
  /// is not enabled or no plugin has been activated.
  static void closeActivatedPlugin() {
    final _ContentPageState? state =
        _debugPanelState?._contentPageKey.currentState;
    if (state?._currentSelected != null) {
      state?._closeActivatedPluggable();
    }
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
    final activated = PluginManager.instance.pluginsMap[
        PluginManager.instance.activatedPluggableName];
    if (activated is PluggableWithNestedWidget) {
      layout = activated.buildNestedWidget(layout);
    }
    return Directionality(textDirection: TextDirection.ltr, child: layout);
  }
}

class _ContentPage extends StatefulWidget {
  const _ContentPage({Key? key, this.refreshChildLayout}) : super(key: key);

  final VoidCallback? refreshChildLayout;

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<_ContentPage> {
  PluginStoreManager _storeManager = PluginStoreManager();
  Size _windowSize = windowSize;
  double _dx = 0;
  double _dy = 0;
  bool _showedMenu = false;
  Pluggable? _currentSelected;
  Widget _empty = Container();
  Widget? _currentWidget;
  Widget? _menuPage;
  BuildContext? _context;

  bool _minimalContent = true;
  Widget? _toolbarWidget;

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

  void onTap() {
    if (_currentSelected != null) {
      _closeActivatedPluggable();
      return;
    }
    _showedMenu = !_showedMenu;
    _updatePanelWidget();
  }

  void _closeActivatedPluggable() {
    PluginManager.instance.deactivatePluggable(_currentSelected!);
    if (widget.refreshChildLayout != null) {
      widget.refreshChildLayout!();
    }
    _currentSelected = null;
    _currentWidget = _empty;
    if (_minimalContent) {
      _currentWidget = _toolbarWidget;
      _showedMenu = true;
    }
    setState(() {});
  }

  void _updatePanelWidget() {
    setState(() {
      _currentWidget = _showedMenu
          ? (_minimalContent ? _toolbarWidget : _menuPage)
          : _empty;
    });
  }

  void _handleAction(BuildContext? context, Pluggable data) {
    _currentWidget = data.buildWidget(context);
    setState(() {
      _showedMenu = false;
    });
  }

  Widget _logoWidget() {
    final pluginOpen = _currentSelected != null;
    return Icon(
      pluginOpen ? Icons.close_rounded : Icons.bug_report_rounded,
      size: 22,
      color: Colors.white,
    );
  }

  @override
  void dispose() {
    super.dispose();
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
      if (MediaQuery.of(context).size.height - dotSize.height < y ||
          MediaQuery.of(context).size.width - dotSize.width < x) {
        return;
      }
      _dx = x;
      _dy = y;
      setState(() {});
    });
    _storeManager.fetchMinimalToolbarSwitch().then((value) {
      setState(() {
        _minimalContent = value ?? true;
      });
    });
    _dx = _windowSize.width - dotSize.width - margin * 4;
    _dy = _windowSize.height - dotSize.height - bottomDistance;
    MenuAction itemTapAction = (pluginData) async {
      if (pluginData is PluggableWithAnywhereDoor) {
        dynamic result;
        if (pluginData.routeNameAndArgs != null) {
          result = await pluginData.navigator?.pushNamed(
            pluginData.routeNameAndArgs!.item1,
            arguments: pluginData.routeNameAndArgs!.item2,
          );
        } else if (pluginData.route != null) {
          result = await pluginData.navigator?.push(pluginData.route!);
        }
        pluginData.popResultReceive(result);
      } else {
        _currentSelected = pluginData;
        if (_currentSelected != null) {
          PluginManager.instance.activatePluggable(_currentSelected!);
        }
        _handleAction(_context, pluginData!);
        if (widget.refreshChildLayout != null) {
          widget.refreshChildLayout!();
        }
        pluginData.onTrigger();
      }
    };
    _menuPage = MenuPage(
      action: itemTapAction,
      minimalAction: () {
        _minimalContent = true;
        _updatePanelWidget();
        PluginStoreManager().storeMinimalToolbarSwitch(true);
      },
      closeAction: () {
        _showedMenu = false;
        _updatePanelWidget();
      },
    );
    _toolbarWidget = ToolBarWidget(
      action: itemTapAction,
      maximalAction: () {
        _minimalContent = false;
        _updatePanelWidget();
        PluginStoreManager().storeMinimalToolbarSwitch(false);
      },
      closeAction: () {
        _showedMenu = false;
        _updatePanelWidget();
      },
    );
    _currentWidget = _empty;
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    if (_windowSize.isEmpty) {
      _dx = MediaQuery.of(context).size.width - dotSize.width - margin * 4;
      _dy =
          MediaQuery.of(context).size.height - dotSize.height - bottomDistance;
      _windowSize = MediaQuery.of(context).size;
    }
    return Container(
      width: _windowSize.width,
      height: _windowSize.height,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          _currentWidget!,
          // Panels and tools with their own close button hide the dot.
          if (!_showedMenu && _currentSelected is! PluggableWithCloseButton)
            Positioned(
              left: _dx,
              top: _dy,
              child: Tooltip(
                message: _currentSelected != null
                    ? 'Close tool'
                    : 'Open debug panel',
                child: GestureDetector(
                  onTap: onTap,
                  onVerticalDragEnd: dragEnd,
                  onHorizontalDragEnd: dragEnd,
                  onHorizontalDragUpdate: dragEvent,
                  onVerticalDragUpdate: dragEvent,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentSelected != null
                          ? DebugPanelColors.accent
                          : DebugPanelColors.fab,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x40000000),
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
                        Center(child: _logoWidget()),
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
