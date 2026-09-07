import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumaColors.darkBg,
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, size: 80, color: LumaColors.accent),
            const SizedBox(height: 24),
            const Text(
              'Premium Coming Soon',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Nikmati pengalaman mendengarkan tanpa batas. Fitur premium akan segera hadir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: LumaColors.darkTextSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
