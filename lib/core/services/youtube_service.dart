import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Search for a song on YouTube Music
  Future<List<Video>> searchMusic(String query) async {
    final searchResults = await _yt.search.search(query);
    // Alternatively, you can use the specific YouTube Music search if needed:
    // await _yt.search.search(query, filter: TypeFilters.video);
    return searchResults.toList();
  }

  /// Get the audio stream URL for a given video ID
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioInfo = manifest.audioOnly.withHighestBitrate();
      return audioInfo.url.toString();
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}
