# LumaApp Design Direction

## Identitas Utama
LumaApp adalah pemutar musik mobile yang fokus pada pengalaman mendengarkan musik tanpa hambatan (bebas iklan, *offline-first*). Desainnya harus menempatkan *cover art* album dan hierarki navigasi musik sebagai raja.

## Antislop Dials
- **ENERGY: 2 (Balanced)**. Rapi dan elegan seperti Spotify/Apple Music, namun dengan satu aksen warna kuat untuk mempertegas identitas "Luma".
- **RHYTHM: 2 (Consistent with breaks)**. Mayoritas daftar musik berbentuk *list*, namun bagian penemuan/koleksi (Home) akan memiliki *breaks* berupa grid horizontal.
- **MOTION: 2 (Transitions)**. Animasi berfokus pada perpindahan mulus antara daftar lagu ke halaman *Now Playing* (Hero transition pada *cover art*). Tidak ada animasi *looping* tanpa henti.

## Palet Warna
- **Background Utama:** Hitam pekat (`#000000`) atau Abu-abu sangat gelap (`#121212`) untuk kontras maksimal dengan *cover art*.
- **Aksen Utama (Satu Aksen):** Hijau Luma / Neon Lime (`#B8FF22`) atau variannya. Hanya digunakan untuk tombol krusial (Play, Subscribe, Login) dan indikator status aktif.
- **Teks Utama:** Putih murni (`#FFFFFF`) untuk judul lagu.
- **Teks Sekunder:** Abu-abu (`#B3B3B3`) untuk nama artis dan durasi.

## Tipografi
- **Primary:** Menggunakan font bawaan platform yang paling optimal untuk keterbacaan (San Francisco di iOS, Roboto/Inter di Android).
- **Styling:** Judul layar/lagu menggunakan *weight* Bold. Detail menggunakan *weight* Regular. Tidak menggunakan tipe *monospace* yang generik tanpa alasan.

## Komponen
- **Tombol:** Radius moderat (sedikit melengkung, misal 8px-12px), BUKAN pil penuh, kecuali untuk tombol *Play* berbentuk lingkaran penuh.
- **Kartu/Cover Art:** Radius sangat kecil (misal 4px) agar *cover art* tetap terlihat tajam seperti album fisik, dengan sedikit bayangan hanya saat lagu tersebut aktif dimainkan.
- **State UI:** Setiap daftar wajib memiliki state *Loading* (Shimmer halus, BUKAN spinner raksasa di tengah layar) dan *Empty* (Teks jujur yang mengarahkan user).

Dial: ENERGY 2 / RHYTHM 2 / MOTION 2
