# Wiki Ringkas

Ringkas adalah aplikasi pencatat keuangan pribadi berbasis Flutter. Datanya disimpan di Google Sheets yang diakses lewat Google Apps Script.

Wiki ini menjelaskan cara kerja aplikasi, cara menyiapkan backend, dan hal-hal yang perlu diperhatikan sebelum aplikasi dipakai orang lain.

## Daftar isi

**Memahami aplikasi**
- [Fitur Aplikasi](Fitur-Aplikasi.md): alur pengguna dan fungsi tiap layar
- [Arsitektur](Arsitektur.md): lapisan kode, state, navigasi, dan penyimpanan lokal

**Backend**
- [Backend Google Sheets](Backend-Google-Sheets.md): cara kerja dan daftar endpoint
- [Struktur Spreadsheet](Struktur-Spreadsheet.md): sheet, kolom, dan relasinya
- [Setup Backend](Setup-Backend.md): deploy Apps Script dan pemecahan masalah

**Pengembangan dan rilis**
- [Panduan Pengembangan](Panduan-Pengembangan.md): menjalankan, menambah fitur, aset, build
- [Kuota dan Performa](Kuota-dan-Performa.md): batas Google dan kecepatan
- [Keamanan](Keamanan.md): risiko dan langkah pengamanan
- [Catatan Teknis](Catatan-Teknis.md): utang teknis dan daftar sebelum rilis

## Ringkasan singkat

| | |
|---|---|
| Package name | `com.fibod.ringkas` |
| Framework | Flutter, Dart `^3.9.2` |
| Backend | Google Apps Script Web App + Google Sheets |
| Autentikasi | Email dan password, token sesi disimpan di sheet `sessions` |
| Bahasa antarmuka | Indonesia |

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
