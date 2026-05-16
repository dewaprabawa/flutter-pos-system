import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/style/image_holder.dart';
import 'package:possystem/helpers/validator.dart';
import 'package:possystem/models/menu/catalog.dart';
import 'package:possystem/models/objects/menu_object.dart';
import 'package:possystem/models/repository/menu.dart';
import 'package:possystem/translator.dart';

class CatalogModal extends StatefulWidget {
  final Catalog? catalog;

  final bool isNew;

  const CatalogModal({super.key, this.catalog}) : isNew = catalog == null;

  @override
  State<CatalogModal> createState() => _CatalogModalState();
}

class _CatalogModalState extends State<CatalogModal> {
  final formKey = GlobalKey<FormState>();
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;

  String? _image;
  bool _isSaving = false;

  String get title => widget.isNew ? S.menuCatalogTitleCreate : S.menuCatalogTitleUpdate;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.catalog?.name);
    _image = widget.catalog?.imagePath;
    _nameFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<Catalog> getCatalog() async {
    final object = CatalogObject(name: _nameController.text, imagePath: _image);
    final catalog = widget.catalog ??
        Catalog(
          name: object.name,
          index: Menu.instance.newIndex,
          imagePath: _image,
        );

    if (widget.isNew) {
      await Menu.instance.addItem(catalog);
    } else {
      await catalog.update(object);
    }

    return catalog;
  }

  Future<void> _handleSubmit() async {
    if (_isSaving || formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);
    try {
      final catalog = await getCatalog();
      if (mounted) {
        widget.isNew ? context.pop(catalog) : context.pop();
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
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      RawAutocomplete<String>(
                        textEditingController: _nameController,
                        focusNode: _nameFocusNode,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          const suggestions = [
                            'Main Course',
                            'Appetizers',
                            'Desserts',
                            'Beverages',
                            'Snacks',
                            'Alcohol',
                            'Breakfast',
                            'Lunch',
                            'Dinner',
                            'Others',
                          ];
                          if (textEditingValue.text.isEmpty) {
                            return suggestions;
                          }
                          return suggestions.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            key: const Key('catalog.name'),
                            controller: controller,
                            focusNode: focusNode,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.words,
                            onFieldSubmitted: (_) => _handleSubmit(),
                            maxLength: 30,
                            decoration: InputDecoration(
                              labelText: S.menuCatalogNameLabel,
                              hintText: widget.catalog?.name ?? S.menuCatalogNameHint,
                              prefixIcon: const Icon(Icons.category_outlined),
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            ),
                            validator: Validator.textLimit(
                              S.menuCatalogNameLabel,
                              30,
                              focusNode: focusNode,
                              validator: (name) {
                                return widget.catalog?.name != name && Menu.instance.hasName(name)
                                    ? S.menuCatalogNameErrorRepeat
                                    : null;
                              },
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Material(
                                elevation: 8.0,
                                shadowColor: Colors.black26,
                                borderRadius: BorderRadius.circular(16),
                                clipBehavior: Clip.antiAlias,
                                color: colorScheme.surface,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: 250,
                                    maxWidth: MediaQuery.sizeOf(context).width - 48,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final String option = options.elementAt(index);
                                      return InkWell(
                                        onTap: () => onSelected(option),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                          child: Text(option, style: theme.textTheme.bodyLarge),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
