# App Audit Report (Non‑UI/UX & Backend)

## 1. Architecture & Code Structure
- **State Management**: `PlayerProvider` contains static vars and business logic; should be split into separate service and notifier layers.
- **Tight Coupling**: Direct UI imports inside providers (e.g., using `BuildContext`). Decouple to improve testability.
- **Missing Clean Architecture**: No clear separation of data, domain, and presentation layers.

## 2. Code Quality & Maintainability
- **TODO / FIXME** markers scattered (`TODO: Add signing config`, `BUG`, etc.).
- **Unused Imports** (already cleaned but ensure no leftover).
- **Long Functions**: `_loadAndPlay`, `_handleNotificationSkip` exceed 30 lines – consider refactoring.
- **Magic Numbers**: Silent MP3 byte array hard‑coded; replace with constant or asset.

## 3. Error Handling & Resilience
- **Missing Try/Catch** around async calls (e.g., network fetch for playlist, Supabase calls).
- **Assertions/DebugPrint** still present in several files – should be removed or guarded by `kDebugMode`.
- **No Global Error Handler** for unhandled stream errors.

## 4. Performance & Resource Management
- **Repeated Playlist Reconstruction** on every play – may cause UI jank.
- **No Caching** for remote audio URLs; each play re‑fetches streams.
- **Potential Memory Leak**: `AudioPlayer` not disposed on widget dispose in some screens.

## 5. Security & Permissions
- **Hard‑coded URLs** for silent audio; consider bundling asset to avoid network dependency.
- **AndroidManifest**: Verify `android:exported` flags for all activities (required Android 12+). 
- **No Secure Storage** for tokens – Supabase auth tokens stored in plain `SharedPreferences`.

## 6. Testing & CI
- **No Unit/Widget Tests** in `test/` directory.
- **Missing CI Workflow** – add GitHub Actions for `flutter test` and `flutter analyze`.

## 7. Documentation
- **README** lacks setup instructions for Supabase keys.
- **No API Documentation** for provider methods.

## 8. Build & Release
- **Signing Configuration** TODO in `android/app/build.gradle` – prevents release builds.
- **No versioning strategy** – manual changes in `pubspec.yaml`.

---
*This report focuses on architectural, code‑quality, performance, security, testing and release aspects that are not directly UI/UX or backend service implementations.*
