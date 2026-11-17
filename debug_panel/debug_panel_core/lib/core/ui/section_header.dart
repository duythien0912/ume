import 'dart:async';

import 'package:flutter/material.dart';
import 'package:debug_panel_core/core/ui/copy_button.dart';
import 'package:debug_panel_core/core/ui/theme.dart';

/// The tappable title row of a section that opens and closes: chevron,
/// title, a muted note (count, size) and an optional copy button.
class DebugPanelSectionHeader extends StatelessWidget {
  const DebugPanelSectionHeader({
    super.key,
    required this.title,
    required this.open,
    required this.onTap,
    this.note,
    this.copyText,
    this.indent = 0,
  });

  final String title;
  final bool open;
  final VoidCallback onTap;
  final String? note;

  /// Copies the section's content; no button when null.
  final FutureOr<String> Function()? copyText;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final copyText = this.copyText;
    final note = this.note;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 36,
        child: Row(
          children: <Widget>[
            SizedBox(width: indent),
            Icon(
              open ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
              size: 18,
              color: DebugPanelColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DebugPanelColors.text,
              ),
            ),
            if (note != null && note.isNotEmpty) ...<Widget>[
              const SizedBox(width: 6),
              Text(
                note,
                style: const TextStyle(
                  fontSize: 12,
                  color: DebugPanelColors.textMuted,
                ),
              ),
            ],
            const Spacer(),
            if (copyText != null)
              DebugPanelCopyButton(
                tooltip: 'Copy ${title.toLowerCase()}',
                size: 15,
                dense: true,
                text: copyText,
              ),
          ],
        ),
      ),
    );
  }
}
