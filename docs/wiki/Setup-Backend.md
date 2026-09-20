# Setup Backend

Panduan ini membuat backend Ringkas dari nol di akun Google Anda. Waktu yang dibutuhkan sekitar 10 menit. Semua langkah dilakukan di browser, dan Anda harus login sebagai pemilik akun Google itu.

## 1. Buat spreadsheet

1. Buka [sheets.new](https://sheets.new) untuk membuat spreadsheet kosong.
2. Beri nama, misalnya `Database Ringkas`.

Anda tidak perlu membuat sheet atau kolom sendiri. Langkah 3 melakukannya otomatis.

## 2. Pasang script

1. Di spreadsheet, buka **Ekstensi > Apps Script**.
2. Hapus kode contoh di editor.
3. Salin seluruh isi [`apps_script/Code.gs`](../../apps_script/Code.gs) dan tempel ke editor.
4. Klik ikon simpan.

## 3. Buat sheet dan header

1. Pilih fungsi **`setup`** pada dropdown di atas editor.
2. Klik **Jalankan**.
3. Izinkan akses ketika diminta. Jika muncul peringatan *"Google hasn't verified this app"*, pilih **Lanjutan > Buka (tidak aman)**. Ini normal untuk script pribadi.

Setelah selesai, spreadsheet berisi sheet `users`, `sessions`, `dompet`, `kategori`, dan `transaksi` dengan header yang benar. Detailnya ada di [Struktur Spreadsheet](Struktur-Spreadsheet.md).

## 4. Deploy sebagai Web App

1. Klik **Deploy > Deployment baru**.
2. Klik ikon roda gigi dan pilih jenis **Aplikasi web**.
3. Isi:
   - **Jalankan sebagai:** *Saya*
   - **Yang memiliki akses:** ***Siapa saja*** (bukan "Siapa saja yang memiliki Akun Google")
4. Klik **Deploy**, lalu salin **URL aplikasi web**. URL yang benar berakhiran **`/exec`**.

> **Jangan memakai URL `/dev`.** URL itu berasal dari *Uji deployment* dan hanya bisa dibuka oleh Anda yang sedang login. Aplikasi akan menerima halaman login (HTTP 401) dan menampilkan `Respons server tidak valid`.

## 5. Hubungkan ke aplikasi

Isi URL `/exec` ke `ApiService.baseUrl` di `lib/data/services/api_service.dart`, lalu **Stop dan Run** ulang aplikasi (nilainya `const`).

## 6. Uji tanpa aplikasi (opsional)

Buka URL `/exec` di browser. Jawaban yang benar:

```json
{"status":"success","message":"Ringkas API aktif"}
```

Uji login dengan akun yang belum ada. Perintah ini tidak menulis apa pun:

```bash
curl -sL -X POST -H 'Content-Type: text/plain' \
  -d '{"method":"POST","path":"/login","body":{"email":"x@x.com","password":"x"}}' \
  "https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec"
```

Hasil yang benar: `{"status":"error","message":"Email atau password salah"}`.

## Memperbarui kode

Setiap kali `Code.gs` diubah, deployment harus diberi **versi baru**. Tanpa itu, URL `/exec` tetap menjalankan kode lama.

1. Tempel kode terbaru ke editor Apps Script dan simpan.
2. **Deploy > Kelola deployment**.
3. Klik ikon pensil pada deployment yang ada.
4. Pada **Versi**, pilih **Versi baru**, lalu **Deploy**.

URL `/exec` tidak berubah. Jangan memilih *Deployment baru* karena itu menghasilkan URL baru.

## Pengaturan keamanan setelah selesai

Spreadsheet **tidak perlu dibagikan**. Script berjalan sebagai Anda sehingga tetap bisa membacanya. Pastikan **Bagikan > Akses umum** bernilai **Dibatasi**. Alasannya ada di [Keamanan](Keamanan.md).

## Pemecahan masalah

| Gejala | Penyebab | Solusi |
|---|---|---|
| `Respons server tidak valid...` | `baseUrl` masih placeholder, URL bukan `/exec`, atau akses deployment bukan "Siapa saja" | Periksa URL dan pengaturan akses di **Kelola deployment** |
| Respons HTTP 401 atau halaman login Google | URL `/dev`, atau akses "Siapa saja yang memiliki Akun Google" | Pakai URL `/exec` dan ubah akses menjadi "Siapa saja" |
| Halaman HTML 404 dari Google | ID deployment salah atau deployment sudah dihapus | Salin ulang URL dari **Kelola deployment** |
| `Unauthenticated` | Token tidak dikenal, atau baris sesinya tidak punya `user_id` | **Keluar lalu masuk lagi** dari menu Profil |
| `Header sheet "x" salah. Baris 1 harus: ...` | Header baris 1 diubah atau terhapus | Kembalikan header sesuai [Struktur Spreadsheet](Struktur-Spreadsheet.md), atau jalankan `setup()` lagi |
| Perubahan kode tidak berpengaruh | Deployment belum diberi versi baru | Lihat [Memperbarui kode](#memperbarui-kode) |
| `Email sudah terdaftar` saat mendaftar ulang setelah gagal di tengah | Akun sempat dibuat sebelum langkah berikutnya gagal | Hapus baris akun itu di `users` dan `sessions`, atau pakai email lain |
| Kategori kosong pada pengguna lama | Kategori bawaan hanya dibuat saat mendaftar | Tambah kategori lewat aplikasi, atau daftar ulang dengan email lain |
| Loading lama atau tidak stabil | Latensi Apps Script | Lihat [Kuota dan Performa](Kuota-dan-Performa.md), dan periksa menu **Eksekusi** di editor Apps Script |
