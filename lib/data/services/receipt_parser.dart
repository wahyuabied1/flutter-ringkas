import '../model/category_model.dart';

/// Jenis transaksi yang dibaca dari struk/notifikasi e-wallet (OVO, GoPay, dll).
enum TrxKind { expense, income }

/// Hasil pembacaan satu screenshot. Semua field bisa kosong/null kalau
/// polanya tidak dikenali; layar pemindaian tetap menampilkan formulir
/// supaya pengguna melengkapi atau membetulkannya sebelum disimpan.
class ParsedReceipt {
  final double? amount;
  final DateTime? date;
  final TrxKind kind;
  final String note;

  const ParsedReceipt({
    required this.amount,
    required this.date,
    required this.kind,
    required this.note,
  });
}

/// Bulan bahasa Indonesia, termasuk singkatan yang umum dipakai notifikasi.
const _idMonths = {
  'januari': 1, 'jan': 1,
  'februari': 2, 'feb': 2,
  'maret': 3, 'mar': 3,
  'april': 4, 'apr': 4,
  'mei': 5,
  'juni': 6, 'jun': 6,
  'juli': 7, 'jul': 7,
  'agustus': 8, 'agu': 8, 'ags': 8,
  'september': 9, 'sep': 9, 'sept': 9,
  'oktober': 10, 'okt': 10,
  'november': 11, 'nov': 11,
  'desember': 12, 'des': 12,
};

/// Baris "label" khas tampilan e-wallet (judul aksi, status, metadata) yang
/// bukan nama merchant/catatan, jadi disingkirkan saat mencari catatan.
const _labelLines = {
  'ovo', 'gopay', 'status', 'berhasil', 'sukses', 'success', 'gagal', 'pending', 'diproses',
  'selesai', 'pembayaran', 'pembelian', 'terima uang', 'kirim uang', 'top up', 'transfer',
  'penarikan', 'tarik tunai', 'metode pembayaran', 'no. referensi', 'no referensi',
  'nomor referensi', 'id transaksi', 'transaction id', 'nominal', 'jumlah', 'total',
  'biaya admin', 'biaya layanan', 'saldo ovo', 'saldo gopay', 'saldo cash', 'poin ovo',
  'gopay coins', 'points', 'bagikan', 'lihat detail', 'kembali ke beranda', 'butuh bantuan',
  'pusat bantuan', 'simpan bukti', 'unduh', 'download', 'riwayat transaksi', 'detail transaksi',
  'rincian transaksi', 'tanggal transaksi', 'waktu transaksi',
};

/// Kata kunci penanda pemasukan/pengeluaran (mencakup istilah umum OVO dan
/// GoPay), dipakai hanya kalau tanda +/- di depan "Rp" tidak ditemukan.
const _incomeKeywords = [
  'terima uang', 'diterima', 'top up', 'topup', 'top-up', 'isi saldo', 'transfer masuk',
  'uang masuk', 'refund', 'pengembalian dana', 'cashback', 'menerima', 'gopay coins',
];
const _expenseKeywords = [
  'pembayaran', 'bayar', 'kirim uang', 'pembelian', 'beli', 'checkout', 'tarik tunai',
  'penarikan', 'transfer keluar', 'uang keluar', 'biaya admin',
];

