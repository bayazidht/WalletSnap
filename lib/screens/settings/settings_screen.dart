import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_snap/data/default_currencies.dart';
import 'package:wallet_snap/screens/settings/account_screen.dart';
import 'package:wallet_snap/screens/settings/manage_categories_screen.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

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
              _buildCurrencyTile(context, colorScheme, settingsProvider),
            ],
          ),
          const SizedBox(height: 24),

          _buildSettingsGroup(
            colorScheme,
            title: 'Appearance',
            items: [
              _buildDarkModeTile(context, colorScheme, themeProvider)
            ],
          ),
          const SizedBox(height: 24),

          _buildSettingsGroup(
            colorScheme,
            title: 'Information',
            items: [
              _buildListTile(
                context,
                icon: Icons.favorite_border_rounded,
                title: 'About Us',
                onTap: () => {},
              ),
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

  Widget _buildProfileSection(BuildContext context, User? user, ColorScheme colorScheme) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountScreen()),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
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
                  Text(
                    user?.userMetadata?['full_name']?.split(' ')[0] ?? 'WalletSnap User',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? 'No email available',
                    style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
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
          child: Text(
              title.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.outline, letterSpacing: 1.1)
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              int idx = entry.key;
              Widget widget = entry.value;
              return Column(
                children: [
                  widget,
                  if (idx != items.length - 1)
                    Divider(height: 1, indent: 60, endIndent: 20, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: colorScheme.outline, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildCurrencyTile(BuildContext context, ColorScheme colorScheme, SettingsProvider settingsProvider) {
    return _buildListTile(
      context,
      icon: Icons.payments_outlined,
      title: 'Currency',
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          borderRadius: BorderRadius.circular(16),
          value: settingsProvider.selectedCurrency,
          icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
          onChanged: (val) => val != null ? settingsProvider.setCurrency(val) : null,
          items: defaultCurrencies.map((c) => DropdownMenuItem(
              value: c.symbol,
              child: Text(c.code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildDarkModeTile(BuildContext context, ColorScheme colorScheme, ThemeProvider themeProvider) {
    return _buildListTile(
      context,
      icon: Icons.dark_mode_outlined,
      title: 'Dark Theme',
      trailing: Switch.adaptive(
        value: themeProvider.isDarkMode,
        activeTrackColor: colorScheme.primary,
        onChanged: (val) => themeProvider.toggleTheme(val),
      ),
    );
  }
}