import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/menu_actions.dart';
import 'package:possystem/components/meta_block.dart';
import 'package:possystem/components/slidable_item_list.dart';
import 'package:possystem/components/style/buttons.dart';
import 'package:possystem/components/style/route_buttons.dart';
import 'package:possystem/constants/icons.dart';
import 'package:possystem/models/menu/catalog.dart';
import 'package:possystem/models/menu/product.dart';
import 'package:possystem/models/repository/menu.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/translator.dart';

class MenuProductList extends StatelessWidget {
  final Catalog? catalog;
  final Widget? leading;

  const MenuProductList({
    super.key,
    required this.catalog,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SlidableItemList(
      leading: leading != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: leading,
            )
          : null,
      action: RouteIconButton(
        label: S.menuProductTitleReorder,
        icon: const Icon(KIcons.reorder),
        route: Routes.menuProductReorder,
        pathParameters: {'id': catalog?.id ?? ''},
        hideLabel: true,
      ),
      delegate: SlidableItemDelegate<Product, int>(
        items: catalog?.itemList ?? Menu.instance.products.toList(),
        deleteValue: 0,
        actionBuilder: _actionBuilder,
        tileBuilder: (product, _, actorBuilder) => _Tile(product, actorBuilder),
        warningContentBuilder: (context, product) => S.dialogDeletionContent(product.name, ''),
        handleDelete: (item) => item.remove(),
      ),
    );
  }

  Iterable<MenuAction<int>> _actionBuilder(Product product) {
    return <MenuAction<int>>[
      MenuAction(
        title: Text(S.menuProductTitleUpdate),
        leading: const Icon(KIcons.modal),
        route: Routes.menuProductUpdate,
        routePathParameters: {'id': product.id},
      ),
      MenuAction(
        title: Text(S.menuIngredientTitleReorder),
        leading: const Icon(KIcons.reorder),
        route: Routes.menuProductReorderIngredient,
        routePathParameters: {'id': product.id},
      ),
    ];
  }
}

class _Tile extends StatelessWidget {
  final Product product;
  final ActorBuilder actorBuilder;

  const _Tile(this.product, this.actorBuilder);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actor = actorBuilder(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.pushNamed(
            Routes.menuProduct,
            pathParameters: {'id': product.id},
          ),
          onLongPress: actor,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _SleekAvatar(child: product.avator),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      MetaBlock.withString(
                        context,
                        product.items.map((e) => e.name),
                        emptyText: S.menuProductEmptyIngredients,
                        textStyle: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ) ?? const SizedBox.shrink(),
                    ],
                  ),
                ),
                EntryMoreButton(onPressed: actor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SleekAvatar extends StatelessWidget {
  final Widget child;

  const _SleekAvatar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}
