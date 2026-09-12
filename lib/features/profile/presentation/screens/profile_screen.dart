import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../library/presentation/screens/settings_screen.dart';
import '../../../library/presentation/screens/recently_played_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luma_app/features/auth/presentation/screens/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// Extract a display name from email: "user@gmail.com" → "user"
  String _displayName(User? user) {
    if (user == null) return 'Pengguna';
    final metaName = user.userMetadata?['display_name'] as String?;
    if (metaName != null && metaName.trim().isNotEmpty) return metaName.trim();
    final email = user.email ?? '';
    if (email.isEmpty) return 'Pengguna';
    return email.split('@').first;
  }

  /// Format createdAt timestamp into a human-readable Indonesian string.
  String _memberSince(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return 'Bergabung ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final initial = user?.email?.substring(0, 1).toUpperCase() ?? 'U';
    final displayName = _displayName(user);
    final memberSince = _memberSince(user?.createdAt);

    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profil', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: LumaColors.accent.withValues(alpha: 0.2),
              child: Text(initial, style: TextStyle(color: textPrimary, fontSize: 40, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
            if (memberSince.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LumaColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  memberSince,
                  style: const TextStyle(color: LumaColors.accent, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(currentDisplayName: displayName),
                    ),
                  );
                  if (result == true) {
                    // Force rebuild to get updated auth metadata
                    setState(() {});
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('Edit Profil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
            _tile(
              context,
              icon: Icons.history_rounded,
              label: 'Riwayat didengar',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentlyPlayedScreen())),
            ),
            _tile(
              context,
              icon: Icons.settings_rounded,
              label: 'Pengaturan',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: theme.dividerColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Keluar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.textTheme.bodyMedium?.color, size: 20),
      ),
      title: Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded, color: theme.dividerColor),
      onTap: onTap,
    );
  }
}
