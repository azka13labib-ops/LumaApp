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

## Direct Installation

### Option 1: One-Click APK Download (Recommended)

1. Click the download button above or [Download app-release.apk directly](https://github.com/azka13labib-ops/LumaApp/releases/latest/download/app-release.apk).
2. Open the downloaded `.apk` file on your Android device.
3. If prompted, allow installation from your browser or file manager.
4. Tap Install.

### Option 2: ADB Command Line Install

Connect your Android device with USB debugging enabled, then execute:

```bash
# Download latest APK
curl -L -o app-release.apk https://github.com/azka13labib-ops/LumaApp/releases/latest/download/app-release.apk

# Install to connected device
adb install -r app-release.apk
```

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

## Architecture Overview

```
lib/
|-- core/
|   |-- constants/          # Application routes, theme tokens, and color palettes
|   |-- services/           # Audio background service, stream resolvers, downloader
|   |-- theme/              # Dark mode styling and typography definitions
|   |-- utils/              # Debouncers, formatters, and platform helpers
|   `-- widgets/            # Shared primitives (LumaListSkeleton, MiniPlayer, etc.)
|-- features/
|   |-- auth/               # Authentication workflows and Supabase auth controllers
|   |-- home/               # Dashboard, recent tracks, and quick discovery feeds
|   |-- library/            # User playlists, liked songs, and downloaded storage
|   |-- player/             # Fullscreen audio visualizer, queue manager, and controls
|   |-- premium/            # Account tier settings and configuration
|   `-- search/             # Query parsing, search results, and stream resolution
`-- main.dart               # Service container initialization and root application entry
```

---

## Local Development & Build

### Prerequisites

- Flutter SDK version 3.2.0 or higher
- Android SDK version 34 (Android 14) with Command Line Tools
- Java Development Kit (JDK 17)

### Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/azka13labib-ops/LumaApp.git
   cd LumaApp
   ```

2. Install Dart dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Environment Variables:
   Create a `.env` file in the root directory:
   ```env
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. Launch the application on a connected device or emulator:
   ```bash
   flutter run
   ```

### Production Build

To compile a signed or release Android package:

```bash
# Build universal release APK
flutter build apk --release

# Build split-per-ABI APKs (smaller file sizes)
flutter build apk --release --split-per-abi
```

The output file will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## License

This project is licensed under the MIT License. Refer to the [LICENSE](LICENSE) file for full details.
