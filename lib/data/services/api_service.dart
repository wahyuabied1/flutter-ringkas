import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive.dart';
import '../model/wallet_model.dart';
import '../model/category_model.dart';
import '../model/transaction_model.dart';

typedef Json = Map<String, dynamic>;

/// Membuka semua box Hive. Panggil sekali sebelum runApp, setelah Hive.init.
Future<void> openLocalDb() async {
  for (final n in ['users', 'dompet', 'kategori', 'transaksi']) {
    await Hive.openBox<Map>(n);
  }
}

// Kategori bawaan untuk pengguna baru: [nama, kind, warna, ikon]
const _defaultCategories = [
  ['Makanan & Minuman', 'expense', '#FF7043', 'restaurant'],
  ['Transportasi', 'expense', '#42A5F5', 'directions_car'],
  ['Belanja', 'expense', '#AB47BC', 'shopping_bag'],
  ['Tagihan', 'expense', '#EF5350', 'credit_card'],
  ['Hiburan', 'expense', '#FFCA28', 'movie'],
  ['Kesehatan', 'expense', '#26A69A', 'local_hospital'],
  ['Pendidikan', 'expense', '#5C6BC0', 'school'],
  ['Gaji', 'income', '#66BB6A', 'attach_money'],
  ['Bonus', 'income', '#5D9E85', 'card_giftcard'],
  ['Investasi', 'income', '#29B6F6', 'trending_up'],
];

/// Data disimpan di perangkat dengan Hive CE (satu box per tabel, isinya Map).
/// Token login adalah id pengguna. Nama method dan bentuk hasilnya sama seperti
/// versi backend sebelumnya, jadi layar tidak perlu diubah.
class ApiService {
  // ---------- akses box ----------
  Box<Map> _box(String n) => Hive.box<Map>(n);

  List<Json> _rows(String n, [bool Function(Json)? test]) => _box(n).values
      .map((m) => Json.from(m))
      .where(test ?? (_) => true)
      .toList();

  String _now() => DateTime.now().toString().substring(0, 19);

  Future<Json> _insert(String n, Json row) async {
    final id = _box(n).keys.fold<int>(0, (m, k) => max(m, k as int)) + 1;
    final saved = {...row, 'id': id, 'created_at': _now(), 'updated_at': _now()};
    await _box(n).put(id, saved);
    return saved;
  }

  /// Baris milik pengguna [uid], atau error jika tidak ada.
  Json _own(String n, dynamic id, int uid) {
    final r = _box(n).get(int.parse('$id'));
    if (r == null || r['user_id'] != uid) throw Exception('Data tidak ditemukan');
    return Json.from(r);
  }

  Future<Json> _update(String n, dynamic id, int uid, Json changes) async {
    final next = {..._own(n, id, uid), ...changes, 'updated_at': _now()};
    await _box(n).put(next['id'], next);
    return next;
  }

  Future<Json> _remove(String n, dynamic id, int uid) async {
    await _box(n).delete(_own(n, id, uid)['id']);
    return {};
  }

  // ---------- akun ----------
  String _hash(String email, String pw) =>
      sha256.convert(utf8.encode('$email:$pw')).toString();

  Json _session(Json u) => {
        'access_token': '${u['id']}',
        'user': {for (final k in ['id', 'name', 'email', 'created_at']) k: u[k]},
      };

  int _uid(String token) {
    final id = int.tryParse(token);
    if (id == null || !_box('users').containsKey(id)) {
      throw Exception('Unauthenticated');
    }
    return id;
  }

