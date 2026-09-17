import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:luma_app/core/updater/app_updater.dart';
import 'package:luma_app/features/auth/presentation/screens/auth_gate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class SplashUpdateScreen extends StatefulWidget {
  const SplashUpdateScreen({super.key});

  @override
  State<SplashUpdateScreen> createState() => _SplashUpdateScreenState();
}

class _SplashUpdateScreenState extends State<SplashUpdateScreen> {
  bool _isChecking = true;
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = 'Mengecek pembaruan...';
  UpdateInfo? _updateInfo;
  // Guard agar navigasi hanya terjadi sekali, mencegah layar stuck / dobel push.
  bool _navigated = false;
  
  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    try {
      final info = await AppUpdater.checkForUpdates();
      if (!mounted) return;

      if (info != null && info.hasUpdate) {
        setState(() {
          _isChecking = false;
          _updateInfo = info;
        });
        // Otomatis download seperti Valorant
        await _startDownload(info.downloadUrl);
      } else {
        await _goToMain();
      }
    } catch (e) {
      // Jangan sampai layar stuck bila pengecekan error, tetap lanjut ke main.
      debugPrint('[OTA] Update check error: $e');
      if (mounted) await _goToMain();
    }
  }

  Future<void> _goToMain() async {
    // Guard: pastikan navigasi hanya terjadi sekali.
    if (_navigated || !mounted) return;
    _navigated = true;

    // Setelah pengecekan pembaruan selesai (baik versi sudah sama, tidak ada
    // update, atau gagal cek), serahkan keputusan routing ke AuthGate.
    // AuthGate menonton onAuthStateChange Supabase secara reaktif sehingga
    // SEMUA user (login maupun logout) diarahkan ke halaman yang tepat,
    // tanpa harus melakukan pengecekan session snapshot di sini.
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _startDownload(String url) async {
    setState(() {
      _isDownloading = true;
      _statusText = 'Mengunduh patch terbaru...';
    });

    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/luma_update.apk';

      // Delete partial file from previous failed attempt
      final partialFile = File(savePath);
      if (await partialFile.exists()) await partialFile.delete();

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
        followRedirects: true,
        maxRedirects: 10,
        headers: {
          // GitHub CDN & release downloads require a browser-like User-Agent
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        },
      ));

      debugPrint('[OTA] Starting download: $url');
      await dio.download(
        url,
        savePath,
        options: Options(
          responseType: ResponseType.stream,
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _progress = (received / total).clamp(0.0, 1.0);
              _statusText =
                  'Mengunduh... ${(_progress * 100).toStringAsFixed(1)}%';
            });
          }
        },
      );

      // Validate file size (APK should be > 1MB)
      final fileSize = await partialFile.length();
      debugPrint('[OTA] Downloaded $fileSize bytes');
      if (fileSize < 1024 * 1024) {
        throw Exception(
            'File APK terlalu kecil ($fileSize bytes), kemungkinan download gagal.');
      }

      setState(() {
        _statusText = 'Membuka installer...';
      });

      // Buka APK untuk di-install
      final result = await OpenFilex.open(savePath);

      if (result.type != ResultType.done) {
        debugPrint('[OTA] OpenFilex failed: ${result.type} ${result.message}');
        setState(() {
          _statusText =
              'Tidak dapat membuka installer (${result.message}). Coba buka file APK secara manual.';
          _isDownloading = false;
        });
        await Future.delayed(const Duration(seconds: 4));
        _goToMain();
      } else {
        // Installer sistem sudah terbuka. Jika user kembali ke aplikasi (misal
        // menekan "Batal"), jangan biarkan mereka stuck di splash — langsung
        // ke main.
        _goToMain();
      }
    } catch (e) {
      debugPrint('[OTA] Download error: $e');
      setState(() {
        _statusText =
            'Gagal mengunduh: ${e.toString().replaceAll('Exception: ', '')}';
        _isDownloading = false;
      });
      await Future.delayed(const Duration(seconds: 4));
      _goToMain();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Luma
            Icon(
              Icons.graphic_eq_rounded,
              size: 80,
              color: onSurface,
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.seconds, curve: Curves.easeInOut),
             
            const SizedBox(height: 32),
            
            Text(
              _statusText,
              style: TextStyle(
                color: onSurface.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 24),

            if (_isDownloading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: onSurface.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_updateInfo != null)
                      Text(
                        'Versi: ${_updateInfo!.latestVersion}\n${_updateInfo!.releaseNotes}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              )
            else if (_isChecking)
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
