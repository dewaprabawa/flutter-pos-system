import 'package:intl/intl.dart';
import 'package:possystem/settings/language_setting.dart';
import 'package:possystem/settings/setting.dart';

class CurrencySetting extends Setting<CurrencyTypes> {
  static CurrencySetting instance = CurrencySetting._();

  static const defaultValue = CurrencyTypes.idr;

  static const supports = <CurrencyTypes, List<num>>{
    CurrencyTypes.twd: [1, 5, 10, 50, 100, 500, 1000],
    CurrencyTypes.usd: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 5, 10, 20, 50, 100],
    CurrencyTypes.idr: [100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000],
  };

  /// Current available unit of money
  List<num> unitList = CurrencySetting.supports[CurrencyTypes.twd]!;

  /// Is this currency all int?
  bool isInt = true;

  /// Index of integer in [unitList]
  int intIndex = 0;

  CurrencySetting._() {
    value = defaultValue;
    LanguageSetting.instance.addListener(() {
      _setFormatter();
    });
  }

  void _setFormatter() {
    final locale = LanguageSetting.instance.language.locale.toString();
    formatter = NumberFormat.compact(locale: locale);
    currencyFormatter = NumberFormat.simpleCurrency(locale: locale, name: value.name.toUpperCase());
  }

  @override
  String get key => 'currency';

  String get recordName => '新台幣';

  NumberFormat formatter = NumberFormat.compact(locale: LanguageSetting.instance.language.locale.toString());

  NumberFormat currencyFormatter = NumberFormat.simpleCurrency(locale: LanguageSetting.instance.language.locale.toString(), name: defaultValue.name.toUpperCase());

  /// Ceiling [value] to currency least value
  ///
  /// 1~4 => 5
  /// 5~9 => 10
  /// 10 => 50
  /// 11~14 => 15
  /// 15~19 => 20
  /// 50 => 100
  /// 110 => 150
  num ceil(num data) {
    assert(data >= 0);

    if (data == 0) return 0;

    // if it is double ceil to int first
    if (data != data.ceil()) return data.ceil();

    final next = unitList.indexWhere((e) => e > data);
    if (next == 0 || next == 1) return unitList[next];

    final useUnits = unitList.sublist(1, next == -1 ? null : next + 1);
    for (var unit in useUnits) {
      if (data % unit != 0) {
        return (data / unit).ceil() * unit;
      }
    }

    return data;
  }

  /// Get all possible value to currency maximum
  ///
  /// Ex. 63 => [65, 70, 100, 500, 1000]
  Iterable<num> ceilToMaximum(num minimum) sync* {
    yield minimum;

    var value = minimum;
    var ceiledValue = ceil(value);
    while (ceiledValue != value) {
      yield ceiledValue;
      value = ceiledValue;
      ceiledValue = CurrencySetting.instance.ceil(ceiledValue);
    }
  }

  @override
  void initialize() {
    value = CurrencyTypes.values[service.get<int>(key) ?? defaultValue.index];
    _setMetadata(value);
    _setFormatter();
  }

  @override
  Future<void> updateRemotely(CurrencyTypes data) {
    return service.set<int>(key, data.index);
  }

  void _setMetadata(CurrencyTypes value) {
    unitList = supports[value]!;

    // index when money start using int
    intIndex = 0;
    for (var money in unitList) {
      if (money.toInt() == money) break;
      intIndex++;
    }

    isInt = intIndex == 0;
  }
}

enum CurrencyTypes {
  twd,
  usd,
  idr,
}
