import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/theme/app_theme.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.lumaapp.audio',
      androidNotificationChannelName: 'LumaApp',
      androidNotificationOngoing: true,
      notificationColor: const Color(0xFF0055FF),
    );
  } catch (_) {
    // Background audio unavailable — app still runs normally
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _user = data.session?.user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LumaApp',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Paksa Hitam-Biru sebagai bawaan
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Jika user null (belum login), ke LoginScreen. Jika ada, ke SearchScreen.
      home: _user == null ? const LoginScreen() : const SearchScreen(),
    );
  }
}
