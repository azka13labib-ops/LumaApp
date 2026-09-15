import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
  });
}

class AppUpdater {
  // Ganti URL ini dengan URL raw JSON Anda (misal dari GitHub Gist)
  // Format JSON yang diharapkan:
  // {
  //   "latest_version": "1.0.1",
  //   "download_url": "https://link-ke-apk-anda.com/app-release.apk",
  //   "release_notes": "Perbaikan bug dan penambahan fitur baru!"
  // }
  static const String _configUrl =
      'https://gist.githubusercontent.com/azka13labib-ops/0f72922f59b56efebf4ec63ccbb9a96e/raw/';

  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final dio = Dio();
      // Tambahkan timeout agar tidak menggantung jika koneksi lambat
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 5);

      final response = await dio.get(_configUrl);
      if (response.statusCode == 200) {
        // Jika JSON dari raw GitHub Gist biasanya berupa string, kita parse
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        
        final latestVersion = data['latest_version'] as String;
        final downloadUrl = data['download_url'] as String? ?? '';
        final releaseNotes = data['release_notes'] as String? ?? 'Ada pembaruan baru!';
        final forceUpdate = data['force_update'] as bool? ?? false;

        // Validasi: skip update jika download_url kosong atau masih placeholder
        final isValidUrl = downloadUrl.startsWith('https://') &&
            !downloadUrl.contains('link-ke-file') &&
            !downloadUrl.contains('placeholder') &&
            downloadUrl.endsWith('.apk');

        final hasUpdate = latestVersion != currentVersion && isValidUrl;

        return UpdateInfo(
          hasUpdate: hasUpdate,
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
          forceUpdate: forceUpdate,
        );
      }
    } catch (e) {
      // Jika gagal cek update (misal tidak ada internet), kita biarkan saja lolos
      print('Gagal mengecek update: $e');
    }
    return null;
  }
}
