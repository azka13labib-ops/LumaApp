import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_app/core/theme/app_theme.dart';
import 'package:luma_app/core/widgets/luma_list_skeleton.dart';
import 'package:luma_app/core/services/youtube_service.dart';

void main() {
  group('LumaApp Core Smoke & Widget Tests', () {
    test('AppTheme dark mode configurations and tokens match design system', () {
      final theme = AppTheme.dark;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, LumaColors.darkBg);
      expect(theme.colorScheme.primary, LumaColors.accent);
      expect(theme.useMaterial3, isTrue);
    });

    test('MusicItem model instantiates and formats properly', () {
      final item = MusicItem(
        id: 'track123',
        title: 'Song Title',
        author: 'Artist Name',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        fileSizeBytes: 1048576,
      );

      expect(item.id, 'track123');
      expect(item.title, 'Song Title');
      expect(item.author, 'Artist Name');
      expect(item.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(item.fileSizeBytes, 1048576);
    });

    testWidgets('LumaListSkeleton renders the specified count of skeleton items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: LumaListSkeleton(count: 5),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ListTile), findsNWidgets(5));
      expect(find.byType(LumaListSkeleton), findsOneWidget);
    });
  });
}
