import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  bool _saving = false;
  int _selectedColor = 0;

  // Preset gradient themes for playlist cover
  static const _gradients = [
    [Color(0xFF0055FF), Color(0xFF00C6FB)], // Blue (default)
    [Color(0xFF7928CA), Color(0xFFFF0080)], // Purple-Pink
    [Color(0xFF11998E), Color(0xFF38EF7D)], // Green
    [Color(0xFFFC4A1A), Color(0xFFF7B733)], // Orange
    [Color(0xFF1A1A2E), Color(0xFF16213E)], // Midnight
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameController.clear();
      setState(() {});
      return;
    }
    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('playlists').insert({
          'user_id': user.id,
          'name': name,
        });
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: Colors.red.shade900,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[_selectedColor];
    final hasText = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── Hero cover art ──
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: LumaColors.darkBg,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1),
                          ),
                          child: const Icon(Icons.queue_music_rounded,
                              color: Colors.white, size: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasText ? _nameController.text.trim() : 'Playlist Baru',
                          style: TextStyle(
                            color: Colors.white
                                .withValues(alpha: hasText ? 1.0 : 0.5),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Label ──
                    const Text('Nama Playlist',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 8),

                    // ── Name Input ──
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: LumaColors.darkSurface,
                        hintText: 'Mis. Lagu Santai, Workout Mix...',
                        hintStyle: const TextStyle(
                            color: Colors.white24, fontSize: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: LumaColors.accent.withValues(alpha: 0.6),
                              width: 1.5),
                        ),
                        suffixIcon: hasText
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white38, size: 18),
                                onPressed: () {
                                  _nameController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Color picker ──
                    const Text('Warna Cover',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(_gradients.length, (i) {
                        final g = _gradients[i];
                        final selected = i == _selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            width: selected ? 42 : 36,
                            height: selected ? 42 : 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: g,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(
                                      color: Colors.white, width: 2.5)
                                  : null,
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                          color:
                                              g[0].withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 1)
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 36),

                    // ── Create Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                hasText ? LumaColors.accent : LumaColors.darkSurface,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: hasText && !_saving ? _create : null,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(
                                  'Buat Playlist',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: hasText
                                        ? Colors.white
                                        : Colors.white30,
                                  ),
                                ),
                        ),
                      ),
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
