import 'package:flutter/material.dart';
import 'package:debug_panel_core/core/pluggable.dart';
import 'package:debug_panel_core/core/pluggable_message_service.dart';
import 'package:debug_panel_core/core/red_dot.dart';
import 'package:debug_panel_core/core/ui/icon_cache.dart';
import 'package:debug_panel_core/core/ui/theme.dart';

/// One tool in the panel: icon on a rounded tile with its name below.
class ToolTile extends StatelessWidget {
  const ToolTile({
    super.key,
    required this.pluggable,
    this.onTap,
    this.iconBoxSize = 52,
  });

  final Pluggable pluggable;
  final VoidCallback? onTap;
  final double iconBoxSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                PluggableMessageService().resetCounter(pluggable);
                onTap!();
              },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    padding: EdgeInsets.all(iconBoxSize * 0.24),
                    decoration: BoxDecoration(
                      color: DebugPanelColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(iconBoxSize * 0.3),
                    ),
                    // Tint every tool icon to the panel accent so they match.
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        DebugPanelColors.accent,
                        BlendMode.srcIn,
                      ),
                      child: IconCache.icon(pluggableInfo: pluggable),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: RedDot(pluginDatas: <Pluggable>[pluggable]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                pluggable.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: DebugPanelColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
