import 'package:flutter_test/flutter_test.dart';
import 'package:luma_app/core/providers/player_provider.dart';
import 'package:luma_app/core/services/settings_service.dart';

void main() {
  group('Settings & Playback Guardrails Unit Tests', () {
    test('AppSettings defaults are initialized correctly', () {
      const settings = AppSettings();
      expect(settings.audioQuality, AudioQuality.auto);
      expect(settings.themePreference, ThemePreference.oled);
      expect(settings.autoplay, isTrue);
      expect(settings.offlineOnly, isFalse);
      expect(settings.showNotificationControls, isTrue);
    });

    test('AppSettings serialization toMap and fromMap round-trip preserves state', () {
      const original = AppSettings(
        audioQuality: AudioQuality.high,
        themePreference: ThemePreference.midnight,
        autoplay: false,
        offlineOnly: true,
        showNotificationControls: false,
      );

      final map = original.toMap();
      final restored = AppSettings.fromMap(map);

      expect(restored.audioQuality, AudioQuality.high);
      expect(restored.themePreference, ThemePreference.midnight);
      expect(restored.autoplay, isFalse);
      expect(restored.offlineOnly, isTrue);
      expect(restored.showNotificationControls, isFalse);
    });

    test('AudioQuality enum provides clear and accurate Indonesian labels', () {
      expect(AudioQuality.auto.label, contains('Otomatis'));
      expect(AudioQuality.high.label, contains('256 kbps'));
      expect(AudioQuality.standard.label, contains('160 kbps'));
      expect(AudioQuality.dataSaver.label, contains('Hemat Data'));
    });

    test('PlayerState isLoading and isPlaying transitions behave predictably', () {
      const initial = PlayerState(isLoading: true, isPlaying: false);
      expect(initial.isLoading, isTrue);
      expect(initial.isPlaying, isFalse);

      final active = initial.copyWith(
        isLoading: false,
        isPlaying: true,
        clearLoadingStatus: true,
      );
      expect(active.isLoading, isFalse);
      expect(active.isPlaying, isTrue);
      expect(active.loadingStatus, isNull);
    });
  });
}
