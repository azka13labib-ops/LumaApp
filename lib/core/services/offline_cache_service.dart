import 'dart:convert';
import 'package:universal_io/io.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'youtube_service.dart';

/// Best-effort local MP3 cache. YouTube / CDN URLs may expire for re-download;
/// already-saved files keep working until deleted.
class OfflineCacheService {
  OfflineCacheService._();
  static final OfflineCacheService instance = OfflineCacheService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 8),
    followRedirects: true,
    maxRedirects: 5,
    headers: {
      // YouTube / GoogleVideo CDN requires a browser-like User-Agent;
      // requests without it return 403 Forbidden.
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      'Range': 'bytes=0-',
    },
  ));

  Directory? _dir;

  /// Reactive download progress notifier: trackId -> double (0.0 to 1.0)
  final ValueNotifier<Map<String, double>> downloadProgress =
      ValueNotifier<Map<String, double>>({});

  bool isDownloading(String youtubeId) =>
      downloadProgress.value.containsKey(youtubeId);

  double? getProgress(String youtubeId) => downloadProgress.value[youtubeId];

  Future<Directory> _cacheDir() async {
    if (kIsWeb) throw UnsupportedError('File system not supported on web');
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/offline_tracks');
    if (!await dir.exists()) await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  /// Sanitizes ID to prevent path traversal vulnerabilities (CWE-22).
  /// Enforces safe alphanumeric, underscore, and hyphen characters.
  static String safeId(String rawId) {
    final sanitized = rawId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
    return sanitized.isEmpty ? 'invalid_id' : sanitized;
  }

  Future<File> _audioFile(String youtubeId) async {
    final dir = await _cacheDir();
    return File('${dir.path}/${safeId(youtubeId)}.mp3');
  }

  Future<File> _thumbFile(String youtubeId) async {
    final dir = await _cacheDir();
    return File('${dir.path}/${safeId(youtubeId)}.jpg');
  }

  Future<File> _metaFile(String youtubeId) async {
    final dir = await _cacheDir();
    return File('${dir.path}/${safeId(youtubeId)}.json');
  }

  Future<bool> isCached(String youtubeId) async {
    if (kIsWeb) return false;
    try {
      return await (await _audioFile(youtubeId)).exists();
    } catch (_) {
      return false;
    }
  }

  Future<String?> localPath(String youtubeId) async {
    if (kIsWeb) return null;
    try {
      final file = await _audioFile(youtubeId);
      if (await file.exists()) return file.path;
    } catch (_) {}
    return null;
  }

  Future<String?> localThumbnailPath(String youtubeId) async {
    if (kIsWeb) return null;
    try {
      final file = await _thumbFile(youtubeId);
      if (await file.exists()) return file.path;
    } catch (_) {}
    return null;
  }

  Future<void> download(
    MusicItem item,
    String streamUrl, {
    void Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) {
      debugPrint('[Offline] Downloading is disabled on Web.');
      return;
    }

    final file = await _audioFile(item.id);
    final thumb = await _thumbFile(item.id);
    final meta = await _metaFile(item.id);

    // Register active download
    final newMap = Map<String, double>.from(downloadProgress.value);
    newMap[item.id] = 0.05;
    downloadProgress.value = newMap;
    onProgress?.call(0.05);

    try {
      debugPrint('[Offline] Downloading ${item.title} → ${file.path}');
      await _dio.download(
        streamUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final p = (received / total).clamp(0.0, 0.95);
            final updated = Map<String, double>.from(downloadProgress.value);
            updated[item.id] = p;
            downloadProgress.value = updated;
            onProgress?.call(p);
          }
        },
      );

      // Download cover art image if available
      String? savedThumbPath;
      if (item.thumbnailUrl.isNotEmpty) {
        try {
          await _dio.download(item.thumbnailUrl, thumb.path);
          if (await thumb.exists()) {
            savedThumbPath = thumb.path;
          }
        } catch (e) {
          debugPrint('[Offline] Thumbnail download skipped/failed: $e');
        }
      }

      final audioSize = await file.length();
      final thumbSize = (savedThumbPath != null && await thumb.exists())
          ? await thumb.length()
          : 0;
      final totalSize = audioSize + thumbSize;

      await meta.writeAsString(jsonEncode({
        'id': item.id,
        'title': item.title,
        'author': item.author,
        'thumbnailUrl': item.thumbnailUrl,
        'localThumbnailPath': savedThumbPath,
        'fileSizeBytes': totalSize,
        'savedAt': DateTime.now().toIso8601String(),
      }));

      onProgress?.call(1.0);
    } finally {
      // Remove from active download map
      final doneMap = Map<String, double>.from(downloadProgress.value);
      doneMap.remove(item.id);
      downloadProgress.value = doneMap;
    }
  }

  Future<void> remove(String youtubeId) async {
    if (kIsWeb) return;
    final audio = await _audioFile(youtubeId);
    final thumb = await _thumbFile(youtubeId);
    final meta = await _metaFile(youtubeId);
    if (await audio.exists()) await audio.delete();
    if (await thumb.exists()) await thumb.delete();
    if (await meta.exists()) await meta.delete();
  }

  Future<void> clearAll() async {
    if (kIsWeb) return;
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            debugPrint('[Offline] clear entity error: $e');
          }
        }
      }
    } catch (_) {}
  }

  Future<int> getTrackSizeBytes(String youtubeId) async {
    var total = 0;
    final audio = await _audioFile(youtubeId);
    if (await audio.exists()) total += await audio.length();
    final thumb = await _thumbFile(youtubeId);
    if (await thumb.exists()) total += await thumb.length();
    return total;
  }

  Future<int> getTotalSizeBytes() async {
    final dir = await _cacheDir();
    var total = 0;
    try {
      await for (final entity in dir.list()) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    } catch (_) {}
    return total;
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  Future<List<MusicItem>> listCached() async {
    if (kIsWeb) return const [];
    final dir = await _cacheDir();
    final items = <MusicItem>[];
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final map =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        final id = map['id'] as String? ?? '';
        if (id.isEmpty) continue;
        if (!await isCached(id)) continue;

        final thumb = await _thumbFile(id);
        final hasThumb = await thumb.exists();

        final audio = await _audioFile(id);
        final size = (await audio.length()) + (hasThumb ? await thumb.length() : 0);

        items.add(MusicItem(
          id: id,
          title: map['title'] as String? ?? 'Tanpa judul',
          author: map['author'] as String? ?? 'Tidak diketahui',
          thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
          localThumbnailPath: hasThumb ? thumb.path : (map['localThumbnailPath'] as String?),
          fileSizeBytes: size,
        ));
      } catch (e) {
        debugPrint('[Offline] meta read error: $e');
      }
    }
    items.sort((a, b) => a.title.compareTo(b.title));
    return items;
  }
}
