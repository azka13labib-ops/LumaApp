import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:luma_app/core/updater/app_updater.dart';
import 'package:luma_app/features/auth/presentation/screens/welcome_screen.dart';
import 'package:luma_app/main.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  
  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    final info = await AppUpdater.checkForUpdates();
    if (!mounted) return;

    if (info != null && info.hasUpdate) {
      setState(() {
        _isChecking = false;
        _updateInfo = info;
      });
      // Otomatis download seperti Valorant
      _startDownload(info.downloadUrl);
    } else {
      _goToMain();
    }
  }

  void _goToMain() {
    final user = Supabase.instance.client.auth.currentUser;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => user == null ? const WelcomeScreen() : const MainShell(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
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
      
      final dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              _statusText = 'Mengunduh... ${( _progress * 100).toStringAsFixed(1)}%';
            });
          }
        },
      );

      setState(() {
        _statusText = 'Membuka installer...';
      });

      // Buka APK untuk di-install
      final result = await OpenFilex.open(savePath);
      
      if (result.type != ResultType.done) {
        setState(() {
          _statusText = 'Gagal menginstal. Silakan coba lagi nanti.';
          _isDownloading = false;
        });
        await Future.delayed(const Duration(seconds: 3));
        _goToMain();
      }
    } catch (e) {
      setState(() {
        _statusText = 'Gagal mengunduh pembaruan.';
        _isDownloading = false;
      });
      await Future.delayed(const Duration(seconds: 2));
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
