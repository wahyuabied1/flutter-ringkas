# Panduan Pengembangan

## Prasyarat

- Flutter dengan Dart **3.9.2 atau lebih baru** (`environment: sdk: ^3.9.2` di `pubspec.yaml`). Flutter 3.35.x sudah dicoba.

Jika Anda memakai [FVM](https://fvm.app) atau beberapa versi Flutter, pastikan `flutter --version` dan `dart --version` di terminal menunjukkan Dart 3.9.2 ke atas. Versi yang lebih lama gagal saat `flutter pub get` dengan pesan *"requires SDK version ^3.9.2"*.

## Menjalankan

```bash
flutter pub get
flutter run
```

Tidak ada backend atau konfigurasi tambahan. Database dibuat otomatis saat aplikasi pertama dibuka.

## Memeriksa kode

```bash
dart analyze lib        # analisis statis
dart format lib         # rapikan kode
```

Analisis saat ini melaporkan sekitar 31 catatan tingkat *info* (misalnya `withOpacity` yang sudah usang dan pemakaian `BuildContext` setelah `await`). Tidak ada error atau peringatan. Detailnya ada di [Catatan Teknis](Catatan-Teknis.md).

## Pengujian

```bash
flutter test test/local_api_test.dart
```

[`test/local_api_test.dart`](../../test/local_api_test.dart) menguji seluruh `ApiService` dengan Hive di direktori sementara. Uji ini tidak memakai emulator dan berjalan dalam hitungan detik. Setiap perubahan pada logika data sebaiknya disertai uji di berkas ini.

`ApiService` dan model di `lib/data` adalah Dart murni (tanpa impor Flutter). Jadi bila `flutter test` bermasalah di komputer Anda, misalnya karena berkas `flutter_tester` belum diunduh (`flutter precache`), uji yang sama bisa dijalankan dengan `dart test` di proyek Dart biasa yang menunjuk ke folder itu.

> `test/widget_test.dart` masih uji *counter* bawaan template dan tidak akan lolos. Lihat [Catatan Teknis](Catatan-Teknis.md).

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

1. **Field baru:** tambahkan kunci saat membuat atau mengubah baris di `ApiService`. Baris lama tidak punya kunci itu, jadi beri nilai bawaan saat membaca. Aturan lengkap mengubah skema ada di [Penyimpanan Lokal](Penyimpanan-Lokal.md#mengubah-skema).
2. **Method baru:** tambahkan di `ApiService`, dengan pola yang sama: ambil `uid` dari token, filter berdasarkan `user_id`, lalu kembalikan `Map`.
3. **Model:** tambahkan field di kelas model dan `fromJson`.
4. **Uji:** tambahkan kasus di `test/local_api_test.dart`.
5. **Dokumentasi:** perbarui [Penyimpanan Lokal](Penyimpanan-Lokal.md) bila ada field atau aturan baru.

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
