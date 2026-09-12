import 'package:universal_io/io.dart' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/theme/app_theme.dart';
import 'package:luma_app/features/auth/presentation/screens/login_screen.dart';
import 'package:luma_app/features/home/presentation/screens/home_screen.dart';
import 'package:luma_app/features/search/presentation/screens/search_screen.dart';
import 'package:luma_app/features/library/presentation/screens/library_screen.dart';
import 'package:luma_app/features/premium/presentation/screens/premium_screen.dart';
import 'package:luma_app/features/player/presentation/widgets/mini_player.dart';
import 'core/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ngodink.lumaapp.audio',
      androidNotificationChannelName: 'Pemutaran musik',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );
  }

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() => _user = data.session?.user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isLight = settings.themePreference == ThemePreference.light;
    final themeMode = isLight ? ThemeMode.light : ThemeMode.dark;

    return MaterialApp(
      title: 'LumaApp',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: settings.themePreference == ThemePreference.midnight 
          ? AppTheme.midnight 
          : AppTheme.dark,
      home: _user == null ? const LoginScreen() : const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
    const PremiumScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini player sits on top of the bottom nav: never clips list items
            const MiniPlayer(),
            BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              selectedItemColor: LumaColors.accent,
              unselectedItemColor: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ?? Colors.grey,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
                BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Cari'),
                BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'Koleksi'),
                BottomNavigationBarItem(icon: Icon(Icons.workspace_premium_rounded), label: 'Premium'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
