import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:possystem/components/sign_in_button.dart';
import 'package:possystem/components/style/outlined_text.dart';
import 'package:possystem/components/style/pop_button.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/services/auth.dart';
import 'package:possystem/settings/checkout_warning.dart';
import 'package:possystem/settings/collect_events_setting.dart';
import 'package:possystem/settings/language_setting.dart';
import 'package:possystem/settings/order_awakening_setting.dart';
import 'package:possystem/settings/theme_setting.dart';
import 'package:possystem/translator.dart';

class SettingsPage extends StatelessWidget {
  final String? focus;

  const SettingsPage({
    super.key,
    this.focus,
  });

  @override
  Widget build(BuildContext context) {
    const flavor = String.fromEnvironment('appFlavor');
    final theme = Theme.of(context);

    void navigateTo(Feature feature) {
      context.pushNamed(Routes.settingsFeature, pathParameters: {'feature': feature.name});
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: <Widget>[
          _buildProfileSection(context),
          const SizedBox(height: 24),
          _SettingsGroup(
            title: S.settingThemeTitle,
            children: [
              ListenableBuilder(
                listenable: ThemeSetting.instance,
                builder: (context, _) => _SettingsTile(
                  key: const Key('feature.theme'),
                  icon: Icons.palette_outlined,
                  title: S.settingThemeTitle,
                  subtitle: S.settingThemeName(ThemeSetting.instance.value.name),
                  onTap: () => navigateTo(Feature.theme),
                ),
              ),
              ListenableBuilder(
                listenable: LanguageSetting.instance,
                builder: (context, _) => _SettingsTile(
                  key: const Key('feature.language'),
                  icon: Icons.language_outlined,
                  title: S.settingLanguageTitle,
                  subtitle: LanguageSetting.instance.language.title,
                  onTap: () => navigateTo(Feature.language),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsGroup(
            title: S.settingCheckoutWarningTitle,
            children: [
              ListenableBuilder(
                listenable: CheckoutWarningSetting.instance,
                builder: (context, _) => _SettingsTile(
                  key: const Key('feature.checkout_warning'),
                  icon: Icons.store_mall_directory_outlined,
                  title: S.settingCheckoutWarningTitle,
                  subtitle: S.settingCheckoutWarningName(CheckoutWarningSetting.instance.value.name),
                  onTap: () => navigateTo(Feature.checkoutWarning),
                ),
              ),
              ListenableBuilder(
                listenable: OrderAwakeningSetting.instance,
                builder: (context, _) => _SettingsSwitchTile(
                  key: const Key('feature.order_awakening'),
                  icon: Icons.remove_red_eye_outlined,
                  title: S.settingOrderAwakeningTitle,
                  subtitle: S.settingOrderAwakeningDescription,
                  value: OrderAwakeningSetting.instance.value,
                  onChanged: (value) => OrderAwakeningSetting.instance.update(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsGroup(
            title: S.settingReportTitle,
            children: [
              ListenableBuilder(
                listenable: CollectEventsSetting.instance,
                builder: (context, _) => _SettingsSwitchTile(
                  key: const Key('feature.collect_events'),
                  icon: Icons.report_outlined,
                  title: S.settingReportTitle,
                  subtitle: S.settingReportDescription,
                  value: CollectEventsSetting.instance.value,
                  onChanged: (value) => CollectEventsSetting.instance.update(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (info != null) Text(S.settingVersion(info.version), style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8.0),
                      OutlinedText((kDebugMode ? '_' : '') + flavor.toUpperCase()),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SignInButton(
          signedInWidgetBuilder: (user) => Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(user.displayName.characters.first.toUpperCase()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.settingWelcome(user.displayName),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(user.email, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              TextButton(
                key: const Key('feature.sign_out'),
                onPressed: () => Auth.instance.signOut(),
                child: Text(S.settingLogoutBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class ItemListScaffold extends StatelessWidget {
  final Feature feature;

  const ItemListScaffold({
    super.key,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = ValueNotifier<int>(feature.selected);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(feature.title),
        leading: const PopButton(),
      ),
      body: ValueListenableBuilder(
        valueListenable: selected,
        builder: (context, value, child) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: feature.itemTitles.length,
          itemBuilder: (context, index) {
            final isSelected = value == index;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: isSelected ? 0 : 0,
              color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: ListTile(
                title: Text(
                  feature.itemTitles.elementAt(index),
                  style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                ),
                subtitle: Text(feature.itemSubtitles.elementAt(index)),
                trailing: isSelected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
                onTap: () async {
                  if (value != index) {
                    selected.value = index;
                    await feature.update(index);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

enum Feature {
  theme(),
  language(),
  checkoutWarning();

  const Feature();

  Iterable<String> get itemTitles {
    return switch (this) {
      Feature.theme => ThemeMode.values.map((e) => S.settingThemeName(e.name)),
      Feature.language => Language.values.map((e) => e.title),
      Feature.checkoutWarning => CheckoutWarningTypes.values.map((e) => S.settingCheckoutWarningName(e.name)),
    };
  }

  Iterable<String> get itemSubtitles {
    return switch (this) {
      Feature.theme => ThemeMode.values.map((e) => ''),
      Feature.language => Language.values.map((e) => ''),
      Feature.checkoutWarning => CheckoutWarningTypes.values.map((e) => S.settingCheckoutWarningTip(e.name)),
    };
  }

  String get title {
    return switch (this) {
      Feature.theme => S.settingThemeTitle,
      Feature.language => S.settingLanguageTitle,
      Feature.checkoutWarning => S.settingCheckoutWarningTitle,
    };
  }

  int get selected {
    return switch (this) {
      Feature.theme => ThemeSetting.instance.value.index,
      Feature.language => LanguageSetting.instance.language.index,
      Feature.checkoutWarning => CheckoutWarningSetting.instance.value.index,
    };
  }

  Future<void> update(int index) {
    return switch (this) {
      Feature.theme => ThemeSetting.instance.update(ThemeMode.values[index]),
      Feature.language => LanguageSetting.instance.update(Language.values[index]),
      Feature.checkoutWarning => CheckoutWarningSetting.instance.update(CheckoutWarningTypes.values[index]),
    };
  }
}
