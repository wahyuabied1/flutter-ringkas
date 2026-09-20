import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/wallet_model.dart';
import '../model/category_model.dart';
import '../model/transaction_model.dart';

class ApiService {
  static const String baseUrl =
      'https://ringkasapi.my.id/api'; // Ganti dengan URL API Anda

  // STEP 1: REGISTER USER (Simpan ke tabel user)
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Gagal mendaftar');
    }
  }

  // STEP 2: CREATE WALLET (Simpan ke tabel dompet)
  Future<Map<String, dynamic>> createWallet({
    required dynamic userId,
    required String name,
    required String currencyCode,
    required double initialBalance,
    required String token,
  }) async {
    final requestBody = {
      'user_id': userId is String ? int.tryParse(userId) : userId,
      'name': name,
      'currency': currencyCode,
      'initial_balance': initialBalance,
      'is_active': true,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/dompet'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Gagal membuat dompet');
    }
  }

  // LOGIN USER
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Login gagal');
    }
  }

  // GET CURRENT USER (Fetch user profile menggunakan token)
  Future<Map<String, dynamic>> getCurrentUser({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Handle jika response adalah List (array)
      if (data is List) {
        if (data.isNotEmpty && data[0] is Map) {
          return data[0] as Map<String, dynamic>;
        } else {
          throw Exception('Response List kosong atau format tidak valid');
        }
      }

      // Handle jika response adalah Map
      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception('Response format tidak valid: ${data.runtimeType}');
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data user');
    }
  }

  // GET WALLETS (Fetch daftar dompet user)
  Future<Map<String, dynamic>> getWallets({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dompet'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Handle jika response adalah Map dengan struktur { status, massage, data }
      if (data is Map && data['data'] is Map) {
        final dataMap = data['data'] as Map;

        // Get wallets from dompets field
        List<dynamic> walletList = [];
        if (dataMap['dompets'] is List) {
          walletList = dataMap['dompets'] as List;
        } else if (dataMap['data'] is List) {
          walletList = dataMap['data'] as List;
        } else if (dataMap['wallets'] is List) {
          walletList = dataMap['wallets'] as List;
        }

        return {
          'data': List<Map<String, dynamic>>.from(
            walletList
                .where((wallet) => wallet is Map)
                .map(
                  (wallet) => wallet is Map<String, dynamic>
                      ? wallet
                      : (wallet as Map).cast<String, dynamic>(),
                ),
          ),
          'total_current_balance': _parseBalance(
            dataMap['total_current_balance'],
          ),
        };
      }

      // Handle jika response adalah List (backward compatibility)
      if (data is List) {
        return {
          'data': List<Map<String, dynamic>>.from(
            data
                .where((wallet) => wallet is Map)
                .map(
                  (wallet) => wallet is Map<String, dynamic>
                      ? wallet
                      : (wallet as Map).cast<String, dynamic>(),
                ),
          ),
          'total_current_balance': 0.0,
        };
      }

      // Handle jika response memiliki data field (simple array)
      if (data is Map && data['data'] is List) {
        return {
          'data': List<Map<String, dynamic>>.from(
            (data['data'] as List)
                .where((wallet) => wallet is Map)
                .map(
                  (wallet) => wallet is Map<String, dynamic>
                      ? wallet
                      : (wallet as Map).cast<String, dynamic>(),
                ),
          ),
          'total_current_balance': _parseBalance(data['total_current_balance']),
        };
      }

      // If none of the above, return empty data
      return {'data': [], 'total_current_balance': 0.0};
    } else {
      final errorMessage = data is Map
          ? (data['message'] ??
                data['massage'] ??
                'Gagal mengambil daftar dompet')
          : 'Gagal mengambil daftar dompet';
      throw Exception(errorMessage);
    }
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
    final requestBody = {
      'name': name,
      'currency': currencyCode,
      'initial_balance': initialBalance,
      'is_active': true,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/dompet/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Gagal memperbarui dompet');
    }
  }

  // DELETE WALLET (Hapus dompet user)
  Future<Map<String, dynamic>> deleteWallet({
    required dynamic id,
    required String token,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/dompet/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Gagal menghapus dompet');
    }
  }

  // GET CATEGORIES (Fetch daftar kategori)
  Future<List<Category>> getCategories({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/kategori'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Handle jika response adalah List
      if (data is List) {
        return List<Category>.from(
          data.map(
            (kategori) => Category.fromJson(kategori as Map<String, dynamic>),
          ),
        );
      }

      // Handle jika response memiliki data field
      if (data is Map && data['data'] is List) {
        return List<Category>.from(
          (data['data'] as List).map(
            (kategori) => Category.fromJson(kategori as Map<String, dynamic>),
          ),
        );
      }

      throw Exception('Format response kategori tidak valid');
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil daftar kategori');
    }
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
    final requestBody = {
      'user_id': userId is String ? int.tryParse(userId) : userId,
      'name': name,
      'kind': kind,
      'color': colorHex,
      'icon': icon,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/kategori'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Gagal membuat kategori');
    }
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
    final requestBody = {
      'name': name,
      'kind': kind,
      'color': colorHex,
      'icon': icon,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/kategori/$categoryId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Gagal mengupdate kategori');
    }
  }

  // DELETE CATEGORY (Hapus kategori)
  Future<void> deleteCategory({
    required dynamic categoryId,
    required String token,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/kategori/$categoryId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal menghapus kategori');
    }
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

    final requestBody = {
      'category_id': parsedCategoryId,
      'dompet_id': parsedWalletId,
      'trx_date': trxDate,
      'amount': amount,
      'note': note,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/transaksi'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Gagal membuat transaksi');
    }
  }

  // GET TRANSACTIONS (Fetch daftar transaksi user)
  Future<Map<String, dynamic>> getTransactionsData({
    required String token,
    String? startDate,
    String? endDate,
  }) async {
    final uri = Uri.parse('$baseUrl/transaksi');
    final uriWithParams = startDate != null && endDate != null
        ? uri.replace(
            queryParameters: {'start_date': startDate, 'end_date': endDate},
          )
        : uri;

    final response = await http.get(
      uriWithParams,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Handle jika response adalah Map dengan struktur { status, massage, data }
      if (data is Map && data['data'] is Map) {
        final dataMap = data['data'] as Map;
        List<dynamic> txList = [];

        if (dataMap['transaksi'] is List) {
          txList = dataMap['transaksi'] as List;
        } else if (dataMap['transactions'] is List) {
          txList = dataMap['transactions'] as List;
        }

        return {
          'transactions': List<Map<String, dynamic>>.from(
            txList
                .where((tx) => tx is Map)
                .map(
                  (tx) => tx is Map<String, dynamic>
                      ? tx
                      : (tx as Map).cast<String, dynamic>(),
                ),
          ),
          'saldo_awal': dataMap['saldo_awal'] ?? 0,
          'saldo_akhir': dataMap['saldo_akhir'] ?? 0,
          'total_transaksi': dataMap['total_transaksi'] ?? 0,
        };
      }

      // Handle jika response adalah List
      if (data is List) {
        return {
          'transactions': List<Map<String, dynamic>>.from(
            data
                .where((tx) => tx is Map)
                .map(
                  (tx) => tx is Map<String, dynamic>
                      ? tx
                      : (tx as Map).cast<String, dynamic>(),
                ),
          ),
          'saldo_awal': 0,
          'saldo_akhir': 0,
          'total_transaksi': 0,
        };
      }

      // Return empty structure
      return {
        'transactions': [],
        'saldo_awal': 0,
        'saldo_akhir': 0,
        'total_transaksi': 0,
      };
    } else {
      throw Exception(
        data is Map
            ? (data['message'] ?? 'Gagal mengambil daftar transaksi')
            : 'Gagal mengambil daftar transaksi',
      );
    }
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

    final uri = Uri.parse(
      '$baseUrl/transaksi',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Handle jika response adalah List
      if (data is List) {
        return List<Map<String, dynamic>>.from(
          data.map((transaction) => transaction as Map<String, dynamic>),
        );
      }

      // Handle jika response adalah Map dengan struktur { data: { transaksi: [...] } }
      if (data is Map && data['data'] is Map) {
        final dataMap = data['data'] as Map;
        List<dynamic> txList = [];

        if (dataMap['transaksi'] is List) {
          txList = dataMap['transaksi'] as List;
        } else if (dataMap['transactions'] is List) {
          txList = dataMap['transactions'] as List;
        }

        return List<Map<String, dynamic>>.from(
          txList
              .where((tx) => tx is Map)
              .map(
                (tx) => tx is Map<String, dynamic>
                    ? tx
                    : (tx as Map).cast<String, dynamic>(),
              ),
        );
      }

      // Handle jika response memiliki data field (direct list)
      if (data is Map && data['data'] is List) {
        return List<Map<String, dynamic>>.from(
          (data['data'] as List).map(
            (transaction) => transaction as Map<String, dynamic>,
          ),
        );
      }

      throw Exception('Format response transaksi tidak valid');
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil daftar transaksi');
    }
  }

  Future<Map<String, dynamic>> getTransactionById({
    required String token,
    required dynamic id,
  }) async {
    final uri = Uri.parse('$baseUrl/transaksi/$id');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data is Map<String, dynamic>) {
        // Extract data dari field 'data' jika ada, atau return langsung
        if (data['data'] is Map<String, dynamic>) {
          return data['data'] as Map<String, dynamic>;
        }
        return data;
      } else {
        throw Exception('Format response transaksi tidak valid');
      }
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data transaksi');
    }
  }

  // GET TRANSACTION BY ID (Return Transaction model)
  Future<Transaction> getTransactionByIdModel({
    required String token,
    required dynamic id,
  }) async {
    final data = await getTransactionById(token: token, id: id);
    return Transaction.fromJson(data);
  } // DELETE TRANSACTION (Hapus transaksi)

  Future<Map<String, dynamic>> deleteTransaction({
    required String token,
    required dynamic id,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transaksi/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Gagal menghapus transaksi');
    }
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
    final requestBody = {
      'amount': amount,
      'note': note,
      'trx_date': trxDate,
      'category_id': categoryId,
      'dompet_id': walletId,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/transaksi/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Gagal mengupdate transaksi');
    }
  }
}
