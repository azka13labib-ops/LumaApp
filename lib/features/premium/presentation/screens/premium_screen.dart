import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

typedef _Feature = ({IconData icon, String title, String subtitle});

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isNotified = false;

  static const List<_Feature> _features = [
    (icon: Icons.block_rounded, title: 'Bebas iklan', subtitle: 'Putar jutaan lagu tanpa jeda iklan komersial.'),
    (icon: Icons.download_rounded, title: 'Unduh offline', subtitle: 'Simpan lagu ke perangkat dan dengarkan tanpa koneksi internet.'),
    (icon: Icons.shuffle_rounded, title: 'Kontrol antrean bebas', subtitle: 'Atur, ubah urutan, dan acak lagu sesukamu tanpa batasan.'),
    (icon: Icons.high_quality_rounded, title: 'Audio jernih native', subtitle: 'Kualitas stream hingga 256 kbps AAC / 160 kbps Opus langsung dari sumber YouTube.'),
    (icon: Icons.skip_next_rounded, title: 'Skip tanpa batas', subtitle: 'Lewati lagu sepuasnya tanpa batas kuota harian.'),
  ];

  void _toggleNotification() {
    setState(() => _isNotified = !_isNotified);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isNotified
            ? 'Pengingat aktif! Kamu akan diberitahu saat paket Premium dirilis.'
            : 'Pengingat notifikasi dibatalkan.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: LumaColors.darkBg,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: LumaColors.darkSurface,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: LumaColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.workspace_premium_rounded,
                            color: LumaColors.accent, size: 32),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Luma Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Segera hadir: daftar untuk menerima pengingat',
                        style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manfaat Mendatang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._features.map((f) => _FeatureRow(feature: f)),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _toggleNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isNotified ? LumaColors.darkSurface : LumaColors.accent,
                        foregroundColor: _isNotified ? Colors.white : Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: _isNotified
                              ? const BorderSide(color: Colors.white24, width: 1)
                              : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isNotified ? Icons.check_circle_rounded : Icons.notifications_active_rounded,
                            size: 20,
                            color: _isNotified ? LumaColors.accent : Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isNotified ? 'Pengingat Aktif (Batalkan)' : 'Ingatkan Saya Saat Rilis',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: _isNotified ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 160),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: LumaColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: LumaColors.accent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.subtitle,
                  style: const TextStyle(
                    color: LumaColors.darkTextSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
