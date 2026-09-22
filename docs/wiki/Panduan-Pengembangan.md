# Panduan Pengembangan

## Prasyarat

- Flutter dengan Dart **3.9.2 atau lebih baru** (`environment: sdk: ^3.9.2` di `pubspec.yaml`). Flutter 3.35.x sudah dicoba.
- iOS **15.5** ke atas (naik dari 13.0 sejak fitur Pindai Struk ditambahkan, mensyaratkan `google_mlkit_text_recognition`).

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
flutter test test/local_api_test.dart test/receipt_parser_test.dart
```

[`test/local_api_test.dart`](../../test/local_api_test.dart) menguji seluruh `ApiService` dengan Hive di direktori sementara. [`test/receipt_parser_test.dart`](../../test/receipt_parser_test.dart) menguji pembacaan struk OVO dan GoPay (lihat [Penyimpanan Lokal](Penyimpanan-Lokal.md#pindai-struk)). Keduanya tidak memakai emulator dan berjalan dalam hitungan detik. Setiap perubahan pada logika data atau pembacaan struk sebaiknya disertai uji di berkas yang sesuai.

`ApiService`, `receipt_parser.dart`, dan model di `lib/data` adalah Dart murni (tanpa impor Flutter). Jadi bila `flutter test` bermasalah di komputer Anda, misalnya karena berkas `flutter_tester` belum diunduh (`flutter precache`), uji yang sama bisa dijalankan dengan `dart test` di proyek Dart biasa yang menunjuk ke folder itu.

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

Build rilis Android memakai **R8** (`isMinifyEnabled = true`, `isShrinkResources = true`) dan `isDebuggable = false` di `android/app/build.gradle.kts`. Kode Java/Kotlin diperkecil dan disamarkan, dan resource yang tidak terpakai dibuang. Kode Dart tidak terpengaruh.

- Aturan tambahan ada di `android/app/proguard-rules.pro` (saat ini kosong). Bila aplikasi rilis crash padahal versi debug normal, atau R8 melaporkan `Missing class ...`, tambahkan aturan `-keep` di sana.
- **Selalu coba build rilis di perangkat** (`flutter run --release`) sebelum mengunggah, karena masalah R8 hanya muncul di mode rilis.
- Berkas pemetaan nama (`build/app/outputs/mapping/release/mapping.txt`) dibutuhkan untuk membaca ulang laporan crash yang sudah disamarkan. Simpan bersama tiap rilis.

Daftar lengkap yang perlu dibereskan sebelum rilis ada di [Catatan Teknis](Catatan-Teknis.md#sebelum-rilis-ke-play-store).

## Memasang ke iPhone tanpa kabel (AltStore)

Aplikasi **release** berjalan mandiri di iPhone tanpa Mac (build debug tidak bisa dibuka dari layar utama tanpa Xcode). Jalur ini memakai [AltStore](https://altstore.io): berkas `.ipa` dibuat tanpa tanda tangan, lalu AltStore menandatanganinya dengan Apple ID yang login di AltServer.

1. Buat `.ipa`:

   ```bash
   flutter build ios --release --no-codesign
   rm -rf build/ios/ipa && mkdir -p build/ios/ipa/Payload
   cp -R build/ios/iphoneos/Runner.app build/ios/ipa/Payload/
   (cd build/ios/ipa && zip -qry Ringkas.ipa Payload && rm -rf Payload)
   ```

2. Kirim `Ringkas.ipa` ke iPhone (AirDrop atau iCloud Drive), lalu buka lewat **AltStore > My Apps > +** atau pilih *Open in AltStore*.
3. Pertama kali, percayai profil pengembang di **Settings > General > VPN & Device Management**.

Syaratnya: AltStore sudah terpasang di iPhone (pemasangan pertama AltStore butuh kabel sekali), AltServer berjalan di Mac, dan keduanya satu jaringan Wi-Fi. Agar penyegaran otomatis lewat Wi-Fi, aktifkan **Show this iPhone when on Wi-Fi** di Finder. Dengan Apple ID gratis, aplikasi kedaluwarsa setelah 7 hari dan harus disegarkan (AltServer melakukannya otomatis selama Mac dan iPhone terhubung).

**Pengaturan signing di proyek** (`DEVELOPMENT_TEAM`, `CODE_SIGN_STYLE = Automatic`) hanya dipakai saat membangun lewat Xcode atau `flutter run` ke perangkat. Jalur AltStore mengabaikannya. Bundle id proyek adalah `com.fibod.ringkas`, dan tim yang tertulis sama dengan proyek `flutter-afin` (tim perusahaan). Membangun dengan Xcode akan mendaftarkan App ID itu ke akun tim tersebut.

## Menandatangani rilis (Play Store)

Play Store hanya menerima AAB yang ditandatangani dengan **kunci unggah yang sama** dengan unggahan pertama aplikasi ini. Bila salah, Play Console menolak dengan pesan *"Your Android App Bundle is signed with the wrong key"* dan menampilkan sidik jari SHA1 yang **diharapkan** serta yang **dipakai**.

### Konfigurasi
Buat berkas `android/key.properties` (sudah diabaikan git, jangan pernah di-commit):

```properties
storePassword=<kata sandi keystore>
keyPassword=<kata sandi kunci>
keyAlias=<alias kunci>
storeFile=/path/absolut/ke/upload-keystore.jks
```

`android/app/build.gradle.kts` membaca berkas itu untuk build rilis.

| Kondisi | Perilaku |
|---|---|
| `key.properties` ada | Rilis ditandatangani kunci di dalamnya |
| `key.properties` tidak ada, `flutter build apk --release` | Memakai kunci **debug**. Hanya untuk uji lokal, jangan diunggah. |
| `key.properties` tidak ada, `flutter build appbundle --release` | **Build dihentikan** dengan pesan penjelasan, agar AAB berkunci debug tidak sampai ke Play Store |

### Memeriksa sidik jari kunci
```bash
keytool -list -v -keystore upload-keystore.jks -alias <alias>            # kunci di keystore
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab   # kunci yang dipakai di AAB
```
Bandingkan nilai `SHA1` dengan yang diminta Play Console (Setup > App signing > *Upload key certificate*).

### Bila kunci yang diminta Play tidak ada
Kunci itu dibuat oleh siapa pun yang pertama kali mengunggah aplikasi (bisa rekan tim, atau komputer lain). Urutan yang disarankan:

1. **Cari keystore aslinya** dari orang atau komputer yang mengunggah pertama, lengkap dengan kata sandi dan alias. Bila unggahan pertama memakai kunci debug bawaan Android Studio, berkasnya `~/.android/debug.keystore` di komputer itu (alias `androiddebugkey`, kata sandi `android`).
2. **Bila keystore hilang dan aplikasi memakai Play App Signing** (bawaan untuk aplikasi baru), minta reset kunci unggah di Play Console: **Setup > App signing > Request upload key reset**. Siapkan kunci baru:

   ```bash
   keytool -genkeypair -v -keystore upload-keystore.jks -alias upload \
     -keyalg RSA -keysize 2048 -validity 10000
   keytool -export -rfc -keystore upload-keystore.jks -alias upload -file upload_certificate.pem
   ```

   Lalu unggah `upload_certificate.pem` pada formulir reset. Lama prosesnya ditentukan Google, jadi ikuti petunjuk terbaru di Play Console.
3. **Bila aplikasi tidak memakai Play App Signing**, kunci yang diminta adalah kunci penandatangan aplikasi itu sendiri dan tidak bisa direset. Tanpa berkasnya, aplikasi tidak bisa diperbarui lagi dan harus diterbitkan ulang sebagai aplikasi baru.

**Cadangkan keystore dan kata sandinya** di tempat aman (penyimpanan terenkripsi atau pengelola kata sandi), terpisah dari repositori.
