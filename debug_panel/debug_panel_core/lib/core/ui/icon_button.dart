import 'package:flutter/material.dart';
import 'package:debug_panel_core/core/ui/theme.dart';

/// A round icon button used in panel and tool headers.
class DebugPanelIconButton extends StatelessWidget {
  const DebugPanelIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 20, color: DebugPanelColors.text),
      style: IconButton.styleFrom(
        backgroundColor: DebugPanelColors.surfaceMuted,
        disabledBackgroundColor: DebugPanelColors.surfaceMuted,
        fixedSize: const Size(36, 36),
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
