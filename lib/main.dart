import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'package:luma_app/features/auth/presentation/screens/login_screen.dart';
import 'package:luma_app/features/home/presentation/screens/home_screen.dart';
import 'package:luma_app/features/search/presentation/screens/search_screen.dart';
import 'package:luma_app/features/library/presentation/screens/library_screen.dart';
import 'package:luma_app/features/premium/presentation/screens/premium_screen.dart';
import 'package:luma_app/features/playlist/presentation/screens/create_playlist_screen.dart';
import 'package:luma_app/features/player/presentation/widgets/mini_player.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _user;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _user = data.session?.user;
          _initialized = true;
        });
      }
    });
    // Jika tidak ada trigger event setelah init, update flag
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_initialized && mounted) {
        setState(() => _initialized = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: LumaColors.darkBg, body: Center(child: CircularProgressIndicator())),
      );
    }
    
    return MaterialApp(
      title: 'LumaApp',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
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
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) {
            // Tab Buat -> push screen khusus
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePlaylistScreen()));
            return;
          }
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: LumaColors.darkBg,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Cari'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Koleksi'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'Premium'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Buat'),
        ],
      ),
    );
  }
}
