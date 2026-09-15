import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../library/presentation/screens/downloads_screen.dart';
import 'edit_profile_screen.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../player/presentation/widgets/mini_player.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  int _cacheSizeBytes = 0;
  bool _loadingCacheSize = true;

  @override
  void initState() {
    super.initState();
    _refreshCacheSize();
  }

  Future<void> _refreshCacheSize() async {
    final bytes = await OfflineCacheService.instance.getTotalSizeBytes();
    if (mounted) {
      setState(() {
        _cacheSizeBytes = bytes;
        _loadingCacheSize = false;
      });
    }
  }

  String _displayName(User? user) {
    if (user == null) return 'Pengguna';
    final metaName = user.userMetadata?['display_name'] as String?;
    if (metaName != null && metaName.trim().isNotEmpty) return metaName.trim();
    final email = user.email ?? '';
    if (email.isEmpty) return 'Pengguna';
    return email.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final initial = user?.email?.substring(0, 1).toUpperCase() ?? 'U';
    final displayName = _displayName(user);
    final settings = ref.watch(settingsProvider);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : Colors.white; 
    final scaffoldBg = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final hasTrack = ref.watch(playerProvider.select((s) => s.hasTrack));

    return Scaffold(
      backgroundColor: scaffoldBg,
      bottomNavigationBar: hasTrack
          ? const SafeArea(
              top: false,
              child: MiniPlayer(),
            )
          : null,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Pengaturan', 
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: -0.5)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(currentDisplayName: displayName),
                    ),
                  );
                  if (result == true) setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                        child: Text(initial,
                            style: TextStyle(
                                color: textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName,
                                style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.4)),
                            const SizedBox(height: 4),
                            Text('Lihat Profil',
                                style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: textSecondary),
                    ],
                  ),
                ),
              ),
            ),

                  const SizedBox(height: 16),
                  
                  // Pemutaran
                  _SectionHeader(title: 'Pemutaran', color: textSecondary),
                  _SettingsGroup(
                    surfaceColor: surfaceColor,
                    children: [
                      _SettingsTile(
                        icon: Icons.high_quality_rounded,
                        iconColor: Colors.blue,
                        label: 'Kualitas Audio',
                        value: settings.audioQuality.label,
                        onTap: () => _showQualitySheet(context, settings.audioQuality),
                        isLast: false,
                      ),
                      _SettingsToggle(
                        icon: Icons.playlist_play_rounded,
                        iconColor: Colors.purple,
                        label: 'Putar Otomatis',
                        value: settings.autoplay,
                        onChanged: (val) => ref.read(settingsProvider.notifier).setAutoplay(val),
                        isLast: false,
                      ),
                      _SettingsToggle(
                        icon: Icons.cloud_off_rounded,
                        iconColor: Colors.teal,
                        label: 'Mode Hanya Offline',
                        value: settings.offlineOnly,
                        onChanged: (val) => ref.read(settingsProvider.notifier).setOfflineOnly(val),
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tampilan
                  _SectionHeader(title: 'Tampilan', color: textSecondary),
                  _SettingsGroup(
                    surfaceColor: surfaceColor,
                    children: [
                      _SettingsTile(
                        icon: Icons.dark_mode_rounded,
                        iconColor: Colors.indigo,
                        label: 'Tema Tampilan',
                        value: settings.themePreference.label,
                        onTap: () => _showThemeSheet(context, settings.themePreference),
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Penyimpanan
                  _SectionHeader(title: 'Penyimpanan', color: textSecondary),
                  _SettingsGroup(
                    surfaceColor: surfaceColor,
                    children: [
                      _SettingsTile(
                        icon: Icons.download_rounded,
                        iconColor: Colors.green,
                        label: 'Daftar Unduhan',
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const DownloadsScreen())),
                        isLast: false,
                      ),
                      _SettingsTile(
                        icon: Icons.storage_rounded,
                        iconColor: Colors.orange,
                        label: 'Cache Offline',
                        value: _loadingCacheSize ? 'Menghitung...' : OfflineCacheService.formatBytes(_cacheSizeBytes),
                        onTap: _refreshCacheSize,
                        isLast: false,
                      ),
                      _SettingsTile(
                        icon: Icons.delete_sweep_rounded,
                        iconColor: Colors.red,
                        label: 'Bersihkan Cache',
                        onTap: () => _showClearCacheDialog(context),
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bantuan
                  _SectionHeader(title: 'Bantuan & Info', color: textSecondary),
                  _SettingsGroup(
                    surfaceColor: surfaceColor,
                    children: [
                      _SettingsTile(
                        icon: Icons.bug_report_rounded,
                        iconColor: Colors.amber.shade700,
                        label: 'Laporkan Masalah',
                        onTap: () => _showFeedbackDialog(context),
                        isLast: false,
                      ),
                      _SettingsTile(
                        icon: Icons.info_rounded,
                        iconColor: Colors.blueGrey,
                        label: 'Tentang LumaApp',
                        value: 'Versi 1.0.0',
                        onTap: () => _showAbout(context),
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

            const SizedBox(height: 32),
            // Logout Button
            Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => _handleLogout(context),
                child: const Text('Keluar dari Akun', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
      );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Kamu akan keluar dari akun LumaApp.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        navigator.pushAndRemoveUntil(
          CupertinoPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showQualitySheet(BuildContext context, AudioQuality current) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Pilih Kualitas Audio',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              ...AudioQuality.values.map((quality) {
                final isSelected = quality == current;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? theme.colorScheme.primary : Colors.grey,
                  ),
                  title: Text(quality.label,
                      style: TextStyle(
                          color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                  onTap: () {
                    ref.read(settingsProvider.notifier).setAudioQuality(quality);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeSheet(BuildContext context, ThemePreference current) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Pilih Nuansa Tema',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              ...ThemePreference.values.map((pref) {
                final isSelected = pref == current;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? theme.colorScheme.primary : Colors.grey,
                  ),
                  title: Text(pref.label,
                      style: TextStyle(
                          color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                  onTap: () {
                    ref.read(settingsProvider.notifier).setThemePreference(pref);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showClearCacheDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Bersihkan Cache Musik?'),
        content: Text('Semua lagu offline (${OfflineCacheService.formatBytes(_cacheSizeBytes)}) akan dihapus.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bersihkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await OfflineCacheService.instance.clearAll();
      await _refreshCacheSize();
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Cache musik berhasil dikosongkan.')));
      }
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur pelaporan akan segera hadir.')),
    );
  }

  void _showAbout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('LumaApp'),
        content: const Text('Versi 1.0.0\n\nAplikasi pemutar musik offline-first yang berfokus pada kemurnian audio dan keterbacaan antarmuka.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final Color surfaceColor;

  const _SettingsGroup({required this.children, required this.surfaceColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.value,
    required this.onTap,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: textSecondary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: TextStyle(color: textPrimary, fontSize: 16), overflow: TextOverflow.ellipsis),
              ),
              if (value != null)
                Text(value!, style: TextStyle(color: textSecondary, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _SettingsToggle({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: textSecondary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: TextStyle(color: textPrimary, fontSize: 16), overflow: TextOverflow.ellipsis),
              ),
              Switch(
                value: value,
                activeColor: theme.colorScheme.primary,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
