import 'package:flutter/material.dart';
import 'package:possystem/components/menu_actions.dart';
import 'package:possystem/components/meta_block.dart';
import 'package:possystem/components/slidable_item_list.dart';
import 'package:possystem/components/style/buttons.dart';
import 'package:possystem/components/style/route_buttons.dart';
import 'package:possystem/constants/icons.dart';
import 'package:possystem/models/menu/catalog.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/translator.dart';

class MenuCatalogList extends StatelessWidget {
  final List<Catalog> catalogs;
  final Widget leading;
  final void Function(Catalog) onSelected;

  const MenuCatalogList(
    this.catalogs, {
    super.key,
    required this.onSelected,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SlidableItemList<Catalog, _Action>(
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: leading,
      ),
      action: RouteIconButton(
        label: S.menuCatalogTitleReorder,
        icon: const Icon(KIcons.reorder),
        route: Routes.menuCatalogReorder,
        hideLabel: true,
      ),
      delegate: SlidableItemDelegate(
        items: catalogs,
        deleteValue: _Action.delete,
        tileBuilder: (catalog, _, actorBuilder) => _Tile(catalog, actorBuilder, onSelected),
        warningContentBuilder: _warningContentBuilder,
        actionBuilder: (Catalog catalog) => <MenuAction<_Action>>[
          MenuAction(
            title: Text(S.menuCatalogTitleUpdate),
            leading: const Icon(KIcons.modal),
            routePathParameters: {'id': catalog.id},
            route: Routes.menuCatalogUpdate,
          ),
          MenuAction(
            title: Text(S.menuProductTitleReorder),
            leading: const Icon(KIcons.reorder),
            route: Routes.menuProductReorder,
            routePathParameters: {'id': catalog.id},
          ),
        ],
        handleDelete: (item) => item.remove(),
      ),
    );
  }

  String _warningContentBuilder(BuildContext context, Catalog catalog) {
    final more = S.menuCatalogDialogDeletionContent(catalog.length);
    return S.dialogDeletionContent(catalog.name, '$more\n\n');
  }
}

class _Tile extends StatelessWidget {
  final Catalog catalog;
  final ActorBuilder actorBuilder;
  final void Function(Catalog) onSelected;

  const _Tile(this.catalog, this.actorBuilder, this.onSelected);

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
          onTap: () => onSelected(catalog),
          onLongPress: actor,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _SleekAvatar(child: catalog.avator),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catalog.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      MetaBlock.withString(
                        context,
                        catalog.itemList.map((product) => product.name),
                        emptyText: S.menuCatalogEmptyProducts,
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
            color: Colors.black.withOpacity(0.05),
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

enum _Action {
  delete,
}
