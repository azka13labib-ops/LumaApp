import 'package:universal_io/io.dart' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/theme/app_theme.dart';
import 'core/services/settings_service.dart';
import 'core/updater/widgets/update_screen.dart';

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
  @override
  void initState() {
    super.initState();
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
      // Widget pertama yang dimuat: SplashUpdateScreen.
      // Berlaku untuk SEMUA user (login maupun logout) — tidak ada syarat auth.
      home: const SplashUpdateScreen(),
    );
  }
}