import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:luma_app/core/services/youtube_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final YouTubeService _ytService = YouTubeService();
  final TextEditingController _searchController = TextEditingController();
  List<Video> _searchResults = [];
  bool _isLoading = false;

  void _search(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
    });
    
    try {
      final results = await _ytService.searchMusic(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Cari lagu atau artis...',
            border: InputBorder.none,
          ),
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_searchController.text),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final video = _searchResults[index];
                return ListTile(
                  leading: Image.network(
                    video.thumbnails.mediumResUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(video.author, maxLines: 1),
                  onTap: () {
                    // TODO: Mainkan lagu
                  },
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _ytService.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
