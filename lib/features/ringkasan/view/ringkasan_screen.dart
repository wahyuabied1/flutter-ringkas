import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/services/api_service.dart';
import '../../../data/model/category_model.dart';
import 'ringkasan_transaction_list_screen.dart';
import 'ringkasan_category_details_screen.dart';

class RingkasanScreen extends StatefulWidget {
  const RingkasanScreen({super.key});

  @override
  State<RingkasanScreen> createState() => _RingkasanScreenState();
}

class _RingkasanScreenState extends State<RingkasanScreen> {
  String userName = "User";
  double balance = 0;
  DateTime currentDate = DateTime.now();
  bool isLoadingInitial = true;
  int _currentNavIndex = 2; // Ringkasan tab
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> allTransactions = []; // Store all transactions
  Map<int, Category> categoriesMap = {};
  Map<int, Map<String, dynamic>> walletsMap = {};

  // Saldo values from API
  double saldoAwal = 0;
  double saldoAkhir = 0;

  // Date filter type: 'daily', 'weekly', 'monthly'
  String dateFilterType = 'weekly';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadUserData();
  }

  @override
  void didUpdateWidget(covariant RingkasanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUserData();
  }

  @override
  void activate() {
    super.activate();
    // Reload data when returning to this screen
    _loadUserData(showLoading: false);
  }

  Future<void> _loadUserData({bool showLoading = true}) async {
    try {
      setState(() {
        userName = "User";
        balance = 0;
        transactions = [];
        categoriesMap = {};
        walletsMap = {};
        isLoadingInitial = showLoading;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final cachedName = prefs.getString('name') ?? '';

      if (token.isEmpty) {
        setState(() {
          userName = cachedName.isNotEmpty ? cachedName : "User";
          balance = prefs.getDouble('initialBalance') ?? 0;
          transactions = [];
          isLoadingInitial = false;
        });
        return;
      }

      // Get date range based on filter
      final dateRange = _getDateRange();
      final startDate = dateRange['start'] as DateTime;
      final endDate = dateRange['end'] as DateTime;
      final startDateStr =
          "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      final endDateStr =
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

      // Keempat permintaan tidak saling bergantung, jadi diminta sekaligus.
      // Menunggunya satu per satu membuat loading berlipat ganda.
      final results = await Future.wait<dynamic>([
        _apiService.getWallets(token: token),
        // Semua transaksi (tanpa filter tanggal) untuk allTransactions
        _apiService.getTransactionsData(token: token),
        // Transaksi dengan filter tanggal untuk saldo awal/akhir
        _apiService.getTransactionsData(
          token: token,
          startDate: startDateStr,
          endDate: endDateStr,
        ),
        _apiService.getCategories(token: token),
      ]);
      final walletsResponse = results[0] as Map<String, dynamic>;
      final allTxData = results[1] as Map<String, dynamic>;
      final txDataWithFilter = results[2] as Map<String, dynamic>;
      final categoriesList = results[3] as List<Category>;
      final walletsData = walletsResponse['data'] as List? ?? [];
      final totalCurrentBalance = walletsResponse['total_current_balance'];

      // Use total_current_balance from API, convert to double if needed
      double totalBalance = 0;
      if (totalCurrentBalance is String) {
        totalBalance = double.tryParse(totalCurrentBalance) ?? 0;
      } else if (totalCurrentBalance is num) {
        totalBalance = totalCurrentBalance.toDouble();
      }

      final txList = allTxData['transactions'] as List<Map<String, dynamic>>;

      // Extract saldo awal and saldo akhir from API with date filter
      double fetchedSaldoAwal = 0;
      double fetchedSaldoAkhir = 0;

      final saldoAwalValue = txDataWithFilter['saldo_awal'];
      if (saldoAwalValue is String) {
        fetchedSaldoAwal = double.tryParse(saldoAwalValue) ?? 0;
      } else if (saldoAwalValue is num) {
        fetchedSaldoAwal = saldoAwalValue.toDouble();
      }

      final saldoAkhirValue = txDataWithFilter['saldo_akhir'];
      if (saldoAkhirValue is String) {
        fetchedSaldoAkhir = double.tryParse(saldoAkhirValue) ?? 0;
      } else if (saldoAkhirValue is num) {
        fetchedSaldoAkhir = saldoAkhirValue.toDouble();
      }

      // Mapping kategori
      final categoryMap = <int, Category>{};
      for (var category in categoriesList) {
        categoryMap[category.id] = category;
      }

      // Build wallet map from walletsData
      final walletMap = <int, Map<String, dynamic>>{};
      for (var wallet in walletsData) {
        final id = wallet is Map
            ? (wallet['id'] is String
                  ? int.tryParse(wallet['id'] as String)
                  : wallet['id'] as int?)
            : null;
        if (id != null) {
          walletMap[id] = wallet is Map ? wallet.cast<String, dynamic>() : {};
        }
      }

      // Assign allTransactions directly first
      allTransactions = txList;

      // Then filter transactions based on current date range
      final filteredTx = _getFilteredTransactions();

      setState(() {
        userName = cachedName.isNotEmpty ? cachedName : "User";
        balance = totalBalance;
        transactions = filteredTx; // Use pre-filtered transactions
        categoriesMap = categoryMap;
        walletsMap = walletMap;
        saldoAwal = fetchedSaldoAwal;
        saldoAkhir = fetchedSaldoAkhir;
        isLoadingInitial = false;
      });

      await prefs.setDouble('initialBalance', totalBalance);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userName = prefs.getString('name') ?? "User";
        balance = prefs.getDouble('initialBalance') ?? 0;
        transactions = [];
        categoriesMap = {};
        walletsMap = {};
        isLoadingInitial = false;
      });
    }
  }

  Future<void> _updateSaldoValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) return;

      final dateRange = _getDateRange();
      final startDate = dateRange['start'] as DateTime;
      final endDate = dateRange['end'] as DateTime;
      final startDateStr =
          "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      final endDateStr =
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

      final txData = await _apiService.getTransactionsData(
        token: token,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      double fetchedSaldoAwal = 0;
      double fetchedSaldoAkhir = 0;

      final saldoAwalValue = txData['saldo_awal'];
      if (saldoAwalValue is String) {
        fetchedSaldoAwal = double.tryParse(saldoAwalValue) ?? 0;
      } else if (saldoAwalValue is num) {
        fetchedSaldoAwal = saldoAwalValue.toDouble();
      }

      final saldoAkhirValue = txData['saldo_akhir'];
      if (saldoAkhirValue is String) {
        fetchedSaldoAkhir = double.tryParse(saldoAkhirValue) ?? 0;
      } else if (saldoAkhirValue is num) {
        fetchedSaldoAkhir = saldoAkhirValue.toDouble();
      }

      setState(() {
        saldoAwal = fetchedSaldoAwal;
        saldoAkhir = fetchedSaldoAkhir;
      });
    } catch (e) {
      // Silent fail - keep existing saldo values
    }
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    final dateRange = _getDateRange();
    final startDate = dateRange['start'] as DateTime;
    final endDate = dateRange['end'] as DateTime;

    final filtered = <Map<String, dynamic>>[];
    for (var transaction in allTransactions) {
      final dateStr = transaction['trx_date'] as String?;
      if (dateStr == null) continue;

      try {
        final txDate = DateTime.parse(dateStr);
        final txDateOnly = DateTime(txDate.year, txDate.month, txDate.day);
        final startDateOnly = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

        if ((txDateOnly.isAfter(startDateOnly) ||
                txDateOnly.isAtSameMomentAs(startDateOnly)) &&
            (txDateOnly.isBefore(endDateOnly) ||
                txDateOnly.isAtSameMomentAs(endDateOnly))) {
          filtered.add(transaction);
        }
      } catch (e) {
        // Ignore parse errors
      }
    }
    return filtered;
  }

  Map<String, DateTime> _getDateRange() {
    if (dateFilterType == 'daily') {
      return {'start': currentDate, 'end': currentDate};
    } else if (dateFilterType == 'weekly') {
      final startOfWeek = currentDate.subtract(
        Duration(days: currentDate.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return {'start': startOfWeek, 'end': endOfWeek};
    } else {
      final startOfMonth = DateTime(currentDate.year, currentDate.month, 1);
      final endOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0);
      return {'start': startOfMonth, 'end': endOfMonth};
    }
  }

  Map<String, dynamic> _calculateSummary() {
    double income = 0;
    double expense = 0;

    // Use transactions yang sudah difilter berdasarkan date range
    for (var transaction in transactions) {
      final amount = (transaction['amount'] is String)
          ? double.tryParse(transaction['amount'] as String) ?? 0
          : (transaction['amount'] as num?)?.toDouble() ?? 0;

      final categoryId = transaction['category_id'] is String
          ? int.tryParse(transaction['category_id'] as String)
          : transaction['category_id'] as int?;

      final category = categoryId != null ? categoriesMap[categoryId] : null;
      final categoryKind = category?.kind == CategoryKind.income
          ? 'income'
          : 'expense';

      if (categoryKind == 'income') {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return {'income': income, 'expense': expense, 'total': income - expense};
  }

  // Get expense breakdown by category
  Map<String, double> _getExpenseByCategory() {
    final expenseMap = <String, double>{};

    // Use transactions yang sudah difilter berdasarkan date range
    for (var transaction in transactions) {
      final amount = (transaction['amount'] is String)
          ? double.tryParse(transaction['amount'] as String) ?? 0
          : (transaction['amount'] as num?)?.toDouble() ?? 0;

      final categoryId = transaction['category_id'] is String
          ? int.tryParse(transaction['category_id'] as String)
          : transaction['category_id'] as int?;

      final category = categoryId != null ? categoriesMap[categoryId] : null;
      final categoryKind = category?.kind == CategoryKind.income
          ? 'income'
          : 'expense';
      final categoryName = category?.name ?? 'Other';

      if (categoryKind == 'expense' && amount < 0) {
        expenseMap[categoryName] =
            (expenseMap[categoryName] ?? 0) + amount.abs();
      }
    }

    return expenseMap;
  }

  void _prevDate() {
    setState(() {
      if (dateFilterType == 'daily') {
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (dateFilterType == 'weekly') {
        currentDate = currentDate.subtract(const Duration(days: 7));
      } else if (dateFilterType == 'monthly') {
        currentDate = DateTime(currentDate.year, currentDate.month - 1);
      }
      // Filter transactions based on new date range
      transactions = _getFilteredTransactions();
    });
    // Update saldo awal/akhir di background
    _updateSaldoValues();
  }

  void _nextDate() {
    setState(() {
      if (dateFilterType == 'daily') {
        currentDate = currentDate.add(const Duration(days: 1));
      } else if (dateFilterType == 'weekly') {
        currentDate = currentDate.add(const Duration(days: 7));
      } else if (dateFilterType == 'monthly') {
        currentDate = DateTime(currentDate.year, currentDate.month + 1);
      }
      // Filter transactions based on new date range
      transactions = _getFilteredTransactions();
    });
    // Update saldo awal/akhir di background
    _updateSaldoValues();
  }

  void _showDateFilterBottomSheet(BuildContext context) {
    String tempDateFilterType = dateFilterType;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter Tanggal",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildFilterOption(
                        context,
                        setModalState,
                        'daily',
                        'Harian',
                        'Navigasi per hari',
                        Icons.today,
                        tempDateFilterType,
                        (value) => tempDateFilterType = value,
                      ),
                      const SizedBox(height: 12),
                      _buildFilterOption(
                        context,
                        setModalState,
                        'weekly',
                        'Mingguan',
                        'Navigasi per minggu',
                        Icons.calendar_view_week,
                        tempDateFilterType,
                        (value) => tempDateFilterType = value,
                      ),
                      const SizedBox(height: 12),
                      _buildFilterOption(
                        context,
                        setModalState,
                        'monthly',
                        'Bulanan',
                        'Navigasi per bulan',
                        Icons.calendar_today,
                        tempDateFilterType,
                        (value) => tempDateFilterType = value,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "Batal",
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              dateFilterType = tempDateFilterType;
                              // Filter transactions based on new filter type
                              transactions = _getFilteredTransactions();
                            });
                            Navigator.pop(context);
                            // Update saldo awal/akhir di background
                            _updateSaldoValues();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D9E85),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Terapkan",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    StateSetter setModalState,
    String value,
    String title,
    String subtitle,
    IconData icon,
    String currentValue,
    Function(String) onChanged,
  ) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          onChanged(value);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF5D9E85)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5D9E85)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Color(0xFF5D9E85))
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (_currentNavIndex == index) return;

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/transaction');
        break;
      case 2:
        setState(() => _currentNavIndex = 2);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate;
    if (dateFilterType == 'daily') {
      formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(currentDate);
    } else if (dateFilterType == 'weekly') {
      final startOfWeek = currentDate.subtract(
        Duration(days: currentDate.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final startFormat = DateFormat('dd MMM', 'id_ID').format(startOfWeek);
      final endFormat = DateFormat('dd MMM yyyy', 'id_ID').format(endOfWeek);
      formattedDate = '$startFormat - $endFormat';
    } else {
      formattedDate = DateFormat('MMMM yyyy', 'id_ID').format(currentDate);
    }

    final summary = _calculateSummary();
    final income = summary['income'] as double? ?? 0.0;
    final expense = summary['expense'] as double? ?? 0.0;
    final expenseByCategory = _getExpenseByCategory();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.fromSize(size: const Size.fromHeight(40)),
                // Nama + Saldo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoadingInitial ? "Loading..." : userName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLoadingInitial
                              ? "Loading..."
                              : "Rp ${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5D9E85),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed('/search');
                          },
                          child: const Icon(
                            Icons.search,
                            size: 24,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            _showDateFilterBottomSheet(context);
                          },
                          child: const Icon(
                            Icons.calendar_month,
                            size: 24,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tanggal + tombol kiri kanan
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _prevDate,
                      icon: const Icon(Icons.arrow_left),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      onPressed: _nextDate,
                      icon: const Icon(Icons.arrow_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CONTENT AREA
          Expanded(
            child: isLoadingInitial
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF5D9E85),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Memuat ringkasan...",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SALDO Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Saldo",
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Saldo awal",
                                          style: TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Rp ${saldoAwal.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Saldo akhir",
                                          style: TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Rp ${saldoAkhir.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // RINGKASAN Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Ringkasan",
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Pendapatan
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Pendapatan",
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "Rp ${income.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
                                    style: const TextStyle(
                                      color: Color(0xFF5D9E85),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Pengeluaran
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Pengeluaran",
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "-Rp ${expense.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
                                    style: const TextStyle(
                                      color: Color(0xFFF75270),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Divider
                              // Total (Income + Expense)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total",
                                    style: TextStyle(
                                      color: Color(0xFF1F2937),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "Rp ${(income + expense).toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
                                    style: const TextStyle(
                                      color: Color(0xFF1F2937),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Divider
                              Container(
                                height: 1,
                                color: const Color(0xFFE5E7EB),
                              ),
                              // Lihat semua button
                              GestureDetector(
                                onTap: () {
                                  final dateRange = _getDateRange();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RingkasanTransactionListScreen(
                                            startDate: dateRange['start']!,
                                            endDate: dateRange['end']!,
                                            dateFilterType: dateFilterType,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Lihat semua",
                                        style: TextStyle(
                                          color: Color(0xFF5D9E85),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Color(0xFF5D9E85),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // STRUKTUR PENGELUARAN Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Struktur Pengeluaran",
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Chart
                              if (expenseByCategory.isNotEmpty)
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        height: 200,
                                        width: 200,
                                        child: PieChart(
                                          PieChartData(
                                            sections: _buildPieChartSections(
                                              expenseByCategory,
                                            ),
                                            centerSpaceRadius: 60,
                                            sectionsSpace: 2,
                                          ),
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            "Total",
                                            style: TextStyle(
                                              color: Color(0xFF6B7280),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Rp ${expense.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
                                            style: const TextStyle(
                                              color: Color(0xFF1F2937),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  height: 200,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Tidak ada data pengeluaran",
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              // Legend
                              ..._buildLegend(expenseByCategory),
                              const SizedBox(height: 16),
                              // Divider
                              const Divider(
                                color: Color(0xFFE5E7EB),
                                height: 1,
                              ),
                              const SizedBox(height: 16),
                              // Lihat semua button
                              GestureDetector(
                                onTap: () {
                                  final dateRange = _getDateRange();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RingkasanCategoryDetailsScreen(
                                            startDate: dateRange['start']!,
                                            endDate: dateRange['end']!,
                                            dateFilterType: dateFilterType,
                                          ),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Lihat semua",
                                      style: TextStyle(
                                        color: Color(0xFF5D9E85),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Color(0xFF5D9E85),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),

      // ✅ FLOATING BUTTON (+) BUNDER IJO
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Color(0xFF5D9E85),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 32),
          onPressed: () async {
            final result = await Navigator.of(
              context,
            ).pushNamed('/add-transaction');
            if (result == true) {
              _loadUserData();
            }
          },
        ),
      ),

      // ✅ NAVBAR BAWAH
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(child: _buildNavItem(0, Icons.home, "Beranda")),
            ),
            Expanded(
              child: Center(
                child: _buildNavItem(1, Icons.receipt_long, "Transaksi"),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox.shrink(), // FAB space
              ),
            ),
            Expanded(
              child: Center(
                child: _buildNavItem(2, Icons.pie_chart, "Ringkasan"),
              ),
            ),
            Expanded(
              child: Center(child: _buildNavItem(3, Icons.person, "Profil")),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF5D9E85) : const Color(0xFF9CA3AF),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? const Color(0xFF5D9E85)
                  : const Color(0xFF9CA3AF),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return const Color(0xFF5D9E85); // Default color
    }

    try {
      String hex = hexColor.replaceFirst('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse('0x$hex'));
    } catch (e) {
      return const Color(0xFF5D9E85);
    }
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, double> expenseMap,
  ) {
    final totalExpense = expenseMap.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return expenseMap.entries.map((entry) {
      final categoryName = entry.key;
      final percentage = (entry.value / totalExpense) * 100;

      // Cari kategori berdasarkan nama untuk mendapatkan warna
      Color categoryColor = const Color(0xFF5D9E85);
      for (var category in categoriesMap.values) {
        if (category.name.toLowerCase() == categoryName.toLowerCase()) {
          categoryColor = _getColorFromHex(category.colorHex);
          break;
        }
      }

      return PieChartSectionData(
        color: categoryColor,
        value: percentage,
        radius: 40,
        titlePositionPercentageOffset: 0.6,
        showTitle: false,
      );
    }).toList();
  }

  List<Widget> _buildLegend(Map<String, double> expenseMap) {
    final totalExpense = expenseMap.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return expenseMap.entries.map((entry) {
      final categoryName = entry.key;
      final percentage = (entry.value / totalExpense) * 100;

      // Cari kategori berdasarkan nama untuk mendapatkan warna
      Color categoryColor = const Color(0xFF5D9E85);
      for (var category in categoriesMap.values) {
        if (category.name.toLowerCase() == categoryName.toLowerCase()) {
          categoryColor = _getColorFromHex(category.colorHex);
          break;
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ),
            Text(
              "(${percentage.toStringAsFixed(1)}%)",
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
