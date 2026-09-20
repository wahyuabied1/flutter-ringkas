# Catatan Teknis

Daftar hal yang diketahui belum ideal di kode saat ini. Isinya diperiksa langsung dari repositori pada saat halaman ini ditulis.

## Sebelum rilis ke Play Store

- [ ] **Kunci unggah Play Store.** Play sudah mengenal aplikasi ini dengan kunci unggah tertentu, sedangkan build rilis tanpa `android/key.properties` memakai kunci debug dan ditolak. Dapatkan keystore aslinya atau minta reset kunci unggah, lalu isi `key.properties`. Langkahnya ada di [Panduan Pengembangan](Panduan-Pengembangan.md#menandatangani-rilis-play-store).
- [ ] **Uji build rilis di perangkat.** R8 (`minify` dan `shrinkResources`) sudah aktif untuk rilis. Jalankan `flutter run --release` dan coba semua alur utama untuk memastikan tidak ada yang hilang karena penyusutan kode.
- [ ] **Nama aplikasi.** Label Android masih `ringkas_app` (`AndroidManifest.xml`) dan nama tampilan iOS `Ringkas App` (`Info.plist`). Samakan dengan nama yang diinginkan, misalnya `Ringkas`.
- [ ] **Deskripsi proyek.** `description` di `pubspec.yaml` masih `A new Flutter project.`
- [ ] **Kebijakan privasi dan penghapusan akun.** Belum ada. Lihat [Keamanan](Keamanan.md#bila-akan-dirilis-ke-play-store).
- [ ] **Cadangan data.** Belum ada. Pengguna kehilangan semuanya bila aplikasi dihapus.
- [ ] **Berkas lisensi.** Belum ada `LICENSE`.

## Perubahan dari versi Google Sheets

Aplikasi pernah memakai backend Google Sheets lewat Apps Script (riwayatnya ada di git sampai commit `536f471`). Setelah pindah ke Hive CE:

- **Data lama tidak dipindahkan.** Isi spreadsheet tidak diimpor ke database lokal.
- **Token lama tidak berlaku.** Token versi Sheets berupa UUID, sedangkan sekarang berupa id pengguna. Perangkat yang sudah pernah masuk dengan versi lama akan menampilkan data kosong sampai pengguna **keluar dari Profil lalu mendaftar atau masuk lagi** (atau membersihkan data aplikasi).
- **Kategori bawaan.** Kode `kategori_settings_page.dart` menganggap kategori dengan `user_id` kosong atau `0` sebagai *default* yang tidak bisa diubah dan dihapus. Kategori bawaan sekarang dibuat per pengguna dengan `user_id` sebenarnya, jadi **bisa diubah dan dihapus**.
- **`total_transaksi`.** Berisi jumlah transaksi pada hasil dan tidak ditampilkan di layar mana pun.
- **`userId` tidak wajib.** Layar tambah dompet, kategori, dan transaksi tidak mewajibkan `userId` lokal karena pemilik data ditentukan dari token.

## Kode

| Temuan | Keterangan |
|---|---|
| Uji bawaan tidak sesuai | `test/widget_test.dart` masih uji *counter* dari template Flutter (mencari teks `0` dan ikon `+`). Aplikasi ini tidak punya counter, jadi uji itu tidak akan lolos. Uji yang relevan adalah `test/local_api_test.dart`. |
| Dependensi tidak terpakai | `image_picker` dan `http_parser` ada di `pubspec.yaml` tetapi tidak dipakai di `lib/`. |
| Berkas kosong | `lib/data/services/dio_client.dart` kosong, dan paket `dio` tidak ada di `pubspec.yaml`. |
| Widget tidak terpakai | `lib/shared/widget/custom_button.dart` dan `custom_testfield.dart` tidak dirujuk dari luar folder `shared`. |
| Nama `ApiService` | Nama warisan dari versi jaringan. Kelas ini sekarang lapisan penyimpanan lokal. Layar membaca hasilnya sebagai `Map<String, dynamic>`, bukan model bertipe. |
| Dua gaya state | Riverpod hanya dipakai untuk autentikasi, layar lain memakai `setState`. Perlu dipilih satu arah bila aplikasi membesar. |
| Layar sangat panjang | `search_screen.dart`, `ringkasan_screen.dart`, dan `transaction_screen.dart` masing-masing lebih dari 1.200 baris dan mencampur tampilan dengan logika pemuatan data. |
| Variabel tidak terpakai | `home_screen.dart` mengisi `monthlySummaryIncome/Expense/Total`, tetapi widget ringkasan bulanan menghitung sendiri lewat `_calculateMonthlySummaryForWallet()`. |
| Catatan analisis | `dart analyze lib` melaporkan sekitar 31 catatan tingkat *info*: `withOpacity` sudah usang (ganti `withValues`), `BuildContext` dipakai setelah `await`, `print` di kode produksi, `WillPopScope` sudah usang (ganti `PopScope`), dan lainnya. Tidak ada error atau peringatan. |
| Pembuat controller di `build` | `register_screen.dart` dan `register_3_screen.dart` membuat `TextEditingController` di dalam `build`, sehingga isian bisa ter-reset saat layar dibangun ulang. |

## Perilaku pendaftaran

Pendaftaran tidak atomik. Pengguna dan kategori bawaan dibuat lebih dulu, lalu dompet oleh `AuthViewModel`. Bila proses terputus di antaranya (misalnya aplikasi ditutup paksa), akun sudah ada tanpa dompet, sehingga mendaftar ulang dengan email yang sama ditolak (`Email sudah terdaftar`). Pengguna harus masuk dengan akun itu dan menambah dompet dari Profil.

## Platform

Folder `web`, `linux`, `windows`, dan `macos` ada dari template Flutter. Pengembangan dan pengujian selama ini berfokus pada Android dan iOS, jadi platform lain belum diverifikasi.
