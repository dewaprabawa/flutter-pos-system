import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/dialog/responsive_dialog.dart';
import 'package:possystem/components/meta_block.dart';
import 'package:possystem/components/slidable_item_list.dart';
import 'package:possystem/components/style/buttons.dart';
import 'package:possystem/components/style/route_buttons.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/constants/icons.dart';
import 'package:possystem/models/printer.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/printer/widgets/printer_view.dart';

class PrinterPage extends StatelessWidget {
  const PrinterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      key: const Key('printers_page'),
      listenable: Printers.instance,
      builder: (context, child) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (Printers.instance.isEmpty) {
      return const _EmptyBody();
    }

    return SafeArea(
      child: SlidableItemList(
        hintText: '',
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ButtonGroup(spacerAt: 2, buttons: [
            RouteIconButton(
              key: const Key('printer.create'),
              route: Routes.printerCreate,
              icon: const Icon(KIcons.add),
              label: S.printerTitleCreate,
            ),
            IconButton(
              key: const Key('printer.supported_list'),
              onPressed: _showSupportedPrinters(context),
              icon: const Icon(Icons.info_outline),
              tooltip: S.printerSupportedTitle,
            ),
            RouteIconButton(
              key: const Key('printer.settings'),
              route: Routes.printerSettings,
              icon: const Icon(Icons.settings),
              label: S.printerTitleSettings,
            ),
          ]),
        ),
        delegate: SlidableItemDelegate(
          disableSlide: true,
          items: Printers.instance.itemList,
          tileBuilder: (printer, _, actorBuilder) => _Tile(printer, actorBuilder),
          handleDelete: (printer) => printer.remove(),
          deleteValue: 0,
          warningContentBuilder: (_, printer) => S.dialogDeletionContent(printer.name, ''),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Printer item;
  final ActorBuilder actorBuilder;

  const _Tile(this.item, this.actorBuilder);

  @override
  Widget build(BuildContext context) {
    final actor = actorBuilder(context);
    return PrinterView(
      printer: item,
      trailing: EntryMoreButton(onPressed: actor),
      onTap: () => context.pushNamed(Routes.printerUpdate, pathParameters: {'id': item.id}),
      onLogPress: actor,
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.print_disabled_outlined,
                size: 80,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              S.printerMetaHelper,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              S.printerSupportedTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () => context.pushNamed(Routes.printerCreate),
              icon: const Icon(Icons.add),
              label: Text(S.printerTitleCreate),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _showSupportedPrinters(context),
              child: Text(S.printerSupportedTitle),
            ),
            if (kDebugMode)
              Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: OutlinedButton(
                  onPressed: () => Printers.instance.addItem(Printer(id: 'demo', name: 'Demo Printer')),
                  child: const Text('Add demo'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

VoidCallback _showSupportedPrinters(BuildContext context) {
  return () => showDialog(
        context: context,
        builder: (context) => ResponsiveDialog(
          title: Text(S.printerSupportedTitle),
          content: Column(children: [
            for (final printer in [PrinterProvider.catPrinter, PrinterProvider.xPrinter58, PrinterProvider.yokoscan58])
              ListTile(
                key: Key('printer.supported.${printer.name}'),
                title: Text(S.printerSupportedName(printer.name)),
                subtitle: MetaBlock.withString(context, printer.markers),
                trailing: const Icon(Icons.open_in_new),
                onTap: printer.launchUrl,
              ),
          ]),
        ),
      );
}
