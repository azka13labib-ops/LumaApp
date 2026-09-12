import 'dart:convert';
import 'package:universal_io/io.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

enum AudioQuality {
  auto,
  high,
  standard,
  dataSaver;

  String get label => switch (this) {
        AudioQuality.auto => 'Otomatis (Disarankan)',
        AudioQuality.high => 'Tinggi (256 kbps AAC)',
        AudioQuality.standard => 'Standar (160 kbps Opus)',
        AudioQuality.dataSaver => 'Hemat Data (96-128 kbps)',
      };

  String get description => switch (this) {
        AudioQuality.auto => 'Menyesuaikan kecepatan koneksi secara dinamis.',
        AudioQuality.high =>
          'Kualitas audio tertinggi langsung dari YouTube native stream.',
        AudioQuality.standard =>
          'Keseimbangan optimal antara kualitas suara dan penggunaan kuota.',
        AudioQuality.dataSaver =>
          'Penggunaan data hemat untuk koneksi seluler lambat.',
      };
}

enum ThemePreference {
  oled,
  midnight,
  light;

  String get label => switch (this) {
        ThemePreference.oled => 'Gelap OLED (Pitch Black)',
        ThemePreference.midnight => 'Gelap Midnight (Deep Navy)',
        ThemePreference.light => 'Terang (Light Mode)',
      };

  String get description => switch (this) {
        ThemePreference.oled =>
          'Hitam pekat murni (#000000) untuk efisiensi baterai maksimal.',
        ThemePreference.midnight =>
          'Nuansa biru malam elegan (#0B0F17) yang lembut di mata.',
        ThemePreference.light =>
          'Tampilan bersih dan terang (#FFFFFF) untuk penggunaan siang hari.',
      };
}

class AppSettings {
  final AudioQuality audioQuality;
  final ThemePreference themePreference;
  final bool autoplay;
  final bool offlineOnly;
  final bool showNotificationControls;

  const AppSettings({
    this.audioQuality = AudioQuality.auto,
    this.themePreference = ThemePreference.light,
    this.autoplay = true,
    this.offlineOnly = false,
    this.showNotificationControls = true,
  });

  AppSettings copyWith({
    AudioQuality? audioQuality,
    ThemePreference? themePreference,
    bool? autoplay,
    bool? offlineOnly,
    bool? showNotificationControls,
  }) {
    return AppSettings(
      audioQuality: audioQuality ?? this.audioQuality,
      themePreference: themePreference ?? this.themePreference,
      autoplay: autoplay ?? this.autoplay,
      offlineOnly: offlineOnly ?? this.offlineOnly,
      showNotificationControls:
          showNotificationControls ?? this.showNotificationControls,
    );
  }

  Map<String, dynamic> toMap() => {
        'audioQuality': audioQuality.name,
        'themePreference': themePreference.name,
        'autoplay': autoplay,
        'offlineOnly': offlineOnly,
        'showNotificationControls': showNotificationControls,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      audioQuality: AudioQuality.values.firstWhere(
        (e) => e.name == map['audioQuality'],
        orElse: () => AudioQuality.auto,
      ),
      themePreference: ThemePreference.values.firstWhere(
        (e) => e.name == map['themePreference'],
        orElse: () => ThemePreference.light,
      ),
      autoplay: map['autoplay'] as bool? ?? true,
      offlineOnly: map['offlineOnly'] as bool? ?? false,
      showNotificationControls:
          map['showNotificationControls'] as bool? ?? true,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  File? _file;

  Future<File> _getFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/app_settings.json');
    return _file!;
  }

  Future<void> _loadSettings() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        state = AppSettings.fromMap(map);
      }
    } catch (e) {
      debugPrint('[Settings] Load failed: $e');
    }
  }

  Future<void> _saveSettings(AppSettings newSettings) async {
    state = newSettings;
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(newSettings.toMap()));
    } catch (e) {
      debugPrint('[Settings] Save failed: $e');
    }
  }

  Future<void> setAudioQuality(AudioQuality quality) =>
      _saveSettings(state.copyWith(audioQuality: quality));

  Future<void> setThemePreference(ThemePreference theme) =>
      _saveSettings(state.copyWith(themePreference: theme));

  Future<void> setAutoplay(bool enabled) =>
      _saveSettings(state.copyWith(autoplay: enabled));

  Future<void> setOfflineOnly(bool enabled) =>
      _saveSettings(state.copyWith(offlineOnly: enabled));

  Future<void> setShowNotificationControls(bool enabled) =>
      _saveSettings(state.copyWith(showNotificationControls: enabled));
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
