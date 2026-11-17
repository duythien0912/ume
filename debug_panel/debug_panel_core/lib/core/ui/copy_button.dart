import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:debug_panel_core/core/ui/theme.dart';

/// Copies [text] and shows a check mark for a moment.
mixin _CopyFeedback<T extends StatefulWidget> on State<T> {
  bool copied = false;
  Timer? _timer;

  Future<void> copy(String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
    } on PlatformException {
      return;
    }
    if (!mounted) return;
    setState(() => copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => copied = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// An icon button that copies [text] and briefly shows a check mark.
class DebugPanelCopyButton extends StatefulWidget {
  const DebugPanelCopyButton({
    required this.tooltip,
    required this.text,
    this.size = 20,
    this.icon = Icons.copy_rounded,
    this.color = DebugPanelColors.textMuted,
  });

  final String tooltip;
  final String Function() text;
  final double size;
  final IconData icon;
  final Color color;

  @override
  State<DebugPanelCopyButton> createState() => _DebugPanelCopyButtonState();
}

class _DebugPanelCopyButtonState extends State<DebugPanelCopyButton>
    with _CopyFeedback<DebugPanelCopyButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: copied ? 'Copied' : widget.tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () => copy(widget.text()),
      icon: Icon(
        copied ? Icons.check_rounded : widget.icon,
        size: widget.size,
        color: copied ? DebugPanelColors.success : widget.color,
      ),
    );
  }
}

/// An outlined button that copies [text] and briefly shows "Copied".
class DebugPanelCopyAction extends StatefulWidget {
  const DebugPanelCopyAction({
    required this.icon,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final String label;
  final String Function() text;

  @override
  State<DebugPanelCopyAction> createState() => _DebugPanelCopyActionState();
}

class _DebugPanelCopyActionState extends State<DebugPanelCopyAction>
    with _CopyFeedback<DebugPanelCopyAction> {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => copy(widget.text()),
      icon: Icon(copied ? Icons.check_rounded : widget.icon, size: 18),
      label: Text(copied ? 'Copied' : widget.label),
      style: OutlinedButton.styleFrom(
        foregroundColor:
            copied ? DebugPanelColors.success : DebugPanelColors.text,
        side: const BorderSide(color: DebugPanelColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(0, 40),
      ),
    );
  }
}

