# Catatan Teknis

Daftar hal yang diketahui belum ideal di kode saat ini. Isinya diperiksa langsung dari repositori pada saat halaman ini ditulis.

## Sebelum rilis ke Play Store

- [ ] **Tanda tangan rilis.** Build rilis Android masih memakai kunci debug (`signingConfig = signingConfigs.getByName("debug")` di `android/app/build.gradle.kts`). Buat keystore rilis dan konfigurasikan.
- [ ] **Nama aplikasi.** Label Android masih `ringkas_app` (`AndroidManifest.xml`) dan nama tampilan iOS `Ringkas App` (`Info.plist`). Samakan dengan nama yang diinginkan, misalnya `Ringkas`.
- [ ] **Deskripsi proyek.** `description` di `pubspec.yaml` masih `A new Flutter project.`
- [ ] **Kebijakan privasi dan penghapusan akun.** Belum ada. Lihat [Keamanan](Keamanan.md#bila-akan-dirilis-ke-play-store).
- [ ] **Berkas lisensi.** Belum ada `LICENSE`.
- [ ] **Akses spreadsheet** diatur ke *Dibatasi*.

## Kode

| Temuan | Keterangan |
|---|---|
| Uji bawaan tidak sesuai | `test/widget_test.dart` masih berupa uji *counter* dari template Flutter (mencari teks `0` dan ikon `+`). Aplikasi ini tidak punya counter, jadi uji itu tidak akan lolos bila dijalankan. Ganti dengan uji yang relevan. |
| Dependensi tidak terpakai | `image_picker` dan `http_parser` ada di `pubspec.yaml` tetapi tidak dipakai di `lib/`. |
| Berkas kosong | `lib/data/services/dio_client.dart` kosong, dan paket `dio` tidak ada di `pubspec.yaml`. |
| Widget tidak terpakai | `lib/shared/widget/custom_button.dart` dan `custom_testfield.dart` tidak dirujuk dari luar folder `shared`. |
| Dua gaya state | Riverpod hanya dipakai untuk autentikasi, layar lain memakai `setState`. Perlu dipilih satu arah bila aplikasi membesar. |
| Layar sangat panjang | `search_screen.dart`, `ringkasan_screen.dart`, dan `transaction_screen.dart` masing-masing lebih dari 1.200 baris dan mencampur tampilan dengan logika pemuatan data. |
| Variabel tidak terpakai | `home_screen.dart` mengisi `monthlySummaryIncome/Expense/Total`, tetapi widget ringkasan bulanan menghitung sendiri lewat `_calculateMonthlySummaryForWallet()`. Isian dari `total_transaksi` tidak ditampilkan. |
| Catatan analisis | `dart analyze lib` melaporkan 34 catatan tingkat *info*: `withOpacity` sudah usang (ganti `withValues`), `BuildContext` dipakai setelah `await`, `print` di kode produksi, `WillPopScope` sudah usang (ganti `PopScope`), dan lainnya. Tidak ada error atau peringatan. |
| Pembuat controller di `build` | `register_screen.dart` dan `register_3_screen.dart` membuat `TextEditingController` di dalam `build`, sehingga isian bisa ter-reset saat layar dibangun ulang. |

## Perbedaan perilaku dari backend sebelumnya

Aplikasi awalnya ditulis untuk backend REST lain. Setelah pindah ke Apps Script:

- **Kategori bawaan.** Kode `kategori_settings_page.dart` menganggap kategori dengan `user_id` kosong atau `0` sebagai *default* yang tidak bisa diubah dan dihapus. Di versi Sheets, kategori bawaan dibuat per pengguna dengan `user_id` sebenarnya, jadi **bisa diubah dan dihapus**.
- **`total_transaksi`.** Di script, nilainya jumlah transaksi pada hasil. Saat ini tidak ditampilkan di layar mana pun.
- **`userId` tidak wajib.** Layar tambah dompet, kategori, dan transaksi tidak lagi mewajibkan `userId` lokal karena server memakai token.

## Perilaku pendaftaran

Pendaftaran tidak transaksional. Akun dibuat lebih dulu, lalu dompet. Bila langkah dompet gagal (misalnya jaringan putus), akun sudah terlanjur ada sehingga mendaftar ulang dengan email yang sama ditolak (`Email sudah terdaftar`). Pengguna harus masuk dengan akun itu dan menambah dompet dari Profil.

## Platform

Folder `web`, `linux`, `windows`, dan `macos` ada dari template Flutter. Pengembangan dan pengujian selama ini berfokus pada Android dan iOS, jadi platform lain belum diverifikasi.
