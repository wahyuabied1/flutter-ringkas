import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/wallet_model.dart';
import '../model/category_model.dart';
import '../model/transaction_model.dart';

class ApiService {
  // URL Web App Google Apps Script (berakhiran /exec).
  // Lihat apps_script/Code.gs untuk cara deploy.
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycbyIXxUZI1Qp10JZwzcsO7sz30A4MBYBVE6u1A2LoR_6bXnt0stqbbh0jbEte8lab9lQ/exec';

  // Apps Script hanya menerima POST/GET, tidak bisa membaca header Authorization,
  // dan selalu membalas HTTP 200. Karena itu semua request dikirim sebagai POST
  // dengan method, path, query, dan token di dalam body JSON, dan hasilnya dicek
  // lewat field `status` pada respons.
  Future<Map<String, dynamic>> _call(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    String? token,
  }) async {
    var response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'text/plain; charset=utf-8'},
      body: jsonEncode({
        'method': method,
        'path': path,
        'query': query ?? {},
        'body': body ?? {},
        'token': token,
      }),
    );

    // Apps Script menjawab POST dengan redirect; hasilnya diambil lewat GET.
    for (var i = 0; i < 3; i++) {
      final location = response.headers['location'];
      if (response.statusCode < 300 ||
          response.statusCode >= 400 ||
          location == null) {
        break;
      }
      response = await http.get(Uri.parse(location));
    }

    final dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Respons server tidak valid. Pastikan URL Apps Script benar dan '
        'akses deployment diatur ke "Siapa saja".',
      );
    }

    if (data is! Map<String, dynamic> || data['status'] != 'success') {
      throw Exception(
        data is Map ? (data['message'] ?? 'Terjadi kesalahan') : 'Terjadi kesalahan',
      );
    }
    return data;
  }

  // STEP 1: REGISTER USER (Simpan ke sheet users)
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    return _call(
      'POST',
      '/register',
      body: {'name': name, 'email': email, 'password': password},
    );
  }

  // STEP 2: CREATE WALLET (Simpan ke sheet dompet)
  Future<Map<String, dynamic>> createWallet({
    required dynamic userId,
    required String name,
    required String currencyCode,
    required double initialBalance,
    required String token,
  }) async {
    return _call(
      'POST',
      '/dompet',
      token: token,
      body: {
        'user_id': userId is String ? int.tryParse(userId) : userId,
        'name': name,
        'currency': currencyCode,
        'initial_balance': initialBalance,
        'is_active': true,
      },
    );
  }

  // LOGIN USER
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    return _call(
      'POST',
      '/login',
      body: {'email': email, 'password': password},
    );
  }

  // GET CURRENT USER (Fetch user profile menggunakan token)
  Future<Map<String, dynamic>> getCurrentUser({required String token}) async {
    return _call('GET', '/users', token: token);
  }

  // GET WALLETS (Fetch daftar dompet user)
  Future<Map<String, dynamic>> getWallets({required String token}) async {
    final data = await _call('GET', '/dompet', token: token);
    final dataMap = data['data'];

    if (dataMap is Map && dataMap['dompets'] is List) {
      return {
        'data': List<Map<String, dynamic>>.from(
          (dataMap['dompets'] as List)
              .where((wallet) => wallet is Map)
              .map((wallet) => (wallet as Map).cast<String, dynamic>()),
        ),
        'total_current_balance': _parseBalance(dataMap['total_current_balance']),
      };
    }

    return {'data': [], 'total_current_balance': 0.0};
  }

  // GET WALLETS (Return List<Wallet> for model-based usage)
  Future<List<Wallet>> getWalletsList({required String token}) async {
    final walletsData = await getWallets(token: token);
    final data = (walletsData['data'] ?? []) as List;
    return List<Wallet>.from(
      data.map((wallet) => Wallet.fromJson(wallet as Map<String, dynamic>)),
    );
  }

  double _parseBalance(dynamic balance) {
    if (balance is String) {
      return double.tryParse(balance) ?? 0.0;
    } else if (balance is num) {
      return balance.toDouble();
    }
    return 0.0;
  }

  // UPDATE WALLET (Update dompet user)
  Future<Map<String, dynamic>> updateWallet({
    required dynamic id,
    required String name,
    required String currencyCode,
    required double initialBalance,
    required String token,
  }) async {
    return _call(
      'PUT',
      '/dompet/$id',
      token: token,
      body: {
        'name': name,
        'currency': currencyCode,
        'initial_balance': initialBalance,
        'is_active': true,
      },
    );
  }

  // DELETE WALLET (Hapus dompet user)
  Future<Map<String, dynamic>> deleteWallet({
    required dynamic id,
    required String token,
  }) async {
    return _call('DELETE', '/dompet/$id', token: token);
  }

  // GET CATEGORIES (Fetch daftar kategori)
  Future<List<Category>> getCategories({required String token}) async {
    final data = await _call('GET', '/kategori', token: token);

    if (data['data'] is List) {
      return List<Category>.from(
        (data['data'] as List).map(
          (kategori) => Category.fromJson(kategori as Map<String, dynamic>),
        ),
      );
    }

    throw Exception('Format response kategori tidak valid');
  }

  // CREATE CATEGORY (Buat kategori baru)
  Future<Map<String, dynamic>> createCategory({
    required dynamic userId,
    required String name,
    required String kind,
    required String colorHex,
    required String icon,
    required String token,
  }) async {
    return _call(
      'POST',
      '/kategori',
      token: token,
      body: {
        'user_id': userId is String ? int.tryParse(userId) : userId,
        'name': name,
        'kind': kind,
        'color': colorHex,
        'icon': icon,
      },
    );
  }

  // UPDATE CATEGORY (Update kategori yang sudah ada)
  Future<Map<String, dynamic>> updateCategory({
    required dynamic categoryId,
    required String name,
    required String kind,
    required String colorHex,
    required String icon,
    required String token,
  }) async {
    return _call(
      'PUT',
      '/kategori/$categoryId',
      token: token,
      body: {'name': name, 'kind': kind, 'color': colorHex, 'icon': icon},
    );
  }

  // DELETE CATEGORY (Hapus kategori)
  Future<void> deleteCategory({
    required dynamic categoryId,
    required String token,
  }) async {
    await _call('DELETE', '/kategori/$categoryId', token: token);
  }

  // CREATE TRANSACTION (Buat transaksi baru)
  Future<Map<String, dynamic>> createTransaction({
    required dynamic userId,
    required String type,
    required double amount,
    required String note,
    required String trxDate,
    required dynamic categoryId,
    required dynamic walletId,
    required String token,
  }) async {
    // Convert IDs to integers
    final parsedCategoryId = categoryId is String
        ? int.tryParse(categoryId)
        : categoryId;
    final parsedWalletId = walletId is String
        ? int.tryParse(walletId)
        : walletId;

    if (parsedCategoryId == null) {
      throw Exception('Category ID tidak valid');
    }
    if (parsedWalletId == null) {
      throw Exception('Wallet ID tidak valid');
    }

    return _call(
      'POST',
      '/transaksi',
      token: token,
      body: {
        'category_id': parsedCategoryId,
        'dompet_id': parsedWalletId,
        'trx_date': trxDate,
        'amount': amount,
        'note': note,
      },
    );
  }

  // GET TRANSACTIONS (Fetch daftar transaksi user)
  Future<Map<String, dynamic>> getTransactionsData({
    required String token,
    String? startDate,
    String? endDate,
  }) async {
    final data = await _call(
      'GET',
      '/transaksi',
      token: token,
      query: startDate != null && endDate != null
          ? {'start_date': startDate, 'end_date': endDate}
          : null,
    );

    final dataMap = data['data'];
    if (dataMap is Map) {
      final txList = dataMap['transaksi'] is List
          ? dataMap['transaksi'] as List
          : <dynamic>[];

      return {
        'transactions': List<Map<String, dynamic>>.from(
          txList
              .where((tx) => tx is Map)
              .map((tx) => (tx as Map).cast<String, dynamic>()),
        ),
        'saldo_awal': dataMap['saldo_awal'] ?? 0,
        'saldo_akhir': dataMap['saldo_akhir'] ?? 0,
        'total_transaksi': dataMap['total_transaksi'] ?? 0,
      };
    }

    return {
      'transactions': [],
      'saldo_awal': 0,
      'saldo_akhir': 0,
      'total_transaksi': 0,
    };
  }

  // GET TRANSACTIONS (Fetch daftar transaksi) - backward compatibility wrapper
  Future<List<Map<String, dynamic>>> getTransactions({
    required String token,
  }) async {
    final data = await getTransactionsData(token: token);
    return data['transactions'] as List<Map<String, dynamic>>;
  }

  // GET TRANSACTIONS (Return List<Transaction> for model-based usage)
  Future<List<Transaction>> getTransactionsList({required String token}) async {
    final txList = await getTransactions(token: token);
    return List<Transaction>.from(txList.map((tx) => Transaction.fromJson(tx)));
  }

  // GET TRANSACTIONS WITH FILTERS (Fetch daftar transaksi dengan filter)
  Future<List<Map<String, dynamic>>> getTransactionsWithFilters({
    required String token,
    String? search,
    String? startDate,
    String? endDate,
    dynamic dompetId,
    dynamic categoryId,
    List<int>? categoryIds,
    List<int>? dompetIds,
  }) async {
    final queryParams = <String, String>{};

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }

    // Support for multiple dompet IDs
    if (dompetIds != null && dompetIds.isNotEmpty) {
      queryParams['dompet_id'] = dompetIds.join(',');
    } else if (dompetId != null) {
      queryParams['dompet_id'] = dompetId.toString();
    }

    // Support for multiple category IDs
    if (categoryIds != null && categoryIds.isNotEmpty) {
      queryParams['category_id'] = categoryIds.join(',');
    } else if (categoryId != null) {
      queryParams['category_id'] = categoryId.toString();
    }

    final data = await _call(
      'GET',
      '/transaksi',
      token: token,
      query: queryParams,
    );

    final dataMap = data['data'];
    if (dataMap is Map && dataMap['transaksi'] is List) {
      return List<Map<String, dynamic>>.from(
        (dataMap['transaksi'] as List)
            .where((tx) => tx is Map)
            .map((tx) => (tx as Map).cast<String, dynamic>()),
      );
    }

    throw Exception('Format response transaksi tidak valid');
  }

  Future<Map<String, dynamic>> getTransactionById({
    required String token,
    required dynamic id,
  }) async {
    final data = await _call('GET', '/transaksi/$id', token: token);
    if (data['data'] is Map) {
      return (data['data'] as Map).cast<String, dynamic>();
    }
    throw Exception('Format response transaksi tidak valid');
  }

  // GET TRANSACTION BY ID (Return Transaction model)
  Future<Transaction> getTransactionByIdModel({
    required String token,
    required dynamic id,
  }) async {
    final data = await getTransactionById(token: token, id: id);
    return Transaction.fromJson(data);
  }

  // DELETE TRANSACTION (Hapus transaksi)
  Future<Map<String, dynamic>> deleteTransaction({
    required String token,
    required dynamic id,
  }) async {
    return _call('DELETE', '/transaksi/$id', token: token);
  }

  // UPDATE TRANSACTION (Update transaksi)
  Future<Map<String, dynamic>> updateTransaction({
    required String token,
    required dynamic id,
    required double amount,
    required String note,
    required String trxDate,
    required dynamic categoryId,
    required dynamic walletId,
  }) async {
    return _call(
      'PUT',
      '/transaksi/$id',
      token: token,
      body: {
        'amount': amount,
        'note': note,
        'trx_date': trxDate,
        'category_id': categoryId,
        'dompet_id': walletId,
      },
    );
  }
}
