import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_snap/features/auth/logic/auth_provider.dart';
import 'package:wallet_snap/features/categories/logic/category_provider.dart';
import 'package:wallet_snap/features/settings/logic/settings_provider.dart';

import '../../transactions/logic/transaction_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final authService = ref.read(authServiceProvider);
    final settings = ref.watch(settingsProvider);

    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileCard(context, user, colorScheme),

            const SizedBox(height: 30),

            _buildSectionHeader(colorScheme, 'Data Management'),
            const SizedBox(height: 10),

            _buildSyncControlTile(
              colorScheme.primary,
              icon: Icons.cloud_done_rounded,
              title: 'Enable Cloud Backup',
              subtitle: 'Keep your data safe on Supabase',
              trailing: Switch.adaptive(
                value: settings.isCloudBackupEnabled,
                activeTrackColor: colorScheme.primary,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).toggleCloudBackup(val);
                },
              ),
            ),
            const SizedBox(height: 12),

            _buildActionTile(
              icon: Icons.sync_rounded,
              title: 'Sync Now',
              subtitle: settings.isCloudBackupEnabled
                  ? 'Last synced: ${settings.lastSyncTime}'
                  : 'Cloud backup is disabled',
              color: colorScheme.primary,
              enabled: settings.isCloudBackupEnabled,
              onTap: () async {
                final now = DateFormat(
                  'dd MMM, hh:mm a',
                ).format(DateTime.now());
                await ref.read(settingsProvider.notifier).updateSyncTime(now);

                await ref.read(transactionProvider.notifier).syncEverything();
                await ref.read(categoryProvider.notifier).syncEverything();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sync completed successfully!'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 30),

            _buildSectionHeader(colorScheme, 'Account Settings'),
            const SizedBox(height: 10),

            _buildActionTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Sign out from your account safely',
              color: colorScheme.primary,
              onTap: () => _showLogoutDialog(context, authService),
            ),

            const SizedBox(height: 12),

            _buildActionTile(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently remove your data',
              color: colorScheme.error,
              onTap: () => _showDeleteDialog(context),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    User? user,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: colorScheme.secondary.withValues(alpha: 0.2),
            child: CircleAvatar(
              radius: 46,
              backgroundImage: user?.userMetadata?['avatar_url'] != null
                  ? NetworkImage(user!.userMetadata!['avatar_url'])
                  : const AssetImage('assets/images/default_user.png')
                        as ImageProvider,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            user?.userMetadata?['full_name']?.split(' ')[0] ??
                'WalletSnap User',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.email ?? 'user@example.com',
            style: TextStyle(color: colorScheme.secondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme colorScheme, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.outline,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildSyncControlTile(
    Color color, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        color: color.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.1)),
            color: color.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: color.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, dynamic authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pop(context); // Dialog ক্লোজ
                Navigator.pop(context); // Screen ক্লোজ
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'This action is permanent and all your data will be lost. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
