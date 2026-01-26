import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_snap/features/categories/ui/manage_categories_screen.dart';
import '../../../core/constants/default_currencies.dart';
import '../logic/settings_provider.dart';
import '../../../core/theme/theme_provider.dart';
import 'account_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final themeMode = ref.watch(themeProvider);
    final currencyCode = ref.watch(settingsProvider).currency;

    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: <Widget>[
          _buildProfileSection(context, user, colorScheme),
          const SizedBox(height: 32),

          _buildSettingsGroup(
            colorScheme,
            title: 'General',
            items: [
              _buildListTile(
                context,
                icon: Icons.category_outlined,
                title: 'Manage Categories',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen())),
              ),
              _buildCurrencyTile(context, colorScheme, ref, currencyCode),
            ],
          ),
          const SizedBox(height: 24),

          _buildSettingsGroup(
            colorScheme,
            title: 'Appearance',
            items: [
              _buildDarkModeTile(context, colorScheme, ref, themeMode)
            ],
          ),
          const SizedBox(height: 24),

          _buildSettingsGroup(
            colorScheme,
            title: 'Information',
            items: [
              _buildListTile(context, icon: Icons.favorite_border_rounded, title: 'About Us'),
              _buildListTile(
                context,
                icon: Icons.info_outline_rounded,
                title: 'App Version',
                trailing: Text('1.0.0', style: TextStyle(color: colorScheme.outline, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSettingsGroup(
            colorScheme,
            title: 'Support',
            items: [
              _buildListTile(
                context,
                icon: Icons.email_outlined,
                title: 'Contact Us',
                onTap: () => {},
              ),
              _buildListTile(
                context,
                icon: Icons.verified_user_outlined,
                title: 'Privacy Policy',
                onTap: () => {},
              ),
            ],
          ),
          const SizedBox(height: 50)
        ],
      ),
    );
  }

  Widget _buildCurrencyTile(BuildContext context, ColorScheme colorScheme, WidgetRef ref, String currencyCode) {

    return _buildListTile(
      context,
      icon: Icons.payments_outlined,
      title: 'Currency',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currencyCode,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _showCurrencyPicker(context, colorScheme, ref, currencyCode),
    );
  }

  void _showCurrencyPicker(BuildContext context, ColorScheme colorScheme, WidgetRef ref, String currencyCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Currency',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: defaultCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = defaultCurrencies[index];
                  final isSelected = currency.code == currencyCode;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                      child: Text(
                        currency.symbol,
                        style: TextStyle(
                          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('${currency.name} (${currency.code})',
                      style: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: colorScheme.primary)
                        : null,
                    onTap: () {
                      ref.read(settingsProvider.notifier).setCurrency(currency.code);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildDarkModeTile(BuildContext context, ColorScheme colorScheme, WidgetRef ref, ThemeMode currentMode) {
    return _buildListTile(
      context,
      icon: Icons.dark_mode_outlined,
      title: 'Dark Theme',
      trailing: Switch.adaptive(
        value: currentMode == ThemeMode.dark,
        activeTrackColor: colorScheme.primary,
        onChanged: (isDark) {
          ref.read(themeProvider.notifier).setTheme(
            isDark ? ThemeMode.dark : ThemeMode.light,
          );
        },
      ),
    );
  }


  Widget _buildProfileSection(BuildContext context, User? user, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colorScheme.primary,
              backgroundImage: user?.userMetadata?['avatar_url'] != null
                  ? NetworkImage(user!.userMetadata!['avatar_url'])
                  : const AssetImage('assets/images/default_user.png') as ImageProvider,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.userMetadata?['full_name']?.split(' ')[0] ?? 'WalletSnap User',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  Text(user?.email ?? 'No email available',
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colorScheme.outline, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(ColorScheme colorScheme, {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(title.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.outline, letterSpacing: 1.1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              return Column(
                children: [
                  entry.value,
                  if (entry.key != items.length - 1)
                    Divider(height: 1, indent: 60, endIndent: 20, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, Widget? trailing, VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: colorScheme.outline, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}