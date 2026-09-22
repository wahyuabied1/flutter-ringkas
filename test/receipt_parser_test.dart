// Contoh teks di bawah ini dibuat sendiri (bukan hasil OCR sungguhan dari
// aplikasi OVO/GoPay) untuk merepresentasikan pola umum: judul aksi, nominal
// dengan "Rp", nama pihak lain, tanggal berbahasa Indonesia, dan label
// metadata. Belum diverifikasi terhadap screenshot asli — kalau pola
// aslinya berbeda, sesuaikan kata kunci di receipt_parser.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:Ringkas/data/model/category_model.dart';
import 'package:Ringkas/data/services/receipt_parser.dart';

void main() {
  group('parseReceipt', () {
    test('pengeluaran dengan tanda minus dan tanggal lengkap (OVO)', () {
      const text = '''
OVO
Pembayaran Berhasil
- Rp 45.000
Toko Kopi Kenangan
12 Januari 2026, 14:30
No. Referensi: 1234567890
Metode Pembayaran: OVO Cash
Selesai
''';
      final r = parseReceipt(text);
      expect(r.kind, TrxKind.expense);
      expect(r.amount, 45000.0);
      expect(r.date, DateTime(2026, 1, 12, 14, 30));
      expect(r.note, 'Toko Kopi Kenangan');
    });

    test('pemasukan tanpa tanda, dikenali dari kata "Terima Uang", angka format koma-ribuan', () {
      const text = '''
OVO
Terima Uang
Rp100,000
Dari Budi Santoso
21 Sep 2026
Status: Berhasil
''';
      final r = parseReceipt(text);
      expect(r.kind, TrxKind.income);
      expect(r.amount, 100000.0);
      expect(r.date, DateTime(2026, 9, 21));
      expect(r.note, 'Dari Budi Santoso');
    });

    test('pengeluaran GoPay dikenali dari kata "Checkout"', () {
      const text = 'GoPay\nCheckout Berhasil\nRp25.000\nIndomaret\n01 Februari 2026\n';
      final r = parseReceipt(text);
      expect(r.kind, TrxKind.expense);
      expect(r.amount, 25000.0);
      expect(r.note, 'Indomaret');
    });

    test('pemasukan GoPay dikenali dari kata "Isi Saldo"', () {
      const text = 'GoPay\nIsi Saldo GoPay\nRp50.000\nBCA Virtual Account\n05 Maret 2026\n';
      final r = parseReceipt(text);
      expect(r.kind, TrxKind.income);
      expect(r.amount, 50000.0);
    });

    test('nominal dengan pemisah ribuan titik dan desimal koma', () {
      const text = 'Rincian Transaksi\nTotal Rp50.000,00\nWarung Bu Sari\n';
      final r = parseReceipt(text);
      expect(r.amount, 50000.0);
      expect(r.note, 'Warung Bu Sari');
    });

    test('nominal tiga digit di belakang koma tidak salah dibaca sebagai jam', () {
      // "14.300" seharusnya dibaca sebagai Rp14.300, bukan jam 14:30.
      const text = 'Pembayaran\nRp14.300\nMinimarket\n10 Maret 2026\n';
      final r = parseReceipt(text);
      expect(r.amount, 14300.0);
      expect(r.date, DateTime(2026, 3, 10)); // tanpa jam
    });

    test('teks tanpa nominal atau tanggal: tidak melempar error, nilai kosong', () {
      const text = 'Halo\nSelamat datang\n';
      final r = parseReceipt(text);
      expect(r.amount, isNull);
      expect(r.date, isNull);
      expect(r.kind, TrxKind.expense); // default paling umum
      expect(r.note, isNotEmpty);
    });

    test('teks kosong tidak melempar error', () {
      final r = parseReceipt('');
      expect(r.amount, isNull);
      expect(r.date, isNull);
      expect(r.note, 'Transaksi');
    });

    test('baris "Total" dipilih di atas nominal lain (mis. biaya admin)', () {
      const text = 'Biaya Admin Rp0\nTotal Rp75.000\nBengkel Jaya\n';
      final r = parseReceipt(text);
      expect(r.amount, 75000.0);
    });
  });

  group('guessCategoryId', () {
    final expenseCats = [
      Category(id: 1, userId: 1, name: 'Makanan & Minuman', kind: CategoryKind.expense),
      Category(id: 2, userId: 1, name: 'Transportasi', kind: CategoryKind.expense),
    ];
    final incomeCats = [
      Category(id: 3, userId: 1, name: 'Gaji', kind: CategoryKind.income),
    ];

    test('cocok lewat kata kunci merchant (kopi -> Makanan & Minuman)', () {
      final id = guessCategoryId(
        categories: expenseCats, kind: TrxKind.expense, note: 'Toko Kopi Kenangan',
      );
      expect(id, 1);
    });

    test('cocok lewat kata kunci merchant GoPay/Gojek (gojek -> Transportasi)', () {
      final id = guessCategoryId(
        categories: expenseCats, kind: TrxKind.expense, note: 'Gojek - GoRide',
      );
      expect(id, 2);
    });

    test('cocok lewat nama kategori yang disebut langsung di catatan', () {
      final id = guessCategoryId(
        categories: expenseCats, kind: TrxKind.expense, note: 'Bayar Transportasi ojek',
      );
      expect(id, 2);
    });

    test('cocok lewat nama kategori kustom yang tidak ada di kata kunci bawaan', () {
      // Kategori & catatan ini sengaja tidak memakai kata kunci apa pun dari
      // _categoryKeywords, supaya jalur pencocokan nama langsung teruji sendiri.
      final custom = [Category(id: 7, userId: 1, name: 'Oleh-oleh', kind: CategoryKind.expense)];
      final id = guessCategoryId(
        categories: custom, kind: TrxKind.expense, note: 'Beli oleh-oleh dari Bandung',
      );
      expect(id, 7);
    });

    test('cocok untuk pemasukan (gaji)', () {
      final id = guessCategoryId(
        categories: incomeCats, kind: TrxKind.income, note: 'Gaji Bulan September',
      );
      expect(id, 3);
    });

    test('tidak ada yang cocok -> null, bukan tebakan sembarangan', () {
      final id = guessCategoryId(
        categories: expenseCats, kind: TrxKind.expense, note: 'Dari Budi Santoso',
      );
      expect(id, isNull);
    });

    test('tidak ada kategori dengan jenis yang sesuai -> null, tidak error', () {
      final id = guessCategoryId(categories: incomeCats, kind: TrxKind.expense, note: 'kopi');
      expect(id, isNull);
    });

    test('kategori yang sudah diganti nama pengguna tidak dipaksakan cocok', () {
      final renamed = [Category(id: 9, userId: 1, name: 'Jajan', kind: CategoryKind.expense)];
      final id = guessCategoryId(categories: renamed, kind: TrxKind.expense, note: 'Toko Kopi Kenangan');
      expect(id, isNull); // batasan yang disengaja, bukan bug
    });
  });
}