/// Kata kunci merchant/tujuan -> nama kategori bawaan yang cocok
/// (lihat 10 kategori bawaan di apps_script lama / seedCategories ApiService).
/// Dipakai untuk menebak kategori; kalau pengguna sudah mengganti nama
/// kategorinya, tebakan ini bisa tidak menemukan apa pun dan itu wajar,
/// karena kecocokan tetap dicek lewat nama kategori kunci di bawah.
const _categoryKeywords = <String, List<String>>{
  'Makanan & Minuman': [
    'makan', 'minum', 'resto', 'restoran', 'cafe', 'kafe', 'kopi', 'food',
    'warung', 'nasi', 'ayam', 'burger', 'pizza', 'mcdonald', 'mcd', 'kfc',
    'starbucks', 'gofood', 'grabfood', 'chatime', 'bakso', 'mie',
  ],
  'Transportasi': [
    'grab', 'gojek', 'gocar', 'goride', 'grabcar', 'taxi', 'taksi', 'ojek', 'parkir',
    'tol', 'bensin', 'pertamina', 'shell', 'mrt', 'krl', 'transjakarta', 'busway',
  ],
  'Belanja': [
    'shopee', 'tokopedia', 'lazada', 'blibli', 'toko', 'mall', 'indomaret',
    'alfamart', 'supermarket', 'belanja',
  ],
  'Tagihan': [
    'listrik', 'pln', 'pdam', 'internet', 'wifi', 'indihome', 'pulsa',
    'paket data', 'bpjs', 'asuransi', 'cicilan', 'premi',
  ],
  'Hiburan': ['bioskop', 'cgv', 'xxi', 'netflix', 'spotify', 'game', 'tiket.com', 'tix'],
  'Kesehatan': ['apotek', 'rumah sakit', 'klinik', 'dokter', 'farmasi', 'kimia farma', 'halodoc', 'guardian'],
  'Pendidikan': ['sekolah', 'kursus', 'buku', 'les privat', 'universitas', 'kuliah'],
  'Gaji': ['gaji', 'payroll', 'salary'],
  'Bonus': ['bonus', 'cashback', 'reward', 'hadiah'],
  'Investasi': ['saham', 'reksadana', 'investasi', 'bibit', 'ajaib', 'emas'],
};

/// Membaca teks hasil OCR (dari `TextRecognizer.processImage(...).text`)
/// menjadi nominal, tanggal, jenis, dan catatan.
///
/// Ini murni pencocokan pola teks (regex dan kata kunci), bukan pemahaman
/// tampilan asli aplikasi e-wallet-nya, jadi hasilnya adalah **tebakan**
/// yang selalu perlu dicek pengguna sebelum disimpan — bukan kepastian.
ParsedReceipt parseReceipt(String rawText) {
  final lines = rawText
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  final lower = rawText.toLowerCase();

  final (amount: amount, isExpenseSign: sign) = _extractAmount(lines);
  final kind = _extractKind(lower, sign);
  final date = _extractDate(lower);
  final note = _extractNote(lines);

  return ParsedReceipt(amount: amount, date: date, kind: kind, note: note);
}

({double? amount, bool? isExpenseSign}) _extractAmount(List<String> lines) {
  final re = RegExp(r'([+-])?\s*Rp\.?\s*([\d][\d.,]*)', caseSensitive: false);
  RegExpMatch? firstMatch;
  RegExpMatch? totalMatch;
  for (final line in lines) {
    for (final m in re.allMatches(line)) {
      firstMatch ??= m;
      // "Total" biasanya menunjuk nominal utama transaksi, bukan biaya admin
      // atau nominal lain yang kadang muncul di baris lain.
      if (totalMatch == null && line.toLowerCase().contains('total')) {
        totalMatch = m;
      }
    }
  }
  final m = totalMatch ?? firstMatch;
  if (m == null) return (amount: null, isExpenseSign: null);
  final sign = m.group(1);
  final amount = _parseIdrNumber(m.group(2)!);
  return (amount: amount, isExpenseSign: sign == null ? null : sign == '-');
}

/// Mengubah angka bergaya Indonesia jadi [double]. Rupiah nyaris tak pernah
/// punya desimal, jadi titik/koma yang diikuti tepat 3 digit dianggap
/// pemisah ribuan dan dibuang; selain itu (1-2 digit) dianggap desimal.
double? _parseIdrNumber(String raw) {
  final buf = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final c = raw[i];
    if (c == '.' || c == ',') {
      final digitsAfter = RegExp(r'^\d+').firstMatch(raw.substring(i + 1))?.group(0)?.length ?? 0;
      if (digitsAfter == 3) continue; // pemisah ribuan
      buf.write('.'); // dianggap desimal
    } else {
      buf.write(c);
    }
  }
  return double.tryParse(buf.toString());
}

TrxKind _extractKind(String lowerText, bool? isExpenseSign) {
  if (isExpenseSign != null) return isExpenseSign ? TrxKind.expense : TrxKind.income;
  final hasIncome = _incomeKeywords.any(lowerText.contains);
  final hasExpense = _expenseKeywords.any(lowerText.contains);
  if (hasIncome && !hasExpense) return TrxKind.income;
  return TrxKind.expense; // default paling umum untuk pelacak pengeluaran
}

