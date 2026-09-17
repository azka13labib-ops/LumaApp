import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luma_app/core/widgets/main_shell.dart';
import 'welcome_screen.dart';

/// Gerbang autentikasi aplikasi.
///
/// Widget ini menonton [Supabase.instance.client.auth.onAuthStateChange]
/// secara reaktif dan otomatis menampilkan:
/// - [WelcomeScreen] saat user belum login (session null)
/// - [MainShell] saat user sudah login (session aktif)
///
/// Ini menghilangkan masalah "login sukses tapi tidak pindah layar" dan
/// memastikan keputusan routing selalu mengikuti status auth terbaru,
/// bukan snapshot sekali jalan.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Ambil session dari event stream terbaru atau dari cached currentSession di memori
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        final user = session?.user;

        // Jika stream belum aktif dan belum ada cached session yang diketahui,
        // tampilkan layar loading transisi singkat.
        if (snapshot.connectionState != ConnectionState.active && session == null) {
          return const _AuthLoadingScreen();
        }

        if (user == null) {
          return const WelcomeScreen();
        }

        return const MainShell();
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              size: 64,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}