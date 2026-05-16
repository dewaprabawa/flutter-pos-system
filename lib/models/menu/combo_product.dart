import 'dart:convert';

/// A combo/package menu item that groups multiple products at a special price.
class ComboProduct {
  final String id;
  final String name;
  final String description;
  final List<ComboItem> items;
  final num specialPrice; // 0 means "sum of individual prices"
  final DateTime createdAt;

  ComboProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.items,
    required this.specialPrice,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// The total price before any combo discount (sum of all items * qty).
  num get originalPrice => items.fold<num>(0, (sum, item) => sum + (item.price * item.qty));

  /// The effective selling price — either a special price or the original sum.
  num get price => specialPrice > 0 ? specialPrice : originalPrice;

  /// Savings if a special price is set.
  num get savings => originalPrice - price;

  factory ComboProduct.fromJson(Map<String, dynamic> json) {
    return ComboProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      specialPrice: (json['specialPrice'] as num?) ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      items: (json['items'] as List<dynamic>)
          .map((e) => ComboItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'specialPrice': specialPrice,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
      };

  ComboProduct copyWith({
    String? name,
    String? description,
    List<ComboItem>? items,
    num? specialPrice,
  }) {
    return ComboProduct(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      items: items ?? this.items,
      specialPrice: specialPrice ?? this.specialPrice,
      createdAt: createdAt,
    );
  }
}

/// A single product entry inside a combo.
class ComboItem {
  final String productId;
  final String productName;
  final num price;
  final int qty;

  const ComboItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.qty,
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    return ComboItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num?) ?? 0,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'qty': qty,
      };
}

/// Utility to encode/decode a list of combos as a JSON string.
String encodeCombos(List<ComboProduct> combos) =>
    jsonEncode(combos.map((e) => e.toJson()).toList());

List<ComboProduct> decodeCombos(String raw) {
  final list = jsonDecode(raw) as List<dynamic>;
  return list.map((e) => ComboProduct.fromJson(e as Map<String, dynamic>)).toList();
}
