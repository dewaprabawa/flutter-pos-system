import 'package:flutter_test/flutter_test.dart';
import 'package:possystem/settings/language_setting.dart';

void main() {
  group('Language Setting', () {
    test('Parse language', () {
      final l = LanguageSetting.instance;
      expect(l.parseLanguage(''), isNull);
      expect(l.parseLanguage('something'), equals(null));
      expect(l.parseLanguage('id'), equals(Language.id));
      expect(l.parseLanguage('id_ID'), equals(Language.id));
      expect(l.parseLanguage('en'), equals(Language.en));
      expect(l.parseLanguage('en_US'), equals(Language.en));
    });
  });
}
