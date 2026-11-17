import 'package:flutter/material.dart';
import 'package:debug_panel_core/debug_panel_core.dart';

/// Longer text is cut on screen; copying always gives the full text.
const int _maxShownChars = 20000;

final RegExp _jsonToken = RegExp(
  r'(?<key>"(?:[^"\\]|\\.)*"(?=\s*:))'
  r'|(?<string>"(?:[^"\\]|\\.)*")'
  r'|(?<number>-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)'
  r'|(?<literal>\btrue\b|\bfalse\b|\bnull\b)',
);

/// Monospace text in a dark box: JSON gets line numbers and syntax colors,
/// `name: value` header lines get colored names.
class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.text, this.headers = false});

  final String text;
  final bool headers;

  @override
  Widget build(BuildContext context) {
    final cut = text.length > _maxShownChars;
    final shown = cut ? text.substring(0, _maxShownChars) : text;
    final trimmed = shown.trimLeft();
    final json =
        !headers && (trimmed.startsWith('{') || trimmed.startsWith('['));
    final lines = shown.split('\n');
    final numbered = json && lines.length > 1;
    final gutter = '${lines.length}'.length * 7.5 + 4;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: DebugPanelColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DebugPanelColors.border),
      ),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (var i = 0; i < lines.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (numbered)
                    SelectionContainer.disabled(
                      child: Container(
                        width: gutter,
                        margin: const EdgeInsets.only(right: 10),
                        child: Text(
                          '${i + 1}',
                          textAlign: TextAlign.right,
                          style: debugPanelMonoStyle.copyWith(
                            color: DebugPanelColors.textMuted.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: debugPanelMonoStyle,
                        children: json
                            ? _jsonSpans(lines[i])
                            : headers
                            ? _headerSpans(lines[i])
                            : <InlineSpan>[TextSpan(text: lines[i])],
                      ),
                    ),
                  ),
                ],
              ),
            if (cut)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '… ${text.length - shown.length} more characters, '
                  'copy to get all',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: DebugPanelColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static List<InlineSpan> _headerSpans(String line) {
    final colon = line.indexOf(':');
    if (colon <= 0) return <InlineSpan>[TextSpan(text: line)];
    return <InlineSpan>[
      TextSpan(
        text: line.substring(0, colon + 1),
        style: const TextStyle(color: DebugPanelColors.jsonKey),
      ),
      TextSpan(text: line.substring(colon + 1)),
    ];
  }

  static List<InlineSpan> _jsonSpans(String line) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _jsonToken.allMatches(line)) {
      if (match.start > last) {
        spans.add(TextSpan(text: line.substring(last, match.start)));
      }
      final color = match.namedGroup('key') != null
          ? DebugPanelColors.jsonKey
          : match.namedGroup('string') != null
          ? DebugPanelColors.jsonString
          : match.namedGroup('number') != null
          ? DebugPanelColors.jsonNumber
          : DebugPanelColors.jsonLiteral;
      spans.add(
        TextSpan(
          text: match[0],
          style: TextStyle(color: color),
        ),
      );
      last = match.end;
    }
    if (last < line.length) spans.add(TextSpan(text: line.substring(last)));
    return spans;
  }
}

/// Muted centered text for an empty view.
class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Icon(icon, size: 36, color: DebugPanelColors.textMuted),
            ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: DebugPanelColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A short colored label, like a method or a status code.
class Tag extends StatelessWidget {
  const Tag({super.key, required this.label, required this.color, this.width});

  final String label;
  final Color color;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: width == null ? null : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.4,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
