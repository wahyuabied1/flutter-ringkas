import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:Ringkas/data/services/api_service.dart';

void main() {
  final api = ApiService();
  late Directory dir;
  late String token;
  late int wallet, food, salary;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('ringkas_test_');
    Hive.init(dir.path);
    await openLocalDb();
    final r = await api.registerUser(name: 'Budi', email: 'Budi@Mail.com', password: 'x');
    token = r['access_token'];
    wallet = (await api.createWallet(
        userId: 1, name: 'Dompet', currencyCode: 'IDR', initialBalance: 100000, token: token))['id'];
    final cats = await api.getCategories(token: token);
    food = cats.firstWhere((c) => c.kind.name == 'expense').id;
    salary = cats.firstWhere((c) => c.kind.name == 'income').id;
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  Future<int> addTx(int category, double amount, String date, {String note = ''}) async =>
      (await api.createTransaction(
          userId: 1, type: '', amount: amount, note: note, trxDate: date,
          categoryId: category, walletId: wallet, token: token))['id'];

  test('register memberi 10 kategori bawaan dan login memakai email huruf kecil', () async {
    expect((await api.getCategories(token: token)).length, 10);
    final login = await api.loginUser(email: 'budi@mail.com', password: 'x');
    expect(login['access_token'], token);
    expect(login['user']['name'], 'Budi');
    expect((await api.getCurrentUser(token: token))['email'], 'budi@mail.com');
  });

  test('email ganda, password salah, dan token palsu ditolak', () async {
    expect(api.registerUser(name: 'X', email: 'budi@mail.com', password: 'y'),
        throwsA(predicate((e) => '$e'.contains('sudah terdaftar'))));
    expect(api.loginUser(email: 'budi@mail.com', password: 'salah'),
        throwsA(predicate((e) => '$e'.contains('password salah'))));
    expect(api.getWallets(token: 'abc'), throwsA(predicate((e) => '$e'.contains('Unauthenticated'))));
  });

  test('saldo dompet dihitung dari transaksi', () async {
    await addTx(food, 25000, '2026-09-20 12:00:00');
    final gaji = await addTx(salary, 500000, '2026-09-21 08:00:00');
    expect((await api.getWallets(token: token))['total_current_balance'], 575000);

    await api.updateTransaction(
        token: token, id: gaji, amount: 400000, note: 'b',
        trxDate: '2026-09-21 08:00:00', categoryId: salary, walletId: wallet);
    expect((await api.getWallets(token: token))['total_current_balance'], 475000);

    await api.deleteTransaction(token: token, id: gaji);
    expect((await api.getWallets(token: token))['total_current_balance'], 75000);
  });

  test('daftar transaksi: urutan, pelengkap nama, filter, dan saldo awal/akhir', () async {
    await addTx(food, 25000, '2026-09-20 12:00:00', note: 'Makan siang');
    await addTx(salary, 500000, '2026-09-21 08:00:00', note: 'Gaji');

    final all = await api.getTransactionsData(token: token);
    expect(all['total_transaksi'], 2);
    expect(all['transactions'][0]['note'], 'Gaji'); // terbaru dulu
    expect(all['transactions'][0]['kind'], 'income');
    expect(all['transactions'][0]['dompet_name'], 'Dompet');
    expect(all['saldo_awal'], 100000);
    expect(all['saldo_akhir'], 575000);

    final day = await api.getTransactionsData(
        token: token, startDate: '2026-09-21', endDate: '2026-09-21');
    expect(day['total_transaksi'], 1);
    expect(day['saldo_awal'], 75000); // saldo awal + transaksi sebelum tanggal itu
    expect(day['saldo_akhir'], 575000);

    Future<int> count({String? search, List<int>? cats}) async => (await api
            .getTransactionsWithFilters(token: token, search: search, categoryIds: cats))
        .length;
    expect(await count(search: 'makan'), 1);
    expect(await count(search: 'gaji'), 1); // cocok dengan nama kategori juga
    expect(await count(cats: [food]), 1);
    expect(await count(cats: []), 2); // daftar kosong = tanpa filter
    expect(await count(search: ''), 2);
    expect((await api.getTransactionById(token: token, id: 1))['kategori_name'], isNotNull);
  });

  test('data antar pengguna terpisah', () async {
    await addTx(food, 25000, '2026-09-20 12:00:00');
    final other = (await api.registerUser(name: 'Sari', email: 'sari@mail.com', password: 'y'))['access_token'];
    expect((await api.getWallets(token: other))['data'], isEmpty);
    expect((await api.getTransactionsData(token: other))['total_transaksi'], 0);
    expect(api.deleteWallet(id: wallet, token: other), throwsA(predicate((e) => '$e'.contains('tidak ditemukan'))));
    expect(api.createTransaction(
        userId: 2, type: '', amount: 1, note: '', trxDate: '2026-09-20 10:00:00',
        categoryId: food, walletId: wallet, token: other), throwsException);
  });

  test('menghapus dompet ikut menghapus transaksinya; kategori terpakai tidak bisa dihapus', () async {
    await addTx(food, 25000, '2026-09-20 12:00:00');
    expect(api.deleteCategory(categoryId: food, token: token),
        throwsA(predicate((e) => '$e'.contains('masih dipakai'))));
    await api.deleteWallet(id: wallet, token: token);
    expect((await api.getTransactionsData(token: token))['total_transaksi'], 0);
    await api.deleteCategory(categoryId: food, token: token);
    expect((await api.getCategories(token: token)).length, 9);
  });

  test('nominal harus positif', () async {
    expect(addTx(food, 0, '2026-09-20 12:00:00'), throwsA(predicate((e) => '$e'.contains('Nominal'))));
  });

  test('data tetap ada setelah database ditutup dan dibuka lagi', () async {
    await addTx(food, 25000, '2026-09-20 12:00:00');
    await Hive.close();
    Hive.init(dir.path);
    await openLocalDb();
    expect((await api.getTransactionsData(token: token))['total_transaksi'], 1);
  });
}