DateTime? _extractDate(String lower) {
  int? hour, minute;
  // (?<!\d) dan (?!\d) mencegah "14.300" (nominal) terbaca sebagai jam 14:30.
  final timeMatch = RegExp(r'(?<!\d)(\d{1,2})[.:](\d{2})(?!\d)').firstMatch(lower);
  if (timeMatch != null) {
    final h = int.tryParse(timeMatch.group(1)!)!;
    final mi = int.tryParse(timeMatch.group(2)!)!;
    if (h <= 23 && mi <= 59) {
      hour = h;
      minute = mi;
    }
  }

  // "12 januari 2026" atau "12 jan 2026"
  final wordMatch = RegExp(r'(\d{1,2})\s+([a-z]+)\s+(\d{4})').firstMatch(lower);
  if (wordMatch != null) {
    final day = int.tryParse(wordMatch.group(1)!);
    final month = _idMonths[wordMatch.group(2)!];
    final year = int.tryParse(wordMatch.group(3)!);
    if (day != null && month != null && year != null && day <= 31) {
      return DateTime(year, month, day, hour ?? 0, minute ?? 0);
    }
  }

  // "12/01/2026" atau "12-01-2026" (dd/mm/yyyy)
  final numMatch = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})').firstMatch(lower);
  if (numMatch != null) {
    final day = int.tryParse(numMatch.group(1)!);
    final month = int.tryParse(numMatch.group(2)!);
    var year = int.tryParse(numMatch.group(3)!);
    if (year != null && year < 100) year += 2000;
    if (day != null && month != null && year != null &&
        month >= 1 && month <= 12 && day >= 1 && day <= 31) {
      return DateTime(year, month, day, hour ?? 0, minute ?? 0);
    }
  }

  if (hour != null) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute ?? 0);
  }
  return null; // pemanggil memakai waktu sekarang sebagai bawaan
}

String _extractNote(List<String> lines) {
  final amountRe = RegExp(r'rp\.?\s*\d', caseSensitive: false);
  final dateWordRe = RegExp(r'\b(' + _idMonths.keys.join('|') + r')\b', caseSensitive: false);
  var best = '';
  for (final line in lines) {
    final trimmed = line.trim();
    final lower = trimmed.toLowerCase();
    if (_labelLines.any(lower.contains)) continue;
    if (amountRe.hasMatch(lower)) continue;
    if (dateWordRe.hasMatch(lower)) continue;
    if (RegExp(r'^[\d\s/.,:-]+$').hasMatch(trimmed)) continue; // hanya angka/tanggal
    final letterCount = trimmed.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (letterCount < 3) continue;
    if (trimmed.length > best.length) best = trimmed;
  }
  return best.isEmpty ? 'Transaksi' : best;
}

/// Menebak kategori pengguna yang paling cocok dengan [note] dan [kind].
/// Mengembalikan `null` kalau tidak ada yang cukup yakin cocok — biarkan
/// pengguna memilih sendiri di layar konfirmasi.
int? guessCategoryId({
  required List<Category> categories,
  required TrxKind kind,
  required String note,
}) {
  final wantKind = kind == TrxKind.expense ? CategoryKind.expense : CategoryKind.income;
  final candidates = categories.where((c) => c.kind == wantKind).toList();
  if (candidates.isEmpty) return null;
  final lowerNote = note.toLowerCase();

  // 1) Nama kategori pengguna sendiri disebut langsung di catatan.
  for (final c in candidates) {
    final name = c.name.trim().toLowerCase();
    if (name.isNotEmpty && lowerNote.contains(name)) return c.id;
  }

  // 2) Kata kunci merchant/tujuan bawaan, dicocokkan ke kategori yang
  //    namanya masih berkaitan dengan nama kategori bawaan itu.
  for (final entry in _categoryKeywords.entries) {
    if (!entry.value.any(lowerNote.contains)) continue;
    final key = entry.key.toLowerCase();
    for (final c in candidates) {
      final name = c.name.toLowerCase();
      if (name.contains(key) || key.contains(name)) return c.id;
    }
  }
  return null;
}
