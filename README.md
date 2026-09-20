# Ringkas

Aplikasi pencatat keuangan pribadi berbasis Flutter. Pengguna mencatat pemasukan dan pengeluaran ke dalam beberapa dompet, mengelompokkannya dengan kategori, lalu melihat ringkasannya dalam bentuk grafik.

Data disimpan di **Google Sheets** yang diakses lewat **Google Apps Script** (Web App), sehingga tidak perlu menyewa server atau database.

- **Package name:** `com.fibod.ringkas`
- **Versi:** 1.0.0+1
- **Bahasa antarmuka:** Indonesia

## Fitur

- **Akun:** daftar 3 langkah (akun, mata uang, dompet pertama), masuk, dan otomatis masuk kembali saat aplikasi dibuka.
- **Dompet:** banyak dompet per pengguna dengan saldo awal dan mata uang (IDR, USD, EUR, JPY). Saldo berjalan dihitung otomatis dari transaksi.
- **Transaksi:** tambah, ubah, hapus, lihat detail, dan cari berdasarkan kata kunci, tanggal, kategori, dan dompet.
- **Kategori:** kategori pemasukan dan pengeluaran per pengguna dengan pilihan warna dan ikon. Pengguna baru langsung mendapat 10 kategori bawaan.
- **Ringkasan:** grafik lingkaran per kategori dengan periode harian, mingguan, atau bulanan, serta saldo awal dan akhir.

Penjelasan lengkap tiap layar ada di [Fitur Aplikasi](docs/wiki/Fitur-Aplikasi.md).

## Teknologi

| Bagian | Yang dipakai |
|---|---|
| Framework | Flutter (Dart `^3.9.2`) |
| State management | `flutter_riverpod` 2.5.1 (alur autentikasi); layar lain memakai `StatefulWidget` |
| Jaringan | `http` |
| Penyimpanan lokal | `shared_preferences` (token dan nama pengguna) |
| Grafik | `fl_chart` |
| Format tanggal | `intl` (lokal `id_ID`) |
| Backend | Google Apps Script Web App + Google Sheets |

## Memulai

### Prasyarat
- Flutter dengan Dart 3.9.2 atau lebih baru (Flutter 3.35.x sudah dicoba).
- Android Studio atau Xcode untuk emulator/simulator.
- Akun Google untuk membuat backend (spreadsheet dan Apps Script).

### Langkah
1. Ambil kode dan pasang dependensi:

   ```bash
   git clone https://github.com/wahyuabied1/flutter-ringkas.git
   cd flutter-ringkas
   flutter pub get
   ```

2. **Siapkan backend Anda sendiri** dengan mengikuti [Setup Backend](docs/wiki/Setup-Backend.md). Hasilnya berupa URL yang berakhiran `/exec`.

3. Isi URL itu di [`lib/data/services/api_service.dart`](lib/data/services/api_service.dart):

   ```dart
   static const String baseUrl =
       'https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec';
   ```

   > Nilai yang ada di repo adalah milik pengembang awal. Ganti dengan URL Anda supaya data Anda tidak bercampur dengan data orang lain.

4. Jalankan aplikasi:

   ```bash
   flutter run
   ```

   `baseUrl` adalah `const`, jadi setelah mengubahnya lakukan **Stop lalu Run** (hot reload tidak cukup).

### Perintah yang sering dipakai

```bash
dart analyze lib                      # analisis statis
dart format lib                       # rapikan kode
flutter build apk --release           # build APK
flutter build appbundle --release     # build untuk Play Store
```

Sebelum rilis ke Play Store, baca [Catatan Teknis](docs/wiki/Catatan-Teknis.md) dan [Keamanan](docs/wiki/Keamanan.md).

## Struktur proyek

```
lib/
├── main.dart               # titik masuk, tema, dan daftar rute
├── core/                   # tema aplikasi
├── data/
│   ├── model/              # Wallet, Category, Transaction, User
│   └── services/           # ApiService: klien untuk Apps Script
├── features/               # satu folder per fitur
│   ├── splash/  onboarding/  auth/  home/
│   └── transaksi/  ringkasan/  profile/
└── shared/widget/          # widget umum
apps_script/Code.gs         # backend (disalin ke editor Apps Script)
assets/images/              # gambar: WebP, nama snake_case
docs/wiki/                  # dokumentasi
```

## Dokumentasi

Seluruh dokumentasi ada di [`docs/wiki`](docs/wiki/Home.md):

| Halaman | Isi |
|---|---|
| [Fitur Aplikasi](docs/wiki/Fitur-Aplikasi.md) | Alur pengguna dan fungsi tiap layar |
| [Arsitektur](docs/wiki/Arsitektur.md) | Lapisan kode, state, navigasi, penyimpanan lokal |
| [Backend Google Sheets](docs/wiki/Backend-Google-Sheets.md) | Cara kerja backend dan daftar endpoint |
| [Struktur Spreadsheet](docs/wiki/Struktur-Spreadsheet.md) | Sheet, kolom, dan relasinya |
| [Setup Backend](docs/wiki/Setup-Backend.md) | Deploy Apps Script langkah demi langkah dan pemecahan masalah |
| [Panduan Pengembangan](docs/wiki/Panduan-Pengembangan.md) | Menjalankan, menambah fitur, aset, dan build |
| [Kuota dan Performa](docs/wiki/Kuota-dan-Performa.md) | Batas Google dan cara menjaga kecepatan |
| [Keamanan](docs/wiki/Keamanan.md) | Risiko, yang sudah ada, dan yang perlu dilakukan |
| [Catatan Teknis](docs/wiki/Catatan-Teknis.md) | Utang teknis dan daftar pekerjaan sebelum rilis |

## Lisensi

Belum ditentukan. Tambahkan berkas `LICENSE` sebelum kode ini dibagikan atau dipublikasikan.