  Future<Json> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    email = email.trim().toLowerCase();
    if (_rows('users', (u) => u['email'] == email).isNotEmpty) {
      throw Exception('Email sudah terdaftar');
    }
    final user = await _insert('users', {
      'name': name,
      'email': email,
      'password_hash': _hash(email, password),
    });
    for (final c in _defaultCategories) {
      await _insert('kategori', {
        'user_id': user['id'], 'name': c[0], 'kind': c[1], 'color': c[2], 'icon': c[3],
      });
    }
    return _session(user);
  }

  Future<Json> loginUser({required String email, required String password}) async {
    email = email.trim().toLowerCase();
    final found = _rows('users',
        (u) => u['email'] == email && u['password_hash'] == _hash(email, password));
    if (found.isEmpty) throw Exception('Email atau password salah');
    return _session(found.first);
  }

  Future<Json> getCurrentUser({required String token}) async =>
      _session(Json.from(_box('users').get(_uid(token))!))['user'];

  // ---------- saldo ----------
  Map<int, String> _kinds(int uid) => {
        for (final c in _rows('kategori', (c) => c['user_id'] == uid))
          c['id'] as int: c['kind'] as String,
      };

  /// Pemasukan dikurangi pengeluaran dari [txs].
  double _net(Iterable<Json> txs, Map<int, String> kinds) => txs.fold(
      0.0,
      (s, t) =>
          s + (kinds[t['category_id']] == 'income' ? 1 : -1) * (t['amount'] as num));

  // ---------- dompet ----------
  Future<Json> getWallets({required String token}) async {
    final uid = _uid(token), kinds = _kinds(uid);
    final txs = _rows('transaksi', (t) => t['user_id'] == uid);
    final list = _rows('dompet', (w) => w['user_id'] == uid)
        .map((w) => {
              ...w,
              'current_balance': (w['initial_balance'] as num) +
                  _net(txs.where((t) => t['dompet_id'] == w['id']), kinds),
            })
        .toList();
    return {
      'data': list,
      'total_current_balance':
          list.fold<double>(0, (s, w) => s + (w['current_balance'] as num)),
    };
  }

  Future<List<Wallet>> getWalletsList({required String token}) async =>
      ((await getWallets(token: token))['data'] as List)
          .map((w) => Wallet.fromJson(w as Json))
          .toList();

  Future<Json> createWallet({
    required dynamic userId,
    required String name,
    required String currencyCode,
    required double initialBalance,
    required String token,
  }) async => _insert('dompet', {
        'user_id': _uid(token),
        'name': name,
        'currency': currencyCode,
        'initial_balance': initialBalance,
        'is_active': true,
      });

  Future<Json> updateWallet({
    required dynamic id,
    required String name,
    required String currencyCode,
    required double initialBalance,
    required String token,
  }) async => _update('dompet', id, _uid(token), {
        'name': name,
        'currency': currencyCode,
        'initial_balance': initialBalance,
      });

  /// Menghapus dompet beserta semua transaksinya.
  Future<Json> deleteWallet({required dynamic id, required String token}) async {
    final uid = _uid(token);
    await _remove('dompet', id, uid);
    await _box('transaksi').deleteAll(_rows(
            'transaksi', (t) => t['user_id'] == uid && '${t['dompet_id']}' == '$id')
        .map((t) => t['id']));
    return {};
  }

  // ---------- kategori ----------
  Future<List<Category>> getCategories({required String token}) async {
    final uid = _uid(token);
    return _rows('kategori', (c) => c['user_id'] == uid)
        .map(Category.fromJson)
        .toList();
  }

  Future<Json> createCategory({
    required dynamic userId,
    required String name,
    required String kind,
    required String colorHex,
    required String icon,
    required String token,
  }) async => _insert('kategori', {
        'user_id': _uid(token),
        'name': name,
        'kind': kind,
        'color': colorHex,
        'icon': icon,
      });

  Future<Json> updateCategory({
    required dynamic categoryId,
    required String name,
    required String kind,
    required String colorHex,
    required String icon,
    required String token,
  }) async => _update('kategori', categoryId, _uid(token),
      {'name': name, 'kind': kind, 'color': colorHex, 'icon': icon});

  Future<void> deleteCategory({
    required dynamic categoryId,
    required String token,
  }) async {
    final uid = _uid(token);
    if (_rows('transaksi',
            (t) => t['user_id'] == uid && '${t['category_id']}' == '$categoryId')
        .isNotEmpty) {
      throw Exception('Kategori masih dipakai transaksi');
    }
    await _remove('kategori', categoryId, uid);
  }

  // ---------- transaksi ----------
  /// Transaksi milik [uid] (terbaru dulu), sudah dilengkapi nama kategori dan dompet.
  List<Json> _txs(int uid, {
    String? start, String? end, String? search,
    List<int>? dompetIds, List<int>? categoryIds,
  }) {
    final cats = {for (final c in _rows('kategori', (c) => c['user_id'] == uid)) c['id']: c};
    final wallets = {for (final w in _rows('dompet', (w) => w['user_id'] == uid)) w['id']: w};
    String day(Json t) => (t['trx_date'] as String).substring(0, 10);
    final q = (search ?? '').toLowerCase();
    return _rows('transaksi', (t) =>
            t['user_id'] == uid &&
            (start == null || day(t).compareTo(start) >= 0) &&
            (end == null || day(t).compareTo(end) <= 0) &&
            (dompetIds == null || dompetIds.contains(t['dompet_id'])) &&
            (categoryIds == null || categoryIds.contains(t['category_id'])) &&
            '${t['note']} ${cats[t['category_id']]?['name']}'.toLowerCase().contains(q))
        .map((t) => {
              ...t,
              'kategori_name': cats[t['category_id']]?['name'],
              'kind': cats[t['category_id']]?['kind'],
              'dompet_name': wallets[t['dompet_id']]?['name'],
            })
        .toList()
      ..sort((a, b) {
        final d = day(b).compareTo(day(a));
        return d != 0 ? d : (b['id'] as int).compareTo(a['id'] as int);
      });
  }

  /// Kategori dan dompet harus milik pengguna, dan nominal harus positif.
  Json _txBody(int uid, dynamic categoryId, dynamic walletId, num amount) {
    _own('kategori', categoryId, uid);
    _own('dompet', walletId, uid);
    if (amount <= 0) throw Exception('Nominal harus lebih dari 0');
    return {'category_id': int.parse('$categoryId'), 'dompet_id': int.parse('$walletId')};
  }

  Future<Json> createTransaction({
    required dynamic userId,
    required String type,
    required double amount,
    required String note,
    required String trxDate,
    required dynamic categoryId,
    required dynamic walletId,
    required String token,
  }) async {
    final uid = _uid(token);
    return _insert('transaksi', {
      'user_id': uid,
      ..._txBody(uid, categoryId, walletId, amount),
      'trx_date': trxDate,
      'amount': amount,
      'note': note,
    });
  }

  Future<Json> updateTransaction({
    required String token,
    required dynamic id,
    required double amount,
    required String note,
    required String trxDate,
    required dynamic categoryId,
    required dynamic walletId,
  }) async {
    final uid = _uid(token);
    return _update('transaksi', id, uid, {
      ..._txBody(uid, categoryId, walletId, amount),
      'trx_date': trxDate,
      'amount': amount,
      'note': note,
    });
  }

  Future<Json> deleteTransaction({required String token, required dynamic id}) async =>
      _remove('transaksi', id, _uid(token));

  Future<Json> getTransactionsData({
    required String token,
    String? startDate,
    String? endDate,
  }) async {
    final uid = _uid(token), kinds = _kinds(uid);
    final list = _txs(uid, start: startDate, end: endDate);
    final before = startDate == null
        ? <Json>[]
        : _rows('transaksi', (t) =>
            t['user_id'] == uid &&
            (t['trx_date'] as String).substring(0, 10).compareTo(startDate) < 0);
    final opening = _rows('dompet', (w) => w['user_id'] == uid)
            .fold<double>(0, (s, w) => s + (w['initial_balance'] as num)) +
        _net(before, kinds);
    return {
      'transactions': list,
      'saldo_awal': opening,
      'saldo_akhir': opening + _net(list, kinds),
      'total_transaksi': list.length,
    };
  }

  Future<List<Json>> getTransactions({required String token}) async =>
      _txs(_uid(token));

  Future<List<Transaction>> getTransactionsList({required String token}) async =>
      (await getTransactions(token: token)).map(Transaction.fromJson).toList();

  Future<List<Json>> getTransactionsWithFilters({
    required String token,
    String? search,
    String? startDate,
    String? endDate,
    dynamic dompetId,
    dynamic categoryId,
    List<int>? categoryIds,
    List<int>? dompetIds,
  }) async {
    String? text(String? s) => (s == null || s.isEmpty) ? null : s;
    List<int>? ids(List<int>? list, dynamic one) => (list?.isNotEmpty ?? false)
        ? list
        : one == null ? null : [int.parse('$one')];
    return _txs(_uid(token),
        start: text(startDate),
        end: text(endDate),
        search: text(search),
        dompetIds: ids(dompetIds, dompetId),
        categoryIds: ids(categoryIds, categoryId));
  }

  Future<Json> getTransactionById({required String token, required dynamic id}) async {
    final uid = _uid(token), tx = _own('transaksi', id, uid);
    return _txs(uid).firstWhere((t) => t['id'] == tx['id']);
  }

  Future<Transaction> getTransactionByIdModel({
    required String token,
    required dynamic id,
  }) async => Transaction.fromJson(await getTransactionById(token: token, id: id));
}
