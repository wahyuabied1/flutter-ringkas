# Fitur Aplikasi

Halaman ini menjelaskan apa yang dilihat dan dilakukan pengguna di tiap layar. Semua rute terdaftar di [`lib/main.dart`](../../lib/main.dart).

## Alur pertama kali membuka aplikasi

```
Splash ──(token ada)──────────────────────────────► Beranda
   │
   └─(token tidak ada)─► Onboarding ─► Welcome ─┬─► Masuk ───────► Beranda
                                                └─► Daftar (3 langkah) ─► Beranda
```

| Layar | Rute | Yang terjadi |
|---|---|---|
| Splash | `/splash` | Menampilkan logo sekitar 2 detik. Jika token login tersimpan di perangkat, langsung ke Beranda. Jika tidak, ke Onboarding. |
| Onboarding | `/onboarding` | 3 slide pengantar dengan tombol **Lewati**. Setelah selesai menuju Welcome. |
| Welcome | `/welcome` | Pilihan **Daftar** atau **Masuk**. |
| Masuk | `/login` | Email dan password. Jika berhasil, token disimpan lalu masuk ke Beranda. |

## Pendaftaran (3 langkah)

Data dari langkah 1 dan 2 ditampung dulu di state aplikasi. Akun baru disimpan di perangkat hanya saat langkah 3 diselesaikan. Akun ini bersifat lokal: hanya berlaku di perangkat tempat ia dibuat.

| Langkah | Rute | Isi |
|---|---|---|
| 1/3 Buat Akun | `/register` | Nama, email, password. Semua wajib diisi. |
| 2/3 Mata Uang | `/register-currency` | Pilihan mata uang: IDR, USD, EUR, JPY. |
| 3/3 Dompet & Saldo Awal | `/register-balance` | Nama dompet pertama (bawaan `Dompet Saya`) dan saldo awal. |

Saat **Selesai** ditekan, aplikasi berturut-turut membuat akun, membuat dompet pertama, menyimpan token, lalu langsung membuka Beranda **tanpa perlu login ulang**. Pengguna baru juga otomatis mendapat 10 kategori bawaan (lihat [Penyimpanan Lokal](Penyimpanan-Lokal.md#kategori-bawaan)).

## Navigasi utama

Empat tab di bagian bawah: **Beranda**, **Transaksi**, **Ringkasan**, **Profil**.

### Beranda (`/home`)
- Total saldo dari semua dompet.
- Pemilih dompet untuk melihat satu dompet saja.
- Ringkasan pemasukan dan pengeluaran bulan berjalan untuk dompet yang dipilih.
- Daftar transaksi terbaru.
- Jalan pintas untuk menambah transaksi.

### Transaksi (`/transaction`)
- Daftar transaksi dengan filter periode **Harian**, **Mingguan**, **Bulanan**, dan **Filter Tanggal**.
- **Cari Transaksi** (`/search`): pencarian dengan kata kunci, rentang tanggal, dan pilihan banyak kategori dan dompet.
- **Detail** (`/transaction-detail/<id>`): rincian satu transaksi dengan tombol **Edit** dan **Hapus**.

Tombol **+** di Beranda dan Transaksi membuka pilihan **Tambah Manual** atau **Pindai Struk**.

### Tambah dan ubah transaksi (`/add-transaction`)
Formulir yang sama dipakai untuk menambah dan mengubah.

| Kolom | Keterangan |
|---|---|
| Tanggal | Tanggal dan jam transaksi |
| Jumlah | Nominal, harus lebih dari 0 |
| Deskripsi | Catatan bebas, wajib diisi |
| Kategori | Dipilih dari daftar kategori; menentukan apakah transaksi pemasukan atau pengeluaran |
| Dompet | Dipilih dari daftar dompet |

Nominal selalu disimpan positif. Apakah saldo bertambah atau berkurang ditentukan oleh jenis kategorinya (`income` atau `expense`).

### Pindai Struk (`/scan-receipt`)
Alternatif tambah transaksi lewat screenshot notifikasi/struk pembayaran (OVO, GoPay, dan sejenisnya), tanpa mengetik satu per satu.

1. Pilih screenshot dari galeri.
2. Teksnya dibaca **di perangkat** dengan OCR (`google_mlkit_text_recognition`) — gambar tidak pernah dikirim ke internet.
3. Nominal, tanggal, jenis (pemasukan/pengeluaran), dan kategori **ditebak** dari pola teks dan kata kunci.
4. Hasilnya ditampilkan sebagai formulir yang sudah terisi — tombol **Pengeluaran** berwarna merah dan **Pemasukan** hijau, sama seperti di layar Tambah Manual — dengan teks mentah hasil OCR bisa dilihat lewat "Lihat teks hasil pemindaian". Semua field bisa diperbaiki sebelum disimpan lewat tombol **Simpan Transaksi**.

Ini adalah **tebakan berbasis pola teks**, bukan pemahaman tampilan aplikasi e-wallet yang sesungguhnya, jadi hasilnya perlu selalu diperiksa. Detail heuristik dan batasannya ada di [Penyimpanan Lokal](Penyimpanan-Lokal.md#pindai-struk).

### Ringkasan (`/ringkasan`)
- Grafik lingkaran (`fl_chart`) pengeluaran dan pemasukan per kategori.
- Periode **Harian**, **Mingguan**, **Bulanan**, dan **Filter Tanggal**.
- Saldo awal dan saldo akhir untuk periode yang dipilih.
- Rincian per kategori, dan daftar transaksi di dalam kategori itu.

### Profil (`/profile`)
- Nama pengguna dan daftar dompet.
- **Tambah**, **ubah**, dan **hapus** dompet. Menghapus dompet ikut menghapus semua transaksinya.
- **Keluar**: dialog konfirmasi, lalu token lokal dihapus dan aplikasi kembali ke Welcome.

## Kategori

Dibuka dari formulir transaksi (pilih kategori) dan halaman pengaturan kategori.

- Dua kelompok: **Pengeluaran** dan **Pemasukan**.
- Tambah dan ubah kategori dengan nama, jenis, **warna** (pemilih warna), dan **ikon** (pemilih ikon).
- Kategori tidak bisa dihapus selama masih dipakai transaksi.
- Kolom pencarian untuk menyaring daftar.

## Aturan penting
- Setiap pengguna hanya melihat dompet, kategori, dan transaksinya sendiri, meskipun beberapa akun dibuat di perangkat yang sama.
- Aplikasi berjalan sepenuhnya tanpa internet. Data tersimpan di perangkat dan tidak ikut pindah ke perangkat lain.
- Saldo dompet tidak disimpan. Nilainya dihitung setiap kali dibaca: `saldo awal + pemasukan - pengeluaran`.
- Tanggal ditampilkan dengan format Indonesia (`id_ID`), misalnya `dd/MM/yyyy HH:mm`.
