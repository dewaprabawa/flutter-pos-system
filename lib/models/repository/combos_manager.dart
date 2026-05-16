import 'package:flutter/material.dart';
import 'package:possystem/models/menu/combo_product.dart';
import 'package:possystem/services/cache.dart';

/// Singleton repository for managing Combo/Package menu items.
class CombosManager extends ChangeNotifier {
  static CombosManager instance = CombosManager();

  static const _cacheKey = 'combos_data_v1';

  List<ComboProduct> _combos = [];

  List<ComboProduct> get combos => List.unmodifiable(_combos);

  bool get isEmpty => _combos.isEmpty;

  /// Load combos from SharedPreferences.
  Future<void> initialize() async {
    final raw = Cache.instance.get<String>(_cacheKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _combos = decodeCombos(raw);
      } catch (_) {
        _combos = [];
      }
    }
  }

  /// Add a new combo.
  Future<void> add(ComboProduct combo) async {
    _combos.add(combo);
    await _persist();
    notifyListeners();
  }

  /// Update an existing combo by ID.
  Future<void> update(ComboProduct updated) async {
    final index = _combos.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _combos[index] = updated;
      await _persist();
      notifyListeners();
    }
  }

  /// Delete a combo by ID.
  Future<void> delete(String id) async {
    _combos.removeWhere((c) => c.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await Cache.instance.set<String>(_cacheKey, encodeCombos(_combos));
  }
}
