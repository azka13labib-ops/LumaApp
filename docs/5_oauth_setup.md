# Setup Supabase OAuth (Google & Apple)

Agar tombol "Lanjutkan dengan Google" dan "Lanjutkan dengan Apple" dapat berfungsi, Anda harus mengkonfigurasi *Credentials* di penyedia layanan tersebut dan menambahkannya ke *dashboard* Supabase. 

Langkah ini **tidak bisa diotomatisasi melalui kode** karena menyangkut akun Google Cloud dan Apple Developer pribadi Anda.

## 1. Setup Google Sign-In

1. Kunjungi [Google Cloud Console](https://console.cloud.google.com/).
2. Buat Project baru (misal: "LumaApp").
3. Buka menu **APIs & Services > Credentials**.
4. Klik **Create Credentials > OAuth client ID**.
5. Anda akan diminta untuk setup *OAuth consent screen* terlebih dahulu (Pilih *External* jika untuk publik).
6. Buat **Web Application Client ID**:
   - Di bagian *Authorized redirect URIs*, masukkan URL dari Supabase Dashboard Anda: `https://[PROJECT-ID].supabase.co/auth/v1/callback`
7. Simpan **Client ID** dan **Client Secret**.
8. Buka **Supabase Dashboard > Authentication > Providers > Google**.
9. Aktifkan *Enable Sign in with Google* dan masukkan *Client ID* dan *Client Secret* yang baru didapat.
10. Untuk dukungan aplikasi Android/iOS Native (pilihan), Anda juga harus membuat *Android Client ID* dan *iOS Client ID* di Google Cloud Console, lalu mendaftarkannya di aplikasi Flutter (atau menggunakan Web Client ID untuk semuanya jika menggunakan mode *web redirect*).

## 2. Setup Apple Sign-In

1. Kunjungi [Apple Developer Portal](https://developer.apple.com/) (Membutuhkan akun berbayar).
2. Buat **App ID** (Identifiers) untuk aplikasi Anda (misal: `com.ngodink.lumaapp`) dan centang fitur *Sign In with Apple*.
3. Buat **Services ID** yang dihubungkan dengan App ID tersebut.
   - Tambahkan *Return URLs*: `https://[PROJECT-ID].supabase.co/auth/v1/callback`
4. Buat **Key** khusus untuk *Sign in with Apple* dan unduh file `.p8` nya.
5. Buka **Supabase Dashboard > Authentication > Providers > Apple**.
6. Masukkan:
   - *Services ID*
   - *Bundle ID* (jika menggunakan iOS App ID)
   - *Team ID* (ada di kanan atas Apple Developer Portal)
   - *Key ID* (dari Key yang baru dibuat)
   - *Secret Key* (isi (teks) dari file `.p8` yang diunduh).

## 3. Konfigurasi Deep Link (Flutter)

Pada kode saat ini di `login_screen.dart`, fungsi `signInWithOAuth` menggunakan parameter:
`redirectTo: 'io.supabase.lumaapp://login-callback/'`

Jika Anda me-*build* aplikasi Android/iOS asli, pastikan Anda juga mendaftarkan skema URL `io.supabase.lumaapp` di `AndroidManifest.xml` (Android) dan `Info.plist` (iOS) agar saat *login* selesai di *browser*, aplikasi Flutter bisa terbuka kembali secara otomatis.

---
**Status Saat Ini:** 
Tombol sudah ada dan terhubung dengan SDK Supabase Flutter. Jika Anda menekannya sekarang sebelum melakukan langkah di atas, akan muncul pesan error di UI karena provider belum aktif di *dashboard*.
