import 'package:flutter/material.dart';
import 'package:luma_app/features/home/presentation/screens/home_screen.dart';
import 'package:luma_app/features/library/presentation/screens/library_screen.dart';
import 'package:luma_app/features/player/presentation/widgets/mini_player.dart';
import 'package:luma_app/features/premium/presentation/screens/premium_screen.dart';
import 'package:luma_app/features/search/presentation/screens/search_screen.dart';
import 'package:luma_app/core/widgets/luma_animated_nav_bar.dart';

/// Shell utama aplikasi setelah user berhasil login.
/// Berisi tab Home / Search / Library / Premium + MiniPlayer + nav bar.
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
            LumaAnimatedNavBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ],
        ),
      ),
    );
  }
}