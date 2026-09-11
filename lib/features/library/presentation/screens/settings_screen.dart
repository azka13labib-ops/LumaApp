import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import 'downloads_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final initial = user?.email?.substring(0, 1).toUpperCase() ?? 'U';
    final email = user?.email ?? 'Tidak diketahui';

    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pengaturan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email,
                        style: const TextStyle(
                            color: Colors.white,
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
                        const Text('Akun Standar',
                            style: TextStyle(
                                color: LumaColors.darkTextSecondary,
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
          _SectionLabel('Pemutaran'),
          _SettingsTile(
            icon: Icons.high_quality_rounded,
            label: 'Kualitas Audio',
            subtitle: 'Otomatis (disarankan)',
            onTap: () => _showQualitySheet(context),
          ),
          _SettingsTile(
            icon: Icons.downloading_rounded,
            label: 'Unduhan',
            subtitle: 'Lagu tersimpan di perangkat',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DownloadsScreen()),
              );
            },
          ),

          const SizedBox(height: 8),
          _SectionLabel('Tampilan'),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            label: 'Tema',
            subtitle: 'Gelap OLED (Pitch Black)',
            onTap: () => _showThemeSheet(context),
          ),

          const SizedBox(height: 8),
          _SectionLabel('Tentang'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'Tentang LumaApp',
            subtitle: 'Versi 1.0.0',
            onTap: () => _showAbout(context),
          ),
          _SettingsTile(
            icon: Icons.bug_report_outlined,
            label: 'Laporkan Masalah',
            subtitle: 'Kirim masukan kendala aplikasi',
            onTap: () => _showFeedbackDialog(context),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E1E1E), height: 1),
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
                    backgroundColor: LumaColors.darkSurface,
                    title: const Text('Keluar?',
                        style: TextStyle(color: Colors.white)),
                    content: const Text(
                        'Kamu akan keluar dari akun LumaApp.',
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal',
                              style: TextStyle(color: Colors.white54))),
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

  void _showQualitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LumaColors.darkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Kualitas Audio',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.check_circle_rounded, color: LumaColors.accent),
              title: const Text('Otomatis (Tertinggi)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: const Text('Mendukung hingga 256kbps AAC / 160kbps Opus langsung dari sumber YouTube native.',
                  style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 12)),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showThemeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LumaColors.darkSurface,
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
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Tema Tampilan',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'LumaApp dirancang dengan tema Gelap OLED murni (#000000) untuk efisiensi baterai dan kenyamanan mata saat mendengarkan musik.',
                style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_rounded, color: LumaColors.accent),
                title: const Text('Gelap OLED (Aktif)',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                subtitle: const Text('Kontras optimal dengan cover art album',
                    style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 12)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LumaColors.darkSurface,
        title: const Text('Laporkan Masalah', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jelaskan kendala atau saran perbaikan yang kamu temui:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Tuliskan laporan masalah di sini...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terima kasih! Laporan masalah telah kami terima.'),
                ),
              );
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LumaColors.darkSurface,
        title: const Text('LumaApp', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Versi 1.0.0\n\nAplikasi pemutar musik offline-first yang berfokus pada kemurnian audio dan keterbacaan antarmuka.\n\n© 2026 LumaApp',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup', style: TextStyle(color: LumaColors.accent))),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(label.toUpperCase(),
          style: const TextStyle(
              color: Colors.white60,
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
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Colors.white38, size: 20),
      onTap: onTap,
    );
  }
}
