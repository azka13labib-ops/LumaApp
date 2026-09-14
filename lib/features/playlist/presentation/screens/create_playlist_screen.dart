import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  bool _saving = false;
  XFile? _coverImage;
  Uint8List? _coverBytes;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canCreate => _nameController.text.trim().isNotEmpty && !_saving;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _coverImage = image;
        _coverBytes = bytes;
      });
    }
  }

  Future<void> _create() async {
    if (!_canCreate) return;
    final name = _nameController.text.trim();
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await Supabase.instance.client.from('user_profiles').upsert({
            'id': user.id,
            'username': user.userMetadata?['username'] ?? user.email?.split('@').first ?? 'User',
            'avatar_url': user.userMetadata?['avatar_url'] ?? '',
          });
        } catch (_) {}
        String? coverUrl;
        if (_coverImage != null && _coverBytes != null) {
          final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await Supabase.instance.client.storage
              .from('playlist-covers')
              .uploadBinary(
                fileName, 
                _coverBytes!,
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );
          coverUrl = Supabase.instance.client.storage
              .from('playlist-covers')
              .getPublicUrl(fileName);
        }

        await Supabase.instance.client.from('playlists').insert({
          'user_id': user.id,
          'name': name,
          if (coverUrl != null) 'cover_url': coverUrl,
        });
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal membuat playlist: $e'),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _nameController.text.trim().isNotEmpty;
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final textSecondary = theme.textTheme.labelSmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Tutup',
        ),
        title: Text(
          'Playlist baru',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Divider(height: 1, color: theme.dividerColor),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      image: _coverBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_coverBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _coverBytes == null
                        ? Center(
                            child: hasText
                                ? Text(
                                    _nameController.text.trim()[0].toUpperCase(),
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 64,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -2,
                                    ),
                                  )
                                : Icon(
                                    Icons.add_a_photo_rounded,
                                    color: theme.dividerColor,
                                    size: 48,
                                  ),
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _focusNode.requestFocus,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded,
                          color: textSecondary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        hasText ? 'Edit nama' : 'Tambah nama',
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                TextField(
                  controller: _nameController,
                  focusNode: _focusNode,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _create(),
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nama playlist',
                    hintStyle: TextStyle(
                        color: textSecondary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: theme.dividerColor, width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
                          width: 2),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                const SizedBox(height: 8),
                if (_nameController.text.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_nameController.text.length}/50',
                      style: TextStyle(
                          color: textSecondary, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(),

          Padding(
            padding: EdgeInsets.fromLTRB(
                24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasText ? theme.colorScheme.primary : theme.colorScheme.surface,
                  foregroundColor:
                      hasText ? theme.colorScheme.onPrimary : textSecondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _canCreate ? _create : null,
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ))
                    : Text(
                        hasText ? 'Buat Playlist' : 'Masukkan Nama Playlist',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: hasText ? theme.colorScheme.onPrimary : textSecondary,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
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
