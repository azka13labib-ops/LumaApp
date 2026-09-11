# Luma

High-performance, minimalist music streaming and offline audio player built with Flutter, Riverpod, Just Audio, and Supabase.

[![Download APK](https://img.shields.io/badge/Download_APK-Direct_Install-10B981?style=for-the-badge&logo=android&logoColor=white)](https://github.com/azka13labib-ops/LumaApp/releases/latest/download/app-release.apk)
[![Latest Release](https://img.shields.io/github/v/release/azka13labib-ops/LumaApp?style=for-the-badge&color=2563EB)](https://github.com/azka13labib-ops/LumaApp/releases/latest)

[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://developer.android.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.2.0+-blue.svg)](https://flutter.dev)
[![State Management](https://img.shields.io/badge/State-Riverpod-blueviolet.svg)](https://riverpod.dev)
[![Backend](https://img.shields.io/badge/Backend-Supabase-emerald.svg)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

---

## Installation

### Method 1: Direct APK Download (Recommended)

1. Click [Download app-release.apk](https://github.com/azka13labib-ops/LumaApp/releases/latest/download/app-release.apk).
2. Open the downloaded `.apk` package on your Android device.
3. If prompted by Android, grant permission to "Install Unknown Apps" for your browser or file manager.
4. Press Install and launch the application.

### Method 2: ADB Installation

For developers or advanced users with USB debugging enabled:

```bash
# Download latest release package
curl -L -o app-release.apk https://github.com/azka13labib-ops/LumaApp/releases/latest/download/app-release.apk

# Install directly to target device
adb install -r app-release.apk
```

---

## Device Requirements & Permissions

| Requirement | Minimum Specification |
| :--- | :--- |
| **Operating System** | Android 7.0 (API Level 24) or later |
| **Storage Space** | 45 MB base install + offline cache headroom |
| **Internet Connection** | Wi-Fi or Mobile Data (for streaming and cloud sync) |

### Runtime Permissions

- **Foreground Service**: Allows uninterrupted audio playback while screen is locked or app is in background.
- **Post Notifications**: Renders playback controls and track metadata in the Android media notification shade.
- **Internet Access**: Fetches remote audio streams, metadata, and Supabase user library data.

---

## Core Capabilities

- **Uninterrupted Background Playback**: Native media notification integration with lock-screen controls, seek bars, and next/previous track navigation powered by `just_audio` and `just_audio_background`.
- **Zero-Interruption Streaming**: Optimized audio stream resolution with cancellation token handling to eliminate race conditions and audio stutter.
- **Offline Storage and Downloads**: High-speed local track caching for offline listening without cellular or WiFi connectivity.
- **Debounced Instant Search**: Real-time YouTube audio query indexing with debounced inputs to reduce API traffic and render instantaneous results.
- **Synchronized Cloud Library**: Real-time persistence for favorites, playlists, and recently played tracks backed by Supabase PostgreSQL.
- **Skeletonized State Transitions**: Native `Skeletonizer` placeholder architecture preventing layout shifts during content loading.
- **Dynamic Palette Extraction**: Contextual UI background gradients computed in real time from album artwork using `palette_generator`.
- **Pure Dark OLED Architecture**: High-contrast, minimal design system engineered to maximize battery longevity and eliminate interface clutter.

---

## Tech Stack

| Layer | Component | Description |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK >=3.2.0) | Cross-platform native mobile foundation |
| **State Management** | Flutter Riverpod | Reactive, compile-safe dependency injection and state |
| **Audio Engine** | Just Audio & Just Audio Background | Native Android foreground media service and ExoPlayer bindings |
| **Stream Extraction** | Youtube Explode Dart & Dio | Audio stream resolution and concurrent file download manager |
| **Backend & Auth** | Supabase Flutter | User authentication, PostgreSQL database, and remote state sync |
| **UI Design System** | Custom Dark Theme + Skeletonizer | OLED-optimized palette with zero layout-shift skeleton loaders |

---

## License

This project is licensed under the MIT License. Refer to the [LICENSE](LICENSE) file for full details.
