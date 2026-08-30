import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/search/presentation/screens/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LumaApp',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Paksa Dark Mode untuk aplikasi musik
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB8FF22), // Luma Green Accent
          secondary: Color(0xFFB8FF22),
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB8FF22),
            foregroundColor: Colors.black, // Kontras tinggi
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // R-11: Bukan pill penuh
            ),
          ),
        ),
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB8FF22)),
        useMaterial3: true,
      ),
      home: const SearchScreen(), // TEMP: Skip login for UI testing
    );
  }
}
