# Panduan Pengembangan

## Prasyarat

- Flutter dengan Dart **3.9.2 atau lebih baru** (`environment: sdk: ^3.9.2` di `pubspec.yaml`). Flutter 3.35.x sudah dicoba.
- Backend yang sudah berjalan. Lihat [Setup Backend](Setup-Backend.md).

Jika Anda memakai [FVM](https://fvm.app) atau beberapa versi Flutter, pastikan `flutter --version` dan `dart --version` di terminal menunjukkan Dart 3.9.2 ke atas. Versi yang lebih lama gagal saat `flutter pub get` dengan pesan *"requires SDK version ^3.9.2"*.

## Menjalankan

```bash
flutter pub get
flutter run
```

Setelah mengubah `ApiService.baseUrl`, lakukan **Stop lalu Run**. Hot reload dan hot restart tidak cukup karena nilainya `const`.

## Memeriksa kode

```bash
dart analyze lib        # analisis statis
dart format lib         # rapikan kode
```

Analisis saat ini melaporkan sekitar 34 catatan tingkat *info* (misalnya `withOpacity` yang sudah usang dan pemakaian `BuildContext` setelah `await`). Tidak ada error atau peringatan. Detailnya ada di [Catatan Teknis](Catatan-Teknis.md).

## Konvensi

- **Aset gambar:** simpan di `assets/images/` (huruf kecil), berformat **WebP**, dengan nama **snake_case**, misalnya `logo_ringkas.webp`. Folder didaftarkan satu kali di `pubspec.yaml` sehingga berkas baru otomatis terbawa. Rujuk di kode dengan `'assets/images/nama_berkas.webp'`.
- **Konversi ke WebP:**

  ```bash
  cwebp -lossless -z 9 masukan.png -o assets/images/nama_berkas.webp
  ```

  Mode `-lossless` menjaga piksel identik. Untuk ilustrasi besar, `-q 80` menghasilkan berkas jauh lebih kecil dengan selisih yang nyaris tak terlihat.
- **Penamaan berkas Dart:** snake_case, satu layar per berkas di `features/<fitur>/view/`.
- **Ikon peluncur dan web** (di `android/`, `ios/`, `web/`) tetap PNG karena platform mewajibkannya.

## Menambah fitur yang butuh data baru

Contoh: menambah kolom atau endpoint baru.

1. **Sheet:** tambahkan kolom di akhir baris header dan di `SCHEMA` pada `Code.gs`. Perbarui [Struktur Spreadsheet](Struktur-Spreadsheet.md).
2. **Script:** ubah fungsi `dompetApi`, `kategoriApi`, atau `transaksiApi` di `Code.gs`, atau tambah cabang baru di `route()`.
3. **Deploy:** buat *versi baru* pada deployment yang sama ([caranya](Setup-Backend.md#memperbarui-kode)).
4. **Aplikasi:** tambah method di `ApiService` yang memanggil `_call('METHOD', '/path', body: ..., token: ...)`.
5. **Model:** tambahkan field di kelas model dan `fromJson`.
6. Perbarui [Backend Google Sheets](Backend-Google-Sheets.md) jika ada endpoint baru.

Pola pemuatan data: bila sebuah layar butuh beberapa data yang tidak saling bergantung, jalankan dengan `Future.wait` seperti di `home_screen.dart`, jangan `await` satu per satu.

## Menguji script tanpa menyentuh spreadsheet

`Code.gs` hanya memakai layanan `SpreadsheetApp`, `Utilities`, `LockService`, `CacheService`, `ContentService`, dan `Session`. Anda bisa menjalankannya di Node dengan sheet tiruan (objek JavaScript biasa) untuk menguji alur register, dompet, dan transaksi tanpa menulis ke spreadsheet asli. Cara ini dipakai selama pengembangan untuk menghitung jumlah pembacaan sheet per request.

## Package name

Package name / bundle ID: **`com.fibod.ringkas`**.

| Platform | Lokasi |
|---|---|
| Android | `namespace` dan `applicationId` di `android/app/build.gradle.kts`; `MainActivity.kt` di `android/app/src/main/kotlin/com/fibod/ringkas/` |
| iOS | `PRODUCT_BUNDLE_IDENTIFIER` di `ios/Runner.xcodeproj/project.pbxproj` |
| macOS | `macos/Runner/Configs/AppInfo.xcconfig` dan `macos/Runner.xcodeproj/project.pbxproj` |
| Linux | `APPLICATION_ID` di `linux/CMakeLists.txt` |

`applicationId` Android tidak bisa diganti setelah aplikasi dirilis di Play Store.

## Build rilis

```bash
flutter build apk --release          # APK
flutter build appbundle --release    # AAB untuk Play Store
```

> Konfigurasi rilis Android saat ini masih memakai **kunci debug** (`signingConfig = signingConfigs.getByName("debug")` di `build.gradle.kts`). Buat keystore rilis dan ganti sebelum mengunggah ke Play Store. Daftar lengkapnya ada di [Catatan Teknis](Catatan-Teknis.md#sebelum-rilis-ke-play-store).
