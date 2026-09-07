import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../../../core/theme/app_theme.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isLoading = true;
  List<MusicItem> _favorites = [];

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('liked_songs')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _favorites = (data as List).map((row) => MusicItem(
          id: row['youtube_id'],
          title: row['title'],
          author: row['author'],
          thumbnailUrl: row['thumbnail_url'],
        )).toList();
      });
    } catch (e) {
      // Jika error (misal tabel belum dibuat), abaikan saja agar tidak crash
      debugPrint('[LumaApp] Error fetching favorites: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    // main.dart akan otomatis kembali ke LoginScreen
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Saya'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: cs.primary),
            onPressed: _logout,
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2))
          : _favorites.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Belum ada lagu favorit.\nKlik tombol ❤️ pada pemutar musik untuk menambahkan.',
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _favorites.length,
                  separatorBuilder: (_, __) => const Divider(indent: 76, endIndent: 16, height: 1),
                  itemBuilder: (context, i) {
                    final item = _favorites[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item.thumbnailUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: -0.2),
                      ),
                      subtitle: Text(item.author, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.favorite, size: 18, color: Colors.redAccent),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(playlist: _favorites, initialIndex: i),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
