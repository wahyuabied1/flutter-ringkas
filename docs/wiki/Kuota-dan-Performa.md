# Kuota dan Performa

## Kuota Google

Angka berikut diambil dari dokumentasi resmi Google pada **20 September 2026**. Kuota bisa berubah, jadi periksa sumbernya bila akan mengandalkannya.

### Apps Script (jalur yang dipakai sekarang)

| Kuota | Akun Gmail biasa |
|---|---|
| Waktu jalan per eksekusi | 6 menit |
| Eksekusi bersamaan per pengguna | **30** |
| Eksekusi bersamaan per script | 1.000 |
| Batas harian untuk `doGet`/`doPost` | Tidak disebutkan di dokumentasi |

Kuota harian lain (trigger 90 menit per hari, URL Fetch 20.000 per hari, spreadsheet baru 250 per hari) tidak terpakai karena script tidak memakai trigger maupun `UrlFetchApp`.

Deployment berjalan sebagai pemilik ("Jalankan sebagai: Saya"), sehingga **semua pengguna aplikasi dihitung sebagai satu pengguna**. Batas 30 eksekusi bersamaan berlaku untuk seluruh aplikasi. Karena satu layar mengirim 3 sampai 4 request paralel, sekitar 8 sampai 10 orang yang membuka layar bersamaan sudah mendekati batas itu. Untuk tahap awal dengan sedikit pengguna, ini cukup.

Tidak adanya batas harian di dokumentasi tidak menjamin tanpa batas. Google tetap bisa memperlambat atau menolak request bila terlalu banyak dalam waktu singkat.

### Google Sheets API (jika suatu saat diakses langsung)

| Kuota | Nilai |
|---|---|
| Baca per menit, per project | 300 |
| Baca per menit, per pengguna per project | 60 |
| Tulis per menit, per project | 300 |
| Tulis per menit, per pengguna per project | 60 |
| Batas harian | Tidak ada, selama tidak melewati batas per menit |
| Waktu habis | 180 detik |

Jika terlampaui, Google membalas HTTP 429 dan Anda perlu menunggu sekitar 1 menit. Bila aplikasi memakai satu service account bersama, seluruh aplikasi kemungkinan besar dihitung sebagai satu pengguna, artinya batas efektifnya 60 per menit untuk semua orang.

Sumber:
- [Batas Sheets API](https://developers.google.com/workspace/sheets/api/limits)
- [Kuota Apps Script](https://developers.google.com/apps-script/guides/services/quotas)

## Performa

### Kenapa terasa lambat
Waktu tunggu Apps Script bersifat tetap dan tidak bisa dihilangkan:

- Satu request ke Web App membutuhkan **sekitar 1,3 sampai 1,5 detik** walau script tidak membaca sheet sama sekali, termasuk redirect yang harus diikuti aplikasi.
- Setiap pembacaan sheet menambah waktu.
- Satu aksi seperti login biasanya membutuhkan **2,5 sampai 3,2 detik**.
- Request pertama setelah lama tidak dipakai bisa lebih lambat karena script perlu dijalankan dari kondisi mati (*cold start*).
- Pada beberapa pengukuran, waktu respons sempat melonjak ke puluhan detik tanpa penyebab yang dipastikan. Bila ini terjadi, lihat menu **Eksekusi** di editor Apps Script untuk membedakan apakah waktu habis di dalam script atau sebelum script mulai.

Angka-angka di atas berasal dari pengukuran selama pengembangan, bukan jaminan.

### Yang sudah dilakukan

| Optimasi | Dampak |
|---|---|
| Isi sheet dibaca **sekali per request** dan dipakai ulang | Pembacaan sheet untuk layar Beranda turun dari 14 menjadi 7 (hasil simulasi) |
| Token **di-cache 6 jam** di `CacheService` | Request tidak perlu membaca `sessions` dan `users` setiap kali |
| **Kunci hanya untuk request yang menulis** | Request baca (GET) bisa berjalan bersamaan |
| Layar Beranda, Transaksi, dan Ringkasan memuat data **paralel** (`Future.wait`) | Waktu tunggu mendekati satu request, bukan tiga atau empat berturut-turut |
| Pembuatan 10 kategori bawaan dengan **satu kali tulis** (`insertMany`) | Register tidak melakukan 10 tulis terpisah |

### Ide lanjutan (belum dikerjakan)
- Satu endpoint `/batch` yang menjawab beberapa permintaan sekaligus, sehingga satu layar hanya menanggung satu waktu tunggu tetap.
- Menampilkan data yang tersimpan di perangkat lebih dulu, lalu memperbaruinya dari server.
- Memindahkan penyimpanan ke database sungguhan (Firebase atau Supabase) bila target respons di bawah satu detik atau pengguna mulai banyak.
