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

  const OrderCatalogListView({
    super.key,
    required this.catalogs,
    required this.indexNotifier,
    required this.onSelected,
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
      height: 50,
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.catalogs.length,
              itemBuilder: (context, i) {
                final catalog = widget.catalogs[i];
                final isSelected = catalog.id == selectedId;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
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
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
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
