git add android/app/src/main/AndroidManifest.xml
git commit -m "chore: update AndroidManifest.xml"
git push

git add pubspec.yaml pubspec.lock
git commit -m "chore: update pubspec dependencies"
git push

git add assets/
git commit -m "feat: add assets"
git push

git add lib/core/services/settings_service.dart
git commit -m "feat: default to light theme in settings service"
git push

git add lib/core/theme/app_theme.dart lib/core/providers/theme_provider.dart
git commit -m "feat: setup light mode theme and theme provider"
git push

git add lib/main.dart
git commit -m "feat: integrate theme provider in main app"
git push

git add lib/features/auth/presentation/screens/login_screen.dart
git commit -m "style: lock login screen to light mode and prevent scrolling"
git push

git add lib/features/home/presentation/screens/home_screen.dart
git commit -m "style: apply dynamic theme colors to home screen"
git push

git add lib/features/library/presentation/screens/settings_screen.dart
git commit -m "style: apply dynamic theme colors to settings screen"
git push

git add lib/features/library/presentation/screens/library_screen.dart
git commit -m "style: apply dynamic theme colors to library screen"
git push

git add lib/features/search/presentation/screens/search_screen.dart
git commit -m "style: apply dynamic theme colors to search screen"
git push

git add lib/features/profile/presentation/screens/profile_screen.dart
git commit -m "style: apply dynamic theme colors to profile screen"
git push

git add lib/core/services/lyrics_service.dart lib/core/services/offline_cache_service.dart lib/core/services/youtube_service.dart
git commit -m "chore: update core services"
git push

git add lib/features/player/presentation/widgets/mini_player.dart lib/features/player/presentation/widgets/track_row.dart
git commit -m "style: update player widgets"
git push
