# Ringkas

Aplikasi pencatat keuangan pribadi berbasis Flutter. Pengguna mencatat pemasukan dan pengeluaran ke dalam beberapa dompet, mengelompokkannya dengan kategori, lalu melihat ringkasannya dalam bentuk grafik.

Semua data disimpan **di perangkat** dengan database lokal [Hive CE](https://pub.dev/packages/hive_ce). Tidak ada server, tidak perlu internet, dan tidak perlu akun cloud.

- **Package name:** `com.fibod.ringkas`
- **Versi:** 1.0.0+1
- **Bahasa antarmuka:** Indonesia

## Fitur

- **Akun lokal:** daftar 3 langkah (akun, mata uang, dompet pertama), masuk, dan otomatis masuk kembali saat aplikasi dibuka.
- **Dompet:** banyak dompet per pengguna dengan saldo awal dan mata uang (IDR, USD, EUR, JPY). Saldo berjalan dihitung otomatis dari transaksi.
- **Transaksi:** tambah, ubah, hapus, lihat detail, dan cari berdasarkan kata kunci, tanggal, kategori, dan dompet.
- **Kategori:** kategori pemasukan dan pengeluaran per pengguna dengan pilihan warna dan ikon. Pengguna baru langsung mendapat 10 kategori bawaan.
- **Ringkasan:** grafik lingkaran per kategori dengan periode harian, mingguan, atau bulanan, serta saldo awal dan akhir.

Penjelasan lengkap tiap layar ada di [Fitur Aplikasi](docs/wiki/Fitur-Aplikasi.md).

> **Data hanya ada di perangkat.** Menghapus aplikasi atau membersihkan datanya menghapus semua catatan, dan belum ada fitur cadangan. Lihat [Penyimpanan Lokal](docs/wiki/Penyimpanan-Lokal.md).

## Teknologi

| Bagian | Yang dipakai |
|---|---|
| Framework | Flutter (Dart `^3.9.2`) |
| Database lokal | `hive_ce` dan `hive_ce_flutter` (data disimpan sebagai `Map`, tanpa adapter) |
| Hash password | `crypto` (SHA-256) |
| State management | `flutter_riverpod` 2.5.1 (alur autentikasi); layar lain memakai `StatefulWidget` |
| Penyimpanan sesi | `shared_preferences` (token dan nama pengguna) |
| Grafik | `fl_chart` |
| Format tanggal | `intl` (lokal `id_ID`) |

## Memulai

### Prasyarat
- Flutter dengan Dart 3.9.2 atau lebih baru (Flutter 3.35.x sudah dicoba).
- Android Studio atau Xcode untuk emulator/simulator.

### Langkah

```bash
git clone https://github.com/wahyuabied1/flutter-ringkas.git
cd flutter-ringkas
flutter pub get
flutter run
```

Tidak ada konfigurasi lain. Database dibuat otomatis saat aplikasi pertama kali dibuka.

### Perintah yang sering dipakai

```bash
flutter test test/local_api_test.dart   # uji lapisan penyimpanan
dart analyze lib                        # analisis statis
dart format lib                         # rapikan kode
flutter build apk --release             # build APK
flutter build appbundle --release       # build untuk Play Store
```

Sebelum rilis ke Play Store, baca [Catatan Teknis](docs/wiki/Catatan-Teknis.md) dan [Keamanan](docs/wiki/Keamanan.md).

## Struktur proyek

```
lib/
├── main.dart               # titik masuk, tema, dan daftar rute
├── core/                   # tema aplikasi
├── data/
│   ├── model/              # Wallet, Category, Transaction, User
│   └── services/           # ApiService: penyimpanan dan logika data (Hive)
├── features/               # satu folder per fitur
│   ├── splash/  onboarding/  auth/  home/
│   └── transaksi/  ringkasan/  profile/
└── shared/widget/          # widget umum
test/local_api_test.dart    # uji lapisan penyimpanan
assets/images/              # gambar: WebP, nama snake_case
docs/wiki/                  # dokumentasi
```

## Dokumentasi

Seluruh dokumentasi ada di [`docs/wiki`](docs/wiki/Home.md):

| Halaman | Isi |
|---|---|
| [Fitur Aplikasi](docs/wiki/Fitur-Aplikasi.md) | Alur pengguna dan fungsi tiap layar |
| [Arsitektur](docs/wiki/Arsitektur.md) | Lapisan kode, state, navigasi, alur data |
| [Penyimpanan Lokal](docs/wiki/Penyimpanan-Lokal.md) | Box Hive, field tiap data, dan cara mengubah skema |
| [Panduan Pengembangan](docs/wiki/Panduan-Pengembangan.md) | Menjalankan, menguji, menambah fitur, aset, dan build |
| [Keamanan](docs/wiki/Keamanan.md) | Risiko dan yang perlu dilakukan sebelum rilis |
| [Catatan Teknis](docs/wiki/Catatan-Teknis.md) | Utang teknis dan daftar pekerjaan sebelum rilis |

Riwayat versi yang memakai backend Google Sheets (Apps Script) masih ada di git, sampai commit `536f471`.

## Lisensi

Belum ditentukan. Tambahkan berkas `LICENSE` sebelum kode ini dibagikan atau dipublikasikan.
