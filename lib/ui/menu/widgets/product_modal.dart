import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/style/image_holder.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/helpers/input_formatters.dart';
import 'package:possystem/helpers/validator.dart';
import 'package:possystem/models/menu/catalog.dart';
import 'package:possystem/models/menu/product.dart';
import 'package:possystem/models/objects/menu_object.dart';
import 'package:possystem/models/repository/menu.dart';
import 'package:possystem/translator.dart';

class ProductModal extends StatefulWidget {
  final Product? product;
  final Catalog catalog;
  final bool isNew;

  const ProductModal({
    super.key,
    this.product,
    required this.catalog,
  }) : isNew = product == null;

  @override
  State<ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends State<ProductModal> {
  final formKey = GlobalKey<FormState>();
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late FocusNode _nameFocusNode;
  late FocusNode _priceFocusNode;
  late FocusNode _costFocusNode;

  String? _image;
  bool _isSaving = false;

  String get title =>
      widget.isNew ? S.menuProductTitleCreate : S.menuProductTitleUpdate;

  @override
  void initState() {
    super.initState();

    final p = widget.product;
    _nameController = TextEditingController(text: p?.name);
    _priceController = TextEditingController(text: p?.price.toString());
    _costController = TextEditingController(text: p?.cost.toString());
    _nameFocusNode = FocusNode();
    _priceFocusNode = FocusNode();
    _costFocusNode = FocusNode();
    _image = widget.product?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _nameFocusNode.dispose();
    _priceFocusNode.dispose();
    _costFocusNode.dispose();
    super.dispose();
  }

  ProductObject _parseObject() {
    return ProductObject(
      name: _nameController.text,
      imagePath: _image,
      price: num.tryParse(_priceController.text.replaceAll('.', '')),
      cost: num.tryParse(_costController.text.replaceAll('.', '')),
    );
  }

  Future<Product> getProduct() async {
    final object = _parseObject();
    final product = widget.product ??
        Product(
          index: widget.catalog.newIndex,
          name: object.name!,
          price: object.price!,
          cost: object.cost!,
          imagePath: _image,
        );

    if (widget.isNew) {
      await widget.catalog.addItem(product);
    } else {
      await product.update(object);
    }

    return product;
  }

  Future<void> _handleSubmit() async {
    if (_isSaving || formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);
    try {
      final product = await getProduct();
      if (mounted) {
        showSnackBar(S.actSuccess, context: context);
        context.pop(product.id);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
        ),
        body: Form(
          key: formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: EditImageHolder(
                          path: _image,
                          onSelected: (image) => setState(() => _image = image),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        key: const Key('product.name'),
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 30,
                        decoration: InputDecoration(
                          labelText: S.menuProductNameLabel,
                          hintText:
                              widget.product?.name ?? S.menuProductNameHint,
                          prefixIcon: const Icon(Icons.fastfood_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        validator: Validator.textLimit(
                          S.menuProductNameLabel,
                          30,
                          focusNode: _nameFocusNode,
                          validator: (name) {
                            return widget.product?.name != name &&
                                    Menu.instance.hasProductByName(name)
                                ? S.menuProductNameErrorRepeat
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('product.price'),
                        controller: _priceController,
                        focusNode: _priceFocusNode,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: S.menuProductPriceLabel,
                          helperText: S.menuProductPriceHelper,
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: Validator.isNumber(
                          S.menuProductPriceLabel,
                          focusNode: _priceFocusNode,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('product.cost'),
                        controller: _costController,
                        focusNode: _costFocusNode,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (_) => _handleSubmit(),
                        decoration: InputDecoration(
                          labelText: S.menuProductCostLabel,
                          helperText: S.menuProductCostHelper,
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: Validator.positiveNumber(
                          S.menuProductCostLabel,
                          focusNode: _costFocusNode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: FilledButton(
                    key: const Key('modal.save'),
                    onPressed: _isSaving ? null : _handleSubmit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            MaterialLocalizations.of(context).saveButtonLabel,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
