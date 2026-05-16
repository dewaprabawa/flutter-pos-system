import 'dart:async';

import 'package:flutter/material.dart';
import 'package:possystem/components/style/circular_loading.dart';
import 'package:possystem/helpers/breakpoint.dart';
import 'package:possystem/helpers/logger.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ReloadableCard<T> extends StatefulWidget {
  final Widget Function(BuildContext context, T metric) builder;

  final Future<T> Function() loader;

  final List<ChangeNotifier>? notifiers;

  /// Required if you want to reload the card when it's visible.
  final String id;

  final String? title;

  final bool wrappedByCard;

  final Widget? action;

  const ReloadableCard({
    super.key,
    required this.id,
    required this.builder,
    required this.loader,
    this.title,
    this.notifiers,
    this.wrappedByCard = true,
    this.action,
  });

  @override
  State<ReloadableCard<T>> createState() => _ReloadableCardState<T>();
}

class _ReloadableCardState<T> extends State<ReloadableCard<T>> with AutomaticKeepAliveClientMixin {
  String? error;
  T? data;
  bool reloadable = false;
  Widget? lastBuiltTarget;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final title = widget.title != null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: buildTitle(),
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Breakpoint.medium.max),
              child: SizedBox(
                width: double.infinity,
                child: buildWrapper(
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: buildTarget(),
                  ),
                ),
              ),
            ),
            if (reloadable) 
              Positioned(
                top: 24,
                right: 24,
                child: buildReloadingIndicator(),
              ),
          ],
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant ReloadableCard<T> oldWidget) {
    if (oldWidget.id != widget.id) {
      data = null;
      reloadable = true;
      reload();
      updateKeepAlive();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  bool get wantKeepAlive => data != null;

  Widget buildTarget() {
    if (error != null) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (data == null) {
      return const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.all(64.0),
        child: CircularLoading(),
      );
    }

    if (reloadable && lastBuiltTarget != null) {
      return lastBuiltTarget!;
    }

    return lastBuiltTarget = Container(
      key: ValueKey('data-${widget.id}'),
      child: widget.builder(context, data as T),
    );
  }

  Widget buildWrapper(Widget child) {
    if (widget.wrappedByCard) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: child,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: child,
    );
  }

  Widget buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.title!,
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.action != null) widget.action!,
      ],
    );
  }

  Widget buildReloadingIndicator() {
    return VisibilityDetector(
      key: Key('anal_card_detector.${widget.id}'),
      onVisibilityChanged: (info) async {
        if (info.visibleFraction > 0.1) {
          await reload();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          height: 12,
          width: 12,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    load().then((value) {
      if (mounted) {
        setState(() => data = value);
      }
    });
    widget.notifiers?.forEach((e) {
      e.addListener(handleUpdate);
    });
  }

  @override
  void dispose() {
    widget.notifiers?.forEach((e) {
      e.removeListener(handleUpdate);
    });
    super.dispose();
  }

  Future<T?> load() {
    return widget.loader().onError((e, stack) {
      Log.err(e ?? 'unknown', 'load_metrics', stack);
      setState(() => error = e?.toString() ?? 'unknown');
      return Future.value(null);
    });
  }

  Future<void> reload() async {
    if (reloadable) {
      final inline = await load();
      if (mounted) {
        setState(() {
          reloadable = false;
          lastBuiltTarget = null;
          data = inline;
        });
      }
    }
  }

  void handleUpdate() {
    if (!reloadable && mounted) {
      setState(() {
        reloadable = true;
      });
    }
  }
}
