import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import 'downloads_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final initial = user?.email?.substring(0, 1).toUpperCase() ?? 'U';
    final email = user?.email ?? 'Tidak diketahui';
    final settings = ref.watch(settingsProvider);
    
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;
    final surfaceColor = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Pengaturan',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          // ── Profil ──
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: LumaColors.accent.withValues(alpha: 0.3),
                  child: Text(initial,
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email,
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: LumaColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Akun Standar',
                            style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          _SectionLabel('Akun'),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            label: 'Informasi Profil',
            subtitle: email,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),

          const SizedBox(height: 8),
          _SectionLabel('Pemutaran', textColor: textSecondary),
          _SettingsTile(
            icon: Icons.high_quality_rounded,
            label: 'Kualitas Audio',
            subtitle: settings.audioQuality.label,
            onTap: () => _showQualitySheet(context, settings.audioQuality),
          ),
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            secondary: Icon(Icons.playlist_play_rounded, color: textPrimary, size: 24),
            title: Text('Putar Otomatis (Autoplay)',
                style: TextStyle(color: textPrimary, fontSize: 15)),
            subtitle: Text(
              'Lanjutkan pemutaran musik serupa saat antrean habis',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            value: settings.autoplay,
            activeColor: LumaColors.accent,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setAutoplay(val);
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            secondary: Icon(Icons.cloud_off_rounded, color: textPrimary, size: 24),
            title: Text('Mode Hanya Offline',
                style: TextStyle(color: textPrimary, fontSize: 15)),
            subtitle: Text(
              'Hanya putar lagu yang telah tersimpan di perangkat',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            value: settings.offlineOnly,
            activeColor: LumaColors.accent,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setOfflineOnly(val);
            },
          ),
          _SettingsTile(
            icon: Icons.downloading_rounded,
            label: 'Daftar Unduhan',
            subtitle: 'Lagu tersimpan di perangkat',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DownloadsScreen()),
              );
            },
          ),

          const SizedBox(height: 8),
          _SectionLabel('Tampilan', textColor: textSecondary),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            label: 'Tema Tampilan',
            subtitle: settings.themePreference.label,
            onTap: () => _showThemeSheet(context, settings.themePreference),
          ),

          const SizedBox(height: 8),
          _SectionLabel('Penyimpanan & Cache', textColor: textSecondary),
          _SettingsTile(
            icon: Icons.storage_rounded,
            label: 'Cache Musik Offline',
            subtitle: _loadingCacheSize
                ? 'Menghitung ukuran...'
                : OfflineCacheService.formatBytes(_cacheSizeBytes),
            onTap: _refreshCacheSize,
          ),
          _SettingsTile(
            icon: Icons.delete_sweep_rounded,
            label: 'Bersihkan Cache Musik',
            subtitle: 'Kosongkan penyimpanan lagu yang diunduh',
            onTap: () => _showClearCacheDialog(context),
          ),

          const SizedBox(height: 8),
          _SectionLabel('Notifikasi', textColor: textSecondary),
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            secondary: Icon(Icons.notifications_active_outlined, color: textPrimary, size: 24),
            title: Text('Kontrol di Bilah Notifikasi',
                style: TextStyle(color: textPrimary, fontSize: 15)),
            subtitle: Text(
              'Tampilkan kontrol pemutar musik di bilah status dan lockscreen',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            value: settings.showNotificationControls,
            activeColor: LumaColors.accent,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setShowNotificationControls(val);
            },
          ),

          const SizedBox(height: 8),
          _SectionLabel('Bantuan & Informasi', textColor: textSecondary),
          _SettingsTile(
            icon: Icons.bug_report_outlined,
            label: 'Laporkan Masalah',
            subtitle: 'Kirim masukan atau laporan kendala aplikasi',
            onTap: () => _showFeedbackDialog(context),
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'Tentang LumaApp',
            subtitle: 'Versi 1.0.0',
            onTap: () => _showAbout(context),
          ),

          const SizedBox(height: 16),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 8),

          // ── Logout ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.red.shade900, width: 1)),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: surfaceColor,
                    title: Text('Keluar?',
                        style: TextStyle(color: textPrimary)),
                    content: Text(
                        'Kamu akan keluar dari akun LumaApp.',
                        style: TextStyle(color: textSecondary)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Batal',
                              style: TextStyle(color: textSecondary))),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Keluar',
                              style: TextStyle(color: Colors.red.shade400))),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Keluar dari Akun',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showQualitySheet(BuildContext context, AudioQuality current) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Pilih Kualitas Audio',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              ...AudioQuality.values.map((quality) {
                final isSelected = quality == current;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected ? LumaColors.accent : textSecondary,
                  ),
                  title: Text(quality.label,
                      style: TextStyle(
                          color: isSelected ? LumaColors.accent : textPrimary,
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500)),
                  subtitle: Text(quality.description,
                      style: TextStyle(
                          color: textSecondary, fontSize: 12)),
                  onTap: () {
                    ref
                        .read(settingsProvider.notifier)
                        .setAudioQuality(quality);
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
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Pilih Nuansa Tema',
                  style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Pilih varian tema gelap sesuai preferensi layar dan kenyamanan visual kamu.',
                style: TextStyle(
                    color: textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              ...ThemePreference.values.map((theme) {
                final isSelected = theme == current;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected ? LumaColors.accent : textSecondary,
                  ),
                  title: Text(theme.label,
                      style: TextStyle(
                          color: isSelected ? LumaColors.accent : textPrimary,
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600)),
                  subtitle: Text(theme.description,
                      style: TextStyle(
                          color: textSecondary, fontSize: 12)),
                  onTap: () {
                    ref
                        .read(settingsProvider.notifier)
                        .setThemePreference(theme);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showClearCacheDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Bersihkan Cache Musik?',
            style: TextStyle(color: textPrimary)),
        content: Text(
          'Tindakan ini akan menghapus semua lagu offline (${OfflineCacheService.formatBytes(_cacheSizeBytes)}) dari penyimpanan perangkat. Akun dan daftar putar kamu tetap aman.',
          style: TextStyle(color: textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
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
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Cache musik berhasil dikosongkan.'),
          ),
        );
      }
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    String selectedCategory = 'Kendala Pemutaran Lagu';
    final categories = [
      'Kendala Pemutaran Lagu',
      'Masalah Tampilan Antarmuka',
      'Saran Fitur Baru',
      'Masalah Akun',
      'Lainnya',
    ];

    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('Laporkan Masalah',
              style: TextStyle(color: textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kategori Masalah:',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: theme.colorScheme.surface,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      items: categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Deskripsi Masalah:',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Tuliskan detail kendala atau saran kamu di sini...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Silakan tuliskan deskripsi masalah sebelum mengirim.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Laporan untuk "$selectedCategory" telah dikirim. Terima kasih atas masukan kamu!'),
                  ),
                );
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('LumaApp', style: TextStyle(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versi 1.0.0 (Build Rilis)\n\nAplikasi pemutar musik offline-first yang berfokus pada kemurnian audio dan keterbacaan antarmuka pengguna tanpa distorsi.',
              style: TextStyle(color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Kebijakan Privasi: LumaApp menghargai privasi kamu. Data koleksi dan riwayat pemutaran disimpan secara privat dan aman.',
              style: TextStyle(
                  color: textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              icon: const Icon(Icons.library_books_rounded, size: 16, color: LumaColors.accent),
              label: const Text('Lisensi Sumber Terbuka',
                  style: TextStyle(color: LumaColors.accent, fontSize: 13)),
              onPressed: () {
                Navigator.pop(ctx);
                showLicensePage(
                  context: context,
                  applicationName: 'LumaApp',
                  applicationVersion: '1.0.0',
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup',
                  style: TextStyle(color: LumaColors.accent))),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.textColor});
  final String label;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: textColor ?? Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    return ListTile(
      leading: Icon(icon, color: textSecondary, size: 22),
      title: Text(label,
          style: TextStyle(color: textPrimary, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(
                  color: textSecondary, fontSize: 12))
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          color: textSecondary.withValues(alpha: 0.5), size: 20),
      onTap: onTap,
    );
  }
}
