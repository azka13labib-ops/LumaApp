import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

/// Design Read: musik app, dark theme, ENERGY 2 / RHYTHM 2 / MOTION 1
/// Focal point: nama input. Satu aksen lime pada tombol aktif.
/// Tidak ada dekorasi tanpa tujuan.
class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    // Fokus otomatis ke input: satu focal point, langsung ke tindakan
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canCreate => _nameController.text.trim().isNotEmpty && !_saving;

  Future<void> _create() async {
    if (!_canCreate) return;
    final name = _nameController.text.trim();
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
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
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal membuat playlist: $e'),
          backgroundColor: const Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      appBar: AppBar(
        backgroundColor: LumaColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Tutup',
        ),
        title: const Text(
          'Playlist baru',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: Color(0xFF1A1A1A)),

          // ── Cover placeholder + input ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
            child: Column(
              children: [
                // Cover art placeholder: satu focal point di tengah
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: hasText
                      ? Center(
                          child: Text(
                            _nameController.text.trim()[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 64,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -2,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.music_note_rounded,
                          color: Color(0xFF444444),
                          size: 48,
                        ),
                ),

                // Tap to edit hint: ringan, bukan dekorasi
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _focusNode.requestFocus(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded,
                          color: Colors.white54, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        hasText ? 'Edit nama' : 'Tambah nama',
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Name input: focal point utama layar ini
                TextField(
                  controller: _nameController,
                  focusNode: _focusNode,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _create(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nama playlist',
                    hintStyle: const TextStyle(
                        color: Color(0xFF444444),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF333333), width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: LumaColors.accent.withValues(alpha: 0.8),
                          width: 2),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                const SizedBox(height: 8),
                // Karakter counter: info, bukan dekorasi
                if (_nameController.text.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_nameController.text.length}/50',
                      style: const TextStyle(
                          color: Colors.white30, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // Tombol utama di bawah: CTA spesifik
          Padding(
            padding: EdgeInsets.fromLTRB(
                24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasText ? LumaColors.accent : const Color(0xFF1A1A1A),
                  foregroundColor:
                      hasText ? Colors.black : Colors.white38,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _canCreate ? _create : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ))
                    : Text(
                        hasText ? 'Buat Playlist' : 'Masukkan Nama Playlist',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: hasText ? Colors.black : Colors.white38,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
