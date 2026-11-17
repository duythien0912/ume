import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:debug_panel_core/core/ui/theme.dart';

/// Copies [text] and confirms with a short snack bar when one can be shown.
Future<void> debugPanelCopy(
  BuildContext context,
  String text, {
  String message = 'Copied',
}) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
  } on PlatformException {
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
}

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
    super.key,
    required this.tooltip,
    required this.text,
    this.size = 18,
    this.icon = Icons.copy_rounded,
    this.color = DebugPanelColors.textMuted,
    this.dense = false,
  });

  final String tooltip;

  /// May be async, so big text is built off the UI thread.
  final FutureOr<String> Function() text;
  final double size;
  final IconData icon;
  final Color color;

  /// A 28 px button for list rows instead of the usual 40 px.
  final bool dense;

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
      constraints: widget.dense
          ? const BoxConstraints.tightFor(width: 28, height: 28)
          : null,
      padding: widget.dense ? EdgeInsets.zero : null,
      onPressed: () async => copy(await widget.text()),
      icon: Icon(
        copied ? Icons.check_rounded : widget.icon,
        size: widget.size,
        color: copied ? DebugPanelColors.success : widget.color,
      ),
    );
  }
}

/// A small pill button that copies [text] and briefly shows "Copied".
class DebugPanelCopyAction extends StatefulWidget {
  const DebugPanelCopyAction({
    super.key,
    required this.icon,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final String label;
  final FutureOr<String> Function() text;

  @override
  State<DebugPanelCopyAction> createState() => _DebugPanelCopyActionState();
}

class _DebugPanelCopyActionState extends State<DebugPanelCopyAction>
    with _CopyFeedback<DebugPanelCopyAction> {
  @override
  Widget build(BuildContext context) {
    final color = copied ? DebugPanelColors.success : DebugPanelColors.text;
    return TextButton.icon(
      onPressed: () async => copy(await widget.text()),
      icon: Icon(copied ? Icons.check_rounded : widget.icon, size: 15),
      label: Text(copied ? 'Copied' : widget.label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: DebugPanelColors.surfaceMuted,
        textStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 30),
        fixedSize: const Size.fromHeight(30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
