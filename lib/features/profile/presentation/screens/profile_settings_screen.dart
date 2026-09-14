import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/interactive_scale_button.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../library/presentation/screens/downloads_screen.dart';
import 'edit_profile_screen.dart';

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
    final email = user?.email ?? 'Tidak diketahui';
    final displayName = _displayName(user);
    final settings = ref.watch(settingsProvider);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : Colors.white; 
    final scaffoldBg = isDark ? Colors.black : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: scaffoldBg,
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
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  InteractiveScaleButton(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => EditProfileScreen(currentDisplayName: displayName),
                        ),
                      );
                      if (result == true) setState(() {});
                    },
                    pressedScale: 0.96,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: isDark ? const Color(0xFF2C2C2E) : LumaColors.lightBorder,
                            child: Text(initial,
                                style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 28,
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.4)),
                                const SizedBox(height: 2),
                                Text(email,
                                    style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: textSecondary.withOpacity(0.5)),
                        ],
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

                  // Logout Button
                  InteractiveScaleButton(
                    onTap: () => _handleLogout(context),
                    pressedScale: 0.96,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('Keluar dari Akun', 
                          style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
      );
  }

  Future<void> _handleLogout(BuildContext context) async {
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
        Navigator.pushAndRemoveUntil(
          context,
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
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
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
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: children,
          ),
        ),
      ),
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

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: isLast ? null : Border(
                    bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2), width: 0.5)
                  ),
                ),
                padding: const EdgeInsets.only(right: 16, top: 14, bottom: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label, style: TextStyle(color: textPrimary, fontSize: 16), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    if (value != null)
                      Flexible(
                        child: Text(value!, style: TextStyle(color: textSecondary, fontSize: 15), overflow: TextOverflow.ellipsis),
                      ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: textSecondary.withOpacity(0.5), size: 20),
                  ],
                ),
              ),
            ),
          ],
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

    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: isLast ? null : Border(
                    bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2), width: 0.5)
                  ),
                ),
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label, style: TextStyle(color: textPrimary, fontSize: 16), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    CupertinoSwitch(
                      value: value,
                      activeColor: theme.colorScheme.primary,
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
