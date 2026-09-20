# Wiki Ringkas

Ringkas adalah aplikasi pencatat keuangan pribadi berbasis Flutter. Semua datanya disimpan di perangkat dengan database lokal Hive CE.

Wiki ini menjelaskan cara kerja aplikasi, cara mengembangkannya, dan hal-hal yang perlu diperhatikan sebelum dirilis.

## Daftar isi

**Memahami aplikasi**
- [Fitur Aplikasi](Fitur-Aplikasi.md): alur pengguna dan fungsi tiap layar
- [Arsitektur](Arsitektur.md): lapisan kode, state, navigasi, dan alur data
- [Penyimpanan Lokal](Penyimpanan-Lokal.md): box Hive, field tiap data, dan cara mengubah skema

**Pengembangan dan rilis**
- [Panduan Pengembangan](Panduan-Pengembangan.md): menjalankan, menguji, menambah fitur, aset, build
- [Keamanan](Keamanan.md): risiko dan langkah pengamanan
- [Catatan Teknis](Catatan-Teknis.md): utang teknis dan daftar sebelum rilis

## Ringkasan singkat

| | |
|---|---|
| Package name | `com.fibod.ringkas` |
| Framework | Flutter, Dart `^3.9.2` |
| Penyimpanan | Hive CE (lokal, di perangkat) |
| Akun | Lokal di perangkat: email dan password, disimpan sebagai hash |
| Bahasa antarmuka | Indonesia |

> Versi yang memakai backend Google Sheets (Apps Script) masih ada di riwayat git sampai commit `536f471`.

## Menerbitkan halaman ini ke GitHub Wiki (opsional)

Berkas di `docs/wiki` sudah memakai nama halaman ala GitHub Wiki (`Home.md`, `_Sidebar.md`). Supaya tampil di tab **Wiki** repositori:

1. Aktifkan fitur Wiki di **Settings > Features**, lalu buat satu halaman apa saja lewat antarmuka GitHub agar repositori wiki-nya terbentuk.
2. Salin dan sesuaikan tautannya:

   ```bash
   git clone https://github.com/wahyuabied1/flutter-ringkas.wiki.git
   cp docs/wiki/*.md flutter-ringkas.wiki/
   sed -i '' -E 's/\]\(([A-Za-z0-9_-]+)\.md\)/](\1)/g' flutter-ringkas.wiki/*.md
   cd flutter-ringkas.wiki && git add -A && git commit -m "Update wiki" && git push
   ```

   Perintah `sed` di atas untuk macOS. Di Linux, hapus tanda `''` setelah `-i`. Perintah itu menghapus ekstensi `.md` dari tautan antarhalaman, karena GitHub Wiki tidak memakainya.
