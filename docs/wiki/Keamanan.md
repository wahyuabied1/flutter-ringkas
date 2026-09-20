# Keamanan

Karena data disimpan di perangkat dan tidak dikirim ke mana pun, permukaan risikonya jauh lebih kecil daripada aplikasi berbackend. Halaman ini mencatat apa yang sudah ada dan apa yang perlu diperhatikan.

## Yang sudah ada

| Hal | Cara |
|---|---|
| Password | Disimpan sebagai `SHA-256("email:password")`. Password asli tidak pernah ditulis ke penyimpanan. |
| Pemisahan data | Setiap baca, ubah, dan hapus memeriksa `user_id`. Akun lain di perangkat yang sama tidak bisa menyentuh data ini lewat aplikasi. |
| Kepemilikan relasi | Transaksi hanya boleh memakai kategori dan dompet milik penggunanya sendiri. |
| Data keluar perangkat | Tidak ada. Aplikasi tidak memakai internet untuk data. |

## Yang perlu diperhatikan

### 1. Data tidak terenkripsi
File database Hive tersimpan sebagai berkas biasa di folder aplikasi. Perangkat yang sudah di-*root* atau dicadangkan tanpa proteksi bisa membacanya. Hive CE mendukung enkripsi AES-256 per box (`HiveAesCipher`) dengan kunci yang disimpan di penyimpanan aman (misalnya `flutter_secure_storage`). Belum dipakai.

### 2. Hash password hanya pelindung ringan
SHA-256 yang cepat dihitung mudah ditebak secara brute-force bila berkas database bocor. Cukup untuk data lokal, karena penyerang yang sudah memegang berkasnya juga bisa membaca datanya langsung. Bila kelak ada layar kunci aplikasi, gunakan biometrik atau PIN dari sistem.

### 3. Token bukan rahasia
Token adalah id pengguna. Fungsinya hanya menandai akun yang sedang aktif di perangkat, bukan membuktikan identitas. Jangan dipakai bila suatu saat ada backend.

### 4. Tidak ada cadangan
Data hilang bila aplikasi dihapus, datanya dibersihkan, atau perangkat rusak atau hilang. Ini risiko kehilangan data, bukan kebocoran, tapi paling mungkin dirasakan pengguna. Ekspor atau impor (JSON atau CSV) adalah tambahan yang paling masuk akal.

### 5. Pemulihan password tidak ada
Tidak ada cara mengatur ulang password. Pengguna yang lupa tidak bisa masuk ke akun itu.

## Bila akan dirilis ke Play Store

- Siapkan **kebijakan privasi** dan isi formulir **Data safety** dengan jujur. Karena data tidak dikirim keluar perangkat, jawabannya bisa mencerminkan bahwa data tidak dikumpulkan, tetapi periksa ketentuan terbaru di Play Console.
- Periksa apakah syarat **penghapusan akun** berlaku untuk akun lokal. Menyediakan opsi hapus akun dan datanya di menu Profil adalah pilihan yang aman. Fitur itu **belum ada**.
- Isi **Financial features declaration** di Play Console.
- Ganti kunci tanda tangan rilis (lihat [Catatan Teknis](Catatan-Teknis.md#sebelum-rilis-ke-play-store)).
