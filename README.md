# Luma

Aplikasi streaming musik dan pemutar audio offline berkinerja tinggi, minimalis, dan hemat daya yang dibangun menggunakan Flutter, Riverpod, Just Audio, dan Supabase.

[![Unduh APK](https://img.shields.io/badge/Unduh_APK-Instal_Langsung-10B981?style=for-the-badge&logo=android&logoColor=white)](https://github.com/azka13labib-ops/LumaApp/releases/latest/download/app-release.apk)
[![Rilis Terbaru](https://img.shields.io/github/v/release/azka13labib-ops/LumaApp?style=for-the-badge&color=2563EB)](https://github.com/azka13labib-ops/LumaApp/releases/latest)

[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://developer.android.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.2.0+-blue.svg)](https://flutter.dev)
[![State Management](https://img.shields.io/badge/State-Riverpod-blueviolet.svg)](https://riverpod.dev)
[![Backend](https://img.shields.io/badge/Backend-Supabase-emerald.svg)](https://supabase.com)
[![Lisensi](https://img.shields.io/badge/Lisensi-MIT-lightgrey.svg)](LICENSE)

---

## Panduan Instalasi

### Metode 1: Unduh dan Pasang Langsung APK (Disarankan)

1. Klik tombol di atas atau [Unduh app-release.apk](https://github.com/azka13labib-ops/LumaApp/releases/latest/download/app-release.apk).
2. Buka berkas `.apk` yang telah diunduh di perangkat Android Anda.
3. Apabila muncul peringatan keamanan sistem Android, pilih opsi untuk mengizinkan instalasi dari sumber ini (browser atau pengelola berkas).
4. Tekan tombol Pasang (Install), lalu buka aplikasi Luma.

### Metode 2: Instalasi Melalui ADB

Bagi pengguna yang menghubungkan perangkat via kabel dengan mode USB Debugging aktif:

```bash
# Unduh berkas APK rilis terbaru
curl -L -o app-release.apk https://github.com/azka13labib-ops/LumaApp/releases/latest/download/app-release.apk

# Pasang langsung ke perangkat Android
adb install -r app-release.apk
```

---

## Kebutuhan Perangkat dan Izin Akses

| Komponen | Spesifikasi Minimum |
| :--- | :--- |
| **Sistem Operasi** | Android 7.0 (API Level 24) atau yang lebih baru |
| **Penyimpanan Bebas** | Minimal 45 MB untuk instalasi dasar ditambah ruang lagu offline |
| **Koneksi Jaringan** | Wi-Fi atau Paket Data Seluler (untuk streaming audio dan sinkronisasi data) |

### Izin Sistem yang Diperlukan

- **Layanan Latar Belakang (Foreground Service)**: Memungkinkan pemutaran lagu tetap berjalan tanpa terhenti saat layar mati atau saat membuka aplikasi lain.
- **Notifikasi**: Menampilkan kontrol lagu (play, pause, next, previous) dan judul lagu pada bilah notifikasi sistem Android.
- **Akses Internet**: Digunakan untuk mengambil streaming audio, metadata pencarian lagu, dan sinkronisasi akun Supabase.

---

## Fitur Utama

- **Pemutaran Latar Belakang Tanpa Hambatan**: Terintegrasi penuh dengan sistem notifikasi dan layar kunci Android menggunakan `just_audio` dan `just_audio_background`.
- **Mode Offline dan Unduh Lagu**: Simpan lagu favorit ke memori internal perangkat untuk didengarkan kapan saja tanpa kuota internet.
- **Pencarian Cepat Responsif**: Menemukan audio dan lagu secara instan dengan sistem debounce cerdas untuk efisiensi jaringan.
- **Sinkronisasi Koleksi Cloud**: Daftar lagu favorit, riwayat lagu yang baru diputar, dan playlist tersimpan secara otomatis di cloud melalui Supabase.
- **Transisi Tampilan Halus**: Penggunaan skeleton loading bawaan (Skeletonizer) yang memuat kerangka data tanpa pergeseran tata letak antarmuka.
- **Ekstraksi Warna Sampul Dinamis**: Latar belakang tampilan pemutar menyesuaikan gradasi warna secara otomatis mengikuti gambar sampul album menggunakan `palette_generator`.
- **Tema Gelap OLED Murni**: Antarmuka hitam pekat berprinsip minimalis, nyaman di mata, dan hemat konsumsi baterai perangkat.

---

## Teknologi yang Digunakan

| Lapisan | Komponen | Peran |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK >=3.2.0) | Fondasi aplikasi mobile lintas platform |
| **Manajemen State** | Flutter Riverpod | Pengelolaan status reaktif dan dependency injection |
| **Mesin Audio** | Just Audio & Just Audio Background | Pemutaran audio native di tingkat sistem Android |
| **Penyedia Sumber Audio** | Youtube Explode Dart & Dio | Resolusi tautan audio dan pengunduh berkas |
| **Backend & Autentikasi** | Supabase Flutter | Basis data cloud PostgreSQL, riwayat, dan akun pengguna |
| **Antarmuka (UI/UX)** | Tema Gelap Kustom & Skeletonizer | Desain modern berkecepatan tinggi tanpa layout-shift |

---

## Lisensi

Proyek ini didistribusikan di bawah lisensi MIT. Silakan lihat berkas [LICENSE](LICENSE) untuk informasi lebih lanjut.
