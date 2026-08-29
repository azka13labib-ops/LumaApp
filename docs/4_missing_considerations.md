# Tambahan / Pertimbangan Implementasi (Missing Considerations)

Berikut adalah beberapa aspek krusial yang belum tercakup dalam spesifikasi awal namun sangat penting untuk keberhasilan aplikasi:

## 1. UI/UX & Navigasi
- **Arsitektur Navigasi**: Apakah menggunakan Bottom Navigation Bar (Home, Search, Library, Profile)?
- **Mini Player**: Player kecil yang selalu muncul di bawah saat pengguna menavigasi aplikasi sambil mendengarkan lagu.
- **Background Audio Service**: Konfigurasi agar audio tetap berjalan saat aplikasi di-minimize atau layar mati (membutuhkan package seperti `audio_service` atau `just_audio_background`).

## 2. Penanganan Error & Edge Cases
- **YouTube Extraction Gagal**: Bagaimana jika `youtube_explode_dart` gagal menemukan audio yang tepat? (Perlu fallback atau mekanisme retry).
- **Spotify API Rate Limiting**: Strategi caching jika request ke Spotify terlalu banyak (menggunakan Supabase Edge Functions sebagai proxy agar API key aman).
- **Storage Management**: UI untuk melihat berapa banyak ruang yang digunakan oleh lagu yang didownload dan fitur untuk menghapus cache/download.

## 3. Keamanan (Security)
- **API Keys**: Key Spotify tidak boleh di-hardcode di dalam aplikasi Flutter. Sebaiknya menggunakan Supabase Edge Functions untuk memanggil API Spotify.
- **Row Level Security (RLS)**: Di Supabase, pastikan aturan RLS ketat (contoh: user hanya bisa mengedit playlist miliknya sendiri).
- **Enkripsi Offline**: Opsional, apakah file audio yang didownload perlu dienkripsi agar tidak bisa diputar di luar aplikasi?

## 4. Legalitas & Terms of Service
- Ekstraksi audio dari YouTube dan penggunaan metadata Spotify mungkin melanggar ToS dari kedua platform jika digunakan untuk aplikasi komersial publik. Harus dipertimbangkan sebagai project edukasi/pribadi.
