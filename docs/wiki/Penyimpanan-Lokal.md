# Penyimpanan Lokal

Semua data Ringkas disimpan di perangkat dengan [Hive CE](https://pub.dev/packages/hive_ce), database kunci–nilai murni Dart. Seluruh logika ada di satu berkas: [`lib/data/services/api_service.dart`](../../lib/data/services/api_service.dart).

## Cara kerja

- Ada **4 box** (semacam tabel): `users`, `dompet`, `kategori`, `transaksi`.
- Tiap baris adalah sebuah `Map` yang disimpan dengan **kunci berupa `id` bertipe angka**. Nilainya hanya berisi tipe dasar (angka, teks, boolean), sehingga **tidak perlu adapter dan tidak perlu *code generation***.
- `id` dibuat dengan mengambil kunci terbesar lalu ditambah 1.
- Semua box dibuka sekali di `main()` lewat `openLocalDb()`.
- Data berada di folder dokumen aplikasi. Hive memuat isi box ke memori, jadi pembacaan cepat.

`ApiService` mempertahankan nama method dan bentuk hasil dari versi backend sebelumnya, sehingga layar tidak perlu tahu bahwa datanya sekarang lokal.

## Isi tiap box

Kolom `id`, `created_at`, dan `updated_at` diisi otomatis. Waktu berformat `yyyy-MM-dd HH:mm:ss`.

### users
| Field | Contoh | Keterangan |
|---|---|---|
| `name` | `Budi` | Nama pengguna |
| `email` | `budi@mail.com` | Huruf kecil, unik |
| `password_hash` | `9f86d0...` | `SHA-256("email:password")`. Password asli tidak disimpan. |

### dompet
| Field | Contoh | Keterangan |
|---|---|---|
| `user_id` | `1` | Pemilik |
| `name` | `Tunai` | |
| `currency` | `IDR` | |
| `initial_balance` | `500000.0` | Saldo awal. Saldo saat ini **tidak disimpan**, tapi dihitung. |
| `is_active` | `true` | |

### kategori
| Field | Contoh | Keterangan |
|---|---|---|
| `user_id` | `1` | Pemilik. Tiap pengguna punya kategorinya sendiri. |
| `name` | `Makanan & Minuman` | |
| `kind` | `expense` | `income` (pemasukan) atau `expense` (pengeluaran) |
| `color` | `#FF7043` | Kode warna hex |
| `icon` | `restaurant` | Nama ikon yang dikenali aplikasi (lihat `icon_picker_page.dart`) |

#### Kategori bawaan
Pengguna baru mendapat 10 kategori saat mendaftar. Daftarnya ada di konstanta `_defaultCategories`.

| Jenis | Kategori |
|---|---|
| Pengeluaran | Makanan & Minuman, Transportasi, Belanja, Tagihan, Hiburan, Kesehatan, Pendidikan |
| Pemasukan | Gaji, Bonus, Investasi |

Kategori ini biasa saja: bisa diubah dan dihapus.

### transaksi
| Field | Contoh | Keterangan |
|---|---|---|
| `user_id` | `1` | Pemilik |
| `category_id` | `3` | Kategori. Dari sini diketahui pemasukan atau pengeluaran. |
| `dompet_id` | `1` | Dompet yang dipakai |
| `trx_date` | `2026-09-20 12:15:00` | Hanya 10 karakter pertama (`yyyy-MM-dd`) yang dipakai untuk filter |
| `amount` | `25000.0` | Selalu positif. Tanda ditentukan oleh `kind` kategori. |
| `note` | `Makan siang` | |

## Aturan dan perhitungan

- **Pemilik data.** Setiap baca, ubah, dan hapus memeriksa `user_id`, sehingga pengguna hanya bisa menyentuh datanya sendiri.
- **Saldo dompet** = `initial_balance` + pemasukan − pengeluaran dari transaksi dompet itu.
- **Saldo awal** (untuk laporan) = jumlah saldo awal semua dompet + efek transaksi sebelum tanggal mulai. **Saldo akhir** = saldo awal + efek transaksi dalam hasil.
- **Pencarian** mencocokkan kata kunci ke catatan dan nama kategori (tidak peka huruf besar-kecil).
- **Hapus dompet** ikut menghapus semua transaksinya. **Hapus kategori** ditolak selama masih dipakai transaksi.
- Transaksi hanya boleh memakai kategori dan dompet milik penggunanya, dengan nominal lebih dari 0.

## Sesi login

Token login adalah **id pengguna** (`access_token: "1"`). Token disimpan di `shared_preferences` dengan kunci `authToken`. Token yang tidak cocok dengan pengguna mana pun ditolak dengan `Unauthenticated`. Ini cukup untuk data lokal, tapi **bukan rahasia** (lihat [Keamanan](Keamanan.md)).

## Mengubah skema

Karena baris hanyalah `Map`, mengubah bentuk data jauh lebih ringan daripada database SQL.

| Perubahan | Cara |
|---|---|
| **Menambah field** | Cukup tambahkan kunci baru saat membuat atau mengubah baris. Baris lama tidak punya kunci itu, jadi saat membaca beri nilai bawaan, misalnya `row['catatan'] ?? ''`. |
| **Mengganti nama field** | Tidak ada migrasi otomatis. Tulis satu kali proses yang membaca semua baris box, menyalin nilai ke nama baru, dan menyimpannya. Jalankan saat aplikasi pertama dibuka setelah pembaruan. |
| **Mengganti tipe field** | Sama seperti mengganti nama: ubah nilai semua baris lama sekali jalan. |
| **Menambah box** | Tambahkan namanya ke daftar di `openLocalDb()`. |

Tidak ada nomor versi skema. Jika perubahan makin banyak, simpan satu nomor versi di `shared_preferences` dan jalankan langkah migrasi berurutan saat aplikasi dibuka.

## Batasan yang perlu diketahui

- **Tidak ada kueri.** Filter, pencarian, dan penjumlahan dikerjakan di Dart dengan memindai baris. Untuk ribuan transaksi ini tetap cepat. Untuk puluhan ribu, pertimbangkan pindah ke database SQL.
- **Tidak ada transaksi database.** Pendaftaran membuat pengguna, lalu kategori, lalu dompet secara berurutan. Jika terputus di tengah, sebagian data sudah tersimpan.
- **Tidak terenkripsi.** Hive CE mendukung enkripsi AES-256 per box (`HiveAesCipher`), tapi belum dipakai.
- **Tidak ada cadangan.** Data hilang bila aplikasi dihapus, datanya dibersihkan, atau perangkat rusak. Ekspor atau impor JSON adalah tambahan yang paling masuk akal berikutnya.
- **Tidak ada sinkron antar perangkat.**

## Pengujian

[`test/local_api_test.dart`](../../test/local_api_test.dart) menguji lapisan ini memakai Hive di direktori sementara, tanpa emulator:

```bash
flutter test test/local_api_test.dart
```

Cakupannya: register dan login, penolakan email ganda, password salah, dan token palsu; perhitungan saldo saat transaksi ditambah, diubah, dan dihapus; urutan, filter, pencarian, serta saldo awal dan akhir; pemisahan data antar pengguna; hapus berantai dan proteksi kategori terpakai; validasi nominal; dan data yang bertahan setelah database ditutup lalu dibuka lagi.
