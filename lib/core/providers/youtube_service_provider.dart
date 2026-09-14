import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/youtube_service.dart';

/// Singleton YouTubeService yang di-manage oleh Riverpod.
/// Semua screen/widget harus pakai ini lewat ref.read(youtubeServiceProvider)
/// bukan membuat YouTubeService() sendiri, untuk menghindari YoutubeExplode
/// instance yang menumpuk dan menyebabkan memory leak.
final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  final service = YouTubeService();
  ref.onDispose(service.dispose);
  return service;
});
