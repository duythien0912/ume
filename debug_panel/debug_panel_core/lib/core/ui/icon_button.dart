import 'package:flutter/material.dart';
import 'package:debug_panel_core/core/ui/theme.dart';

/// A small square icon button used in panel and tool headers.
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
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        foregroundColor: DebugPanelColors.text,
        disabledForegroundColor: DebugPanelColors.border,
        backgroundColor: DebugPanelColors.surfaceMuted,
        disabledBackgroundColor: DebugPanelColors.surface,
        fixedSize: const Size(32, 32),
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
