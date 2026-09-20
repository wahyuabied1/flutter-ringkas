# Arsitektur

## Gambaran besar

```mermaid
flowchart LR
    subgraph App["Aplikasi Flutter (di perangkat)"]
        V["Layar (features/*/view)"] --> A["ApiService"]
        VM["AuthViewModel (Riverpod)"] --> A
        A --> H[("Hive CE<br/>4 box")]
        V --> P[("shared_preferences")]
    end
```

Tidak ada server maupun koneksi internet. Semua layar mengambil dan menyimpan data lewat satu kelas, `ApiService`, yang membaca dan menulis box Hive. Detail penyimpanan ada di [Penyimpanan Lokal](Penyimpanan-Lokal.md).

## Struktur folder

| Folder | Isi |
|---|---|
| `lib/main.dart` | Titik masuk, membuka database, `ProviderScope`, tema, dan seluruh rute bernama |
| `lib/core/` | `app_theme.dart`: warna dan gaya bersama |
| `lib/data/model/` | Kelas data: `Wallet`, `Category`, `Transaction`, `User`, masing-masing dengan `fromJson` |
| `lib/data/services/` | `ApiService`: seluruh akses dan logika data |
| `lib/features/<fitur>/view/` | Layar (widget) |
| `lib/features/auth/viewmodel/` | `AuthViewModel` dan `AuthState` |
| `lib/shared/widget/` | Widget umum |

Fitur yang ada: `splash`, `onboarding`, `auth`, `home`, `transaksi`, `ringkasan`, `profile`.

## Kenapa nama kelasnya `ApiService`?
Kelas ini awalnya klien untuk backend jarak jauh. Setelah pindah ke penyimpanan lokal, nama method dan bentuk hasilnya sengaja dipertahankan (`Map` berisi `data`, `transactions`, `saldo_awal`, dan seterusnya) agar semua layar tetap bekerja tanpa diubah. Bila kelak ingin merapikan, mengganti nama kelas menjadi repository dan memakai model bertipe adalah langkah lanjutan yang wajar.

## State management

Ada dua gaya yang dipakai berdampingan:

- **Riverpod (`StateNotifier`)** hanya untuk alur autentikasi. `AuthViewModel` menampung data pendaftaran 3 langkah (`name`, `email`, `password`, `currencyCode`) dan status `initial`, `loading`, `success`, `error`. Layar register dan login mendengarkannya dengan `ref.listen`.
- **`StatefulWidget` + `setState`** untuk semua layar lain. Tiap layar membuat `ApiService` sendiri, memuat data di `initState`, dan menyimpannya di variabel state lokal.

## Navigasi

Semua rute didaftarkan di `MaterialApp.routes`. Satu rute dinamis, `/transaction-detail/<id>`, ditangani `onGenerateRoute`. Perpindahan setelah login, register, dan splash memakai `pushNamedAndRemoveUntil` agar tombol kembali tidak membawa pengguna ke layar autentikasi.

## Penyimpanan sesi

Disimpan lewat `shared_preferences`:

| Kunci | Isi | Ditulis saat |
|---|---|---|
| `authToken` | Token sesi (id pengguna) | Login dan register berhasil |
| `name` | Nama pengguna untuk sapaan | Login dan register berhasil |
| `userId` | Id pengguna | Login dan register berhasil |
| `initialBalance` | Salinan terakhir total saldo, dipakai bila data gagal dimuat | Beranda berhasil memuat data |

`authToken` menentukan layar pertama: jika ada, Splash langsung ke Beranda. Saat **Keluar**, hanya `authToken` dan `name` yang dihapus; `userId` dan `initialBalance` tetap tersimpan dan akan ditimpa saat pengguna masuk lagi.

## Alur data: pendaftaran

```mermaid
sequenceDiagram
    participant U as Pengguna
    participant S as Layar Register 3/3
    participant VM as AuthViewModel
    participant API as ApiService
    participant DB as Hive

    U->>S: tekan "Selesai"
    S->>VM: registerAndLogin(namaDompet, saldoAwal)
    VM->>API: registerUser
    API->>DB: simpan pengguna + 10 kategori bawaan
    API-->>VM: access_token + user
    VM->>API: createWallet(token)
    API->>DB: simpan dompet
    VM-->>S: status success
    S->>S: simpan token, nama, userId
    S->>U: buka Beranda
```

## Memuat data layar

Beranda, Transaksi, dan Ringkasan membutuhkan dompet, transaksi, dan kategori sekaligus. Ketiganya diminta bersamaan dengan `Future.wait`. Pola ini diwarisi dari versi yang memakai jaringan. Sekarang datanya lokal dan cepat, jadi hasilnya tidak berbeda jauh, dan pola ini tetap aman dipertahankan.

## Tema dan lokal

- Warna utama `#5D9E85`, warna sekunder `#C0EAD8` (`AppTheme`).
- Tanggal dan bulan memakai lokal `id_ID` lewat paket `intl`.
