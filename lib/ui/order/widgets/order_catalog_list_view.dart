import 'package:flutter/material.dart';
import 'package:possystem/components/style/single_row_warp.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/menu/catalog.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/order/order_page.dart';

class OrderCatalogListView extends StatefulWidget {
  final List<Catalog> catalogs;
  final void Function(int) onSelected;
  final ValueNotifier<int> indexNotifier;
  final ValueNotifier<ProductListView> viewNotifier;

  const OrderCatalogListView({
    super.key,
    required this.catalogs,
    required this.indexNotifier,
    required this.onSelected,
    required this.viewNotifier,
  });

  @override
  State<OrderCatalogListView> createState() => _OrderCatalogListViewState();
}

class _OrderCatalogListViewState extends State<OrderCatalogListView> {
  final FocusNode _f = FocusNode(debugLabel: 'OrderCatalogListView');
  final MenuController controller = MenuController();
  late String selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.catalogs.isEmpty) {
      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Text(S.orderCatalogListEmpty, style: theme.textTheme.bodyMedium),
      );
    }

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: widget.catalogs.length,
              itemBuilder: (context, i) {
                final catalog = widget.catalogs[i];
                final isSelected = catalog.id == selectedId;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: ChoiceChip(
                      avatar: isSelected ? null : catalog.avator,
                      key: Key('order.catalog.${catalog.id}'),
                      onSelected: (isSelected) {
                        if (isSelected) {
                          setState(() => selectedId = catalog.id);
                          widget.onSelected(i);
                        }
                      },
                      selected: isSelected,
                      label: Text(
                        catalog.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                        ),
                      ),
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide.none,
                      ),
                      showCheckmark: false,
                    ),
                  ),
                );
              },
            ),
          ),
          const VerticalDivider(width: 1, indent: 16, endIndent: 16),
          _ProductListView(
            controller: controller,
            focusNode: _f,
            viewNotifier: widget.viewNotifier,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _f.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.indexNotifier.addListener(() {
      if (mounted) {
        setState(() {
          final index = widget.indexNotifier.value;
          selectedId = widget.catalogs[index].id;
        });
      }
    });
    selectedId = widget.catalogs.isEmpty ? '' : widget.catalogs.first.id;
  }
}

class _ProductListView extends StatelessWidget {
  const _ProductListView({
    required this.controller,
    required this.focusNode,
    required this.viewNotifier,
  });

  final MenuController controller;
  final FocusNode focusNode;
  final ValueNotifier<ProductListView> viewNotifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: MenuAnchor(
        controller: controller,
        childFocusNode: focusNode,
        menuChildren: ProductListView.values.map((e) {
          return MenuItemButton(
            leadingIcon: e.icon,
            onPressed: () => viewNotifier.value = e,
            child: Text(S.orderProductListViewHelper(e.name)),
          );
        }).toList(),
        child: ListenableBuilder(
          listenable: viewNotifier,
          builder: (context, child) {
            return IconButton(
              focusNode: focusNode,
              onPressed: controller.toggle,
              icon: viewNotifier.value.icon,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
      ),
    );
  }
}
