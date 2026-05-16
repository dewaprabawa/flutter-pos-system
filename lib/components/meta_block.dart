import 'package:flutter/material.dart';
import 'package:possystem/components/style/hint_text.dart';

class MetaBlock {
  static TextSpan span() {
    return const TextSpan(text: string);
  }

  static const string = '  •  ';

  /// Divide strings with a modern pill layout
  ///
  /// return null if [emptyText] is not provided and [data] is empty
  static Widget? withString(
    BuildContext context,
    Iterable<String> data, {
    TextStyle? textStyle,
    String? emptyText,
    int? maxLines,
    TextOverflow textOverflow = TextOverflow.ellipsis,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (data.isNotEmpty) {
      final style = textStyle ??
          theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );

      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: data.map((value) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Text(
              value,
              style: style,
              maxLines: maxLines ?? 1,
              overflow: textOverflow,
            ),
          );
        }).toList(),
      );
    } else if (emptyText != null) {
      return HintText(emptyText);
    } else {
      return null;
    }
  }
}
