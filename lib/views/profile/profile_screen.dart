import 'package:duwitku/views/profile/widgets/profile_header.dart';
import 'package:duwitku/views/profile/widgets/profile_menu_item.dart';
import 'package:duwitku/views/profile/widgets/profile_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showSignOutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
      // The router's refreshListenable will handle navigation
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Profile & Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfileHeader(),
            const ProfileSectionHeader(title: 'Account'),
            ProfileMenuItem(
              icon: Icons.person_outline,
              title: 'Personal Information',
              subtitle: 'Manage your account details',
              onTap: () {
                context.push('/edit_profile');
              },
            ),
            ProfileMenuItem(
              icon: Icons.category_outlined,
              title: 'Manage Categories',
              subtitle: 'Add, edit, or delete your custom categories',
              onTap: () {
                context.push('/manage_categories');
              },
            ),
            const ProfileSectionHeader(title: 'General'),
            ProfileMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage notification settings',
              onTap: () {},
            ),
            const ProfileSectionHeader(title: 'Account Actions'),
            ProfileMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out from your account',
              iconColor: Theme.of(context).colorScheme.error,
              textColor: Theme.of(context).colorScheme.error,
              showDivider: false,
              onTap: () => _showSignOutDialog(context),
            ),
            const SizedBox(height: 32),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'App Version 0.1.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.4 * 255).round()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
