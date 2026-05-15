import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:possystem/translator.dart';

class PercentileBar extends StatefulWidget {
  final num total;
  final num at;

  const PercentileBar(
    this.at,
    this.total, {
    super.key,
  });

  @override
  State<PercentileBar> createState() => _PercentileBarState();
}

class _PercentileBarState extends State<PercentileBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curveAnimation;
  final nf = NumberFormat.compact(locale: S.localeName);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            '${nf.format(widget.at)} / ${nf.format(widget.total)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _curveAnimation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _controller.value,
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                minHeight: 8,
                semanticsLabel: S.semanticsPercentileBar(_curveAnimation.value),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: widget.total == 0 ? 1.0 : widget.at / widget.total,
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _curveAnimation = _controller.drive(CurveTween(curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.at != widget.at || oldWidget.total != widget.total) {
      _controller.animateTo(widget.total == 0 ? 1.0 : widget.at / widget.total);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
