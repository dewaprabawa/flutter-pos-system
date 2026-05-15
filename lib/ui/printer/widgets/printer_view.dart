import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/imageable_container.dart';
import 'package:possystem/components/linkify.dart';
import 'package:possystem/components/style/pop_button.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/objects/order_attribute_object.dart';
import 'package:possystem/models/objects/order_object.dart';
import 'package:possystem/models/printer.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/printer/widgets/printer_receipt_view.dart';

class PrinterView extends StatefulWidget {
  final Printer printer;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLogPress;

  const PrinterView({
    super.key,
    required this.printer,
    this.trailing,
    this.onTap,
    this.onLogPress,
  });

  @override
  State<PrinterView> createState() => _PrinterViewState();
}

class _PrinterViewState extends State<PrinterView> {
  ValueNotifier<bool> waiting = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      _buildCard(),
      ListenableBuilder(
        listenable: waiting,
        builder: (context, child) {
          if (waiting.value) {
            return const _Backdrop(child: CircularProgressIndicator.adaptive());
          }
          return const SizedBox.shrink();
        },
      ),
    ]);
  }

  Widget _buildCard() {
    return ListenableBuilder(
      listenable: widget.printer,
      builder: (context, child) {
        return _SleekPrinterCard(
          printer: widget.printer,
          trailing: widget.trailing,
          onTap: widget.onTap,
          onLongPress: widget.onLogPress,
          onConnect: connect,
          onDisconnect: disconnect,
          onReconnect: reconnect,
          onPrintTest: startPrint,
        );
      },
    );
  }

  void connect() async {
    if (!waiting.value) {
      waiting.value = true;
      final success = await showSnackbarWhenFutureError(
        widget.printer.connect(),
        'printer_view_connect',
        context: context,
      );
      onConnected(success);
      waiting.value = false;
    }
  }

  void disconnect() async {
    if (!waiting.value) {
      waiting.value = true;
      await showSnackbarWhenFutureError(
        widget.printer.disconnect(),
        'printer_view_disconnect',
        context: context,
      );
      waiting.value = false;
    }
  }

  void reconnect() async {
    if (!waiting.value) {
      waiting.value = true;
      await showSnackbarWhenFutureError(() async {
        await widget.printer.disconnect();
        final success = await widget.printer.connect();
        onConnected(success);
      }(), 'printer_view_reconnect', context: context);
      waiting.value = false;
    }
  }

  void onConnected(bool? success) {
    if (success == false && mounted) {
      showMoreInfoSnackBar(
        S.printerErrorNotSupportTitle,
        Linkify.fromString(S.printerErrorNotSupportContent),
        context: context,
      );
    }
  }

  void startPrint() async {
    final progress = ValueNotifier<double?>(null);
    final controller = ImageableManger.instance.create();
    final done = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.printerBtnTestPrint),
        contentPadding: EdgeInsets.zero,
        actions: [
          PopButton(title: MaterialLocalizations.of(context).cancelButtonLabel),
          _PrintButton(
            progress: progress,
            controller: controller,
            printer: widget.printer,
          ),
        ],
        content: Stack(alignment: Alignment.center, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: PrinterReceiptView(
              controller: controller,
              order: OrderObject(
                createdAt: DateTime.now(),
                price: 300,
                paid: 500,
                attributes: [
                  OrderSelectedAttributeObject(
                    optionName: S.orderAttributeExamplePlaceDineIn,
                    mode: OrderAttributeMode.changeDiscount,
                    modeValue: 10,
                  ),
                ],
                products: [
                  OrderProductObject(
                    productName: S.menuExampleProductCheeseBurger,
                    count: 2,
                    singlePrice: 60,
                    originalPrice: 120,
                    isDiscount: true,
                  ),
                  OrderProductObject(
                    productName: S.menuExampleProductHamBurger,
                    count: 1,
                    singlePrice: 180,
                    originalPrice: 180,
                  ),
                ],
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: progress,
            builder: (context, value, _) {
              return value == null
                  ? const SizedBox.shrink()
                  : _Backdrop(child: CircularProgressIndicator.adaptive(value: value));
            },
          ),
        ]),
      ),
    );

    if (done == true && mounted) {
      showSnackBar(S.printerStatusPrinted, context: context);
    }
  }
}

class _SleekPrinterCard extends StatelessWidget {
  final Printer printer;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onReconnect;
  final VoidCallback onPrintTest;

  const _SleekPrinterCard({
    required this.printer,
    this.trailing,
    this.onTap,
    this.onLongPress,
    required this.onConnect,
    required this.onDisconnect,
    required this.onReconnect,
    required this.onPrintTest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = printer.connected;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isConnected 
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                        color: isConnected ? theme.colorScheme.primary : theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            printer.name == '' ? '<unknown>' : printer.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isConnected ? S.printerStatusSuccess : S.printerStatusStandby,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isConnected ? theme.colorScheme.primary : theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                if (isConnected) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onPrintTest,
                        label: Text(S.printerBtnTestPrint),
                        icon: const Icon(Icons.print, size: 18),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MenuAnchor(
                        menuChildren: [
                          MenuItemButton(
                            onPressed: onReconnect,
                            leadingIcon: const Icon(Icons.refresh),
                            child: Text(S.printerBtnRetry),
                          ),
                          MenuItemButton(
                            onPressed: onDisconnect,
                            leadingIcon: const Icon(Icons.bluetooth_disabled),
                            child: Text(S.printerBtnDisconnect),
                          ),
                        ],
                        builder: (context, controller, _) {
                          return FilledButton.icon(
                            onPressed: controller.toggle,
                            label: Text(S.printerStatusConnecting),
                            icon: const Icon(Icons.arrow_drop_down),
                            iconAlignment: IconAlignment.end,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton(
                        onPressed: onConnect,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(S.printerBtnConnect),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  final Widget child;
  const _Backdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _PrintButton extends StatelessWidget {
  final ValueNotifier<double?> progress;
  final ImageableController controller;
  final Printer printer;

  const _PrintButton({
    required this.progress,
    required this.controller,
    required this.printer,
  });

  @override
  Widget build(BuildContext context) {
    void handleDone() {
      if (progress.value != null) {
        reset();
        if (context.mounted && context.canPop()) {
          context.pop(true);
        }
      }
    }

    void handlePress() async {
      progress.value = 0;
      final future = controller.toImage(widths: [printer.provider.manufactory.widthBits]);
      final data = await future;
      if (data != null && context.mounted) {
        final image = data.first.toGrayScale().toBitMap().bytes;
        showSnackbarWhenStreamError(
          printer.draw(image),
          'printer_test',
          context: context,
          callback: reset,
        ).listen((value) => progress.value = value, onDone: handleDone);
      }
    }

    return ValueListenableBuilder(
      valueListenable: progress,
      builder: (context, value, _) {
        return TextButton(
          onPressed: value == null ? handlePress : null,
          child: Text(S.printerBtnPrint),
        );
      },
    );
  }

  void reset() {
    progress.value = null;
  }
}
