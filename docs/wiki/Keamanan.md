# Keamanan

Halaman ini menjelaskan apa yang sudah melindungi data, apa yang belum, dan langkah yang perlu dilakukan sebelum aplikasi dipakai orang lain.

## Yang sudah ada

| Hal | Cara |
|---|---|
| Password | Disimpan sebagai `SHA-256(salt + password)` dengan salt acak per pengguna. Password asli tidak pernah ditulis ke sheet. |
| Pemilik data | Ditentukan dari **token**, bukan dari `user_id` yang dikirim aplikasi. Pengguna tidak bisa membaca atau mengubah data pengguna lain dengan mengganti id. |
| Kepemilikan relasi | Transaksi hanya boleh memakai kategori dan dompet milik penggunanya sendiri. |
| Transportasi | Semua komunikasi lewat HTTPS. |
| Sheet rusak | Script menolak bekerja bila header sheet berubah, sehingga tidak diam-diam menyimpan data ke kolom yang salah. |

## Yang perlu diperhatikan

### 1. Batasi akses spreadsheet
Script berjalan sebagai pemilik spreadsheet, jadi sheet **tidak perlu dibagikan ke siapa pun**. Set **Bagikan > Akses umum** ke **Dibatasi**.

Jika sheet bisa diedit lewat link, siapa pun yang punya link dapat:
- membaca `password_hash`, `salt`, dan `token` semua pengguna;
- memakai token yang terbaca untuk masuk sebagai pengguna lain;
- menghapus atau merusak data, misalnya mengubah header sehingga seluruh aplikasi berhenti bekerja.

### 2. URL `/exec` bersifat publik
Deployment memakai akses **Siapa saja**, jadi siapa pun yang tahu URL-nya bisa memanggil `/register` dan `/login`. Data pengguna tetap dilindungi token, tetapi endpoint pendaftaran terbuka untuk penyalahgunaan (pendaftaran massal). URL ini juga terkirim di dalam aplikasi dan di repositori. Untuk memutarnya, buat deployment baru dan ganti `baseUrl`.

### 3. Hash password bukan bcrypt
SHA-256 dengan salt lebih baik daripada teks biasa, tetapi cepat dihitung sehingga lebih mudah ditebak secara brute-force bila sheet bocor. Cukup untuk prototipe. Untuk produksi, gunakan layanan autentikasi sungguhan.

### 4. Token tidak kedaluwarsa dan tidak bisa dicabut
- Sesi di sheet `sessions` berlaku selamanya.
- **Keluar** hanya menghapus token di perangkat. Barisnya di `sessions` tetap ada, sehingga token yang bocor tetap berlaku.
- Cache 6 jam adalah optimasi, bukan masa berlaku.

Untuk mencabut sesi, hapus barisnya dari `sessions` secara manual (cache bisa membuat token tetap dikenali sampai 6 jam).

### 5. Belum ada pembatasan percobaan login
Tidak ada batas jumlah percobaan password. Ini membuka celah tebak-tebakan password.

### 6. Data di perangkat
Token dan nama disimpan di `shared_preferences` (tidak dienkripsi). Cukup untuk saat ini, tetapi bukan tempat untuk data yang lebih sensitif.

## Bila akan dirilis ke Play Store

- Sediakan **kebijakan privasi** karena aplikasi mengumpulkan nama, email, password, dan data keuangan.
- Isi formulir **Data safety** dan **Financial features declaration** di Play Console.
- Sediakan **penghapusan akun** di dalam aplikasi dan lewat tautan web. Endpoint penghapusan akun **belum ada**.
- Jangan memasukkan kunci akses spreadsheet (service account) ke dalam aplikasi. Kunci di dalam APK dapat diekstrak dan memberi akses ke seluruh data.
- Pertimbangkan pindah ke backend dengan autentikasi bawaan (Firebase atau Supabase) bila pengguna sudah banyak.
