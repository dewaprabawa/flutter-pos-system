import 'dart:io';

import 'package:flutter/material.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/models/order/order_attribute.dart';
import 'package:possystem/models/order/order_attribute_option.dart';
import 'package:possystem/models/repository/cart.dart';
import 'package:possystem/models/repository/order_attributes.dart';
import 'package:possystem/models/xfile.dart';
import 'package:possystem/services/image_dumper.dart';
import 'package:possystem/translator.dart';

class CheckoutAttributeView extends StatelessWidget {
  final ValueNotifier<num> price;

  const CheckoutAttributeView({
    super.key,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final noteField = TextField(
      key: const Key('order.attr_note'),
      controller: TextEditingController(text: Cart.instance.note),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: S.orderCheckoutAttributeNoteHint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.multiline,
      maxLength: 200,
      minLines: 1,
      maxLines: 2,
      onChanged: Cart.instance.updateNote,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in OrderAttributes.instance.notEmptyItems.where((e) {
            final name = e.name.toLowerCase();
            return name != 'age' &&
                name != 'usia' &&
                name != 'eco-friendly' &&
                name != 'eco friendly';
          }))
            _CheckoutAttributeGroup(item, price),
          const SizedBox(height: 8),
          Text(
            S.orderCheckoutAttributeNoteTitle,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          noteField,
          const SizedBox(height: 16),
          const _ProofAttachment(),
        ],
      ),
    );
  }
}

class _CheckoutAttributeGroup extends StatefulWidget {
  final ValueNotifier<num> price;

  final OrderAttribute attribute;

  const _CheckoutAttributeGroup(this.attribute, this.price);

  @override
  State<_CheckoutAttributeGroup> createState() =>
      _CheckoutAttributeGroupState();
}

class _CheckoutAttributeGroupState extends State<_CheckoutAttributeGroup> {
  late String? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.attribute.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in widget.attribute.itemList)
              _AttributeChip(
                key: Key('order.attr.${widget.attribute.id}.${option.id}'),
                label: option.name,
                isSelected: selectedId == option.id,
                onSelected: (selected) {
                  setState(() => selectedId = selected ? option.id : null);
                  selectOption(option, selected);
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    selectedId = Cart.instance.attributes[widget.attribute.id] ??
        widget.attribute.defaultOption?.id;
  }

  void selectOption(OrderAttributeOption option, bool isSelected) {
    Cart.instance.chooseAttribute(
      widget.attribute.id,
      isSelected ? option.id : '',
    );

    widget.price.value = Cart.instance.price;
  }
}

class _AttributeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _AttributeChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => onSelected(!isSelected),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofAttachment extends StatelessWidget {
  const _ProofAttachment();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Cart.instance,
      builder: (context, _) {
        final path = Cart.instance.imagePath;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bukti Pembayaran (Opsional)',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (path != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      File(path),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Cart.instance.updateImagePath(null),
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: () async {
                  final image = await ImageDumper.instance.pick();
                  if (image != null) {
                    Cart.instance.updateImagePath(image.path);
                  }
                },
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Lampirkan Bukti (QRIS/Transfer)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
