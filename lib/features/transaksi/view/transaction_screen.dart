import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../data/services/api_service.dart';
import '../../../data/model/category_model.dart';
import 'detail_transaction_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String userName = "User";
  double balance = 0;
  DateTime currentDate = DateTime.now();
  bool isLoading = true;
  int _currentNavIndex = 1; // Transaksi tab (bukan Home)
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> transactions = [];
  Map<int, Category> categoriesMap = {}; // Cache kategori dengan id sebagai key
  Map<int, Map<String, dynamic>> walletsMap =
      {}; // Cache dompet dengan id sebagai key

  // Date filter type: 'daily', 'weekly', 'monthly'
  String dateFilterType = 'weekly';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadUserData();
  }

  @override
  void didUpdateWidget(covariant TransactionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Reset state ke default
      setState(() {
        userName = "User";
        balance = 0;
        transactions = [];
        categoriesMap = {};
        walletsMap = {};
        isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final cachedName = prefs.getString('name') ?? '';

      if (token.isEmpty) {
        setState(() {
          userName = cachedName.isNotEmpty ? cachedName : "User";
          balance = prefs.getDouble('initialBalance') ?? 0;
          transactions = [];
          isLoading = false;
        });
        return;
      }

      // Fetch wallets from API
      final walletsResponse = await _apiService.getWallets(token: token);
      final wallets = walletsResponse['data'] as List? ?? [];
      final totalCurrentBalance = walletsResponse['total_current_balance'];

      // Use total_current_balance from API, convert to double if needed
      double totalBalance = 0;
      if (totalCurrentBalance is String) {
        totalBalance = double.tryParse(totalCurrentBalance) ?? 0;
      } else if (totalCurrentBalance is num) {
        totalBalance = totalCurrentBalance.toDouble();
      }

      // Fetch transactions
      final txList = await _apiService.getTransactions(token: token);

      // Fetch categories untuk mapping
      final categoriesList = await _apiService.getCategories(token: token);
      final categoryMap = <int, Category>{};
      for (var category in categoriesList) {
        categoryMap[category.id] = category;
      }

      // Build wallet map
      final walletMap = <int, Map<String, dynamic>>{};
      for (var wallet in wallets) {
        final id = wallet['id'] is String
            ? int.tryParse(wallet['id'] as String)
            : wallet['id'] as int?;
        if (id != null) {
          walletMap[id] = wallet as Map<String, dynamic>;
        }
      }

      setState(() {
        userName = cachedName.isNotEmpty ? cachedName : "User";
        balance = totalBalance;
        transactions = txList;
        categoriesMap = categoryMap;
        walletsMap = walletMap;
        isLoading = false;
      });

      // Simpan ke SharedPreferences untuk backup
      await prefs.setDouble('initialBalance', totalBalance);
    } catch (e) {
      // Fallback ke SharedPreferences jika API error
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userName = prefs.getString('name') ?? "User";
        balance = prefs.getDouble('initialBalance') ?? 0;
        transactions = [];
        categoriesMap = {};
        walletsMap = {};
        isLoading = false;
      });
    }
  }

  // Calculate monthly summary
  Map<String, dynamic> _calculateMonthlySummary() {
    double income = 0;
    double expense = 0;

    // Get date range berdasarkan filter type
    final dateRange = _getDateRange();
    final startDate = dateRange['start'] as DateTime;
    final endDate = dateRange['end'] as DateTime;

    for (var transaction in transactions) {
      final dateStr = transaction['trx_date'] as String?;
      if (dateStr == null) continue;

      try {
        final txDate = DateTime.parse(dateStr);
        // Bandingkan hanya tanggal (ignore waktu)
        final txDateOnly = DateTime(txDate.year, txDate.month, txDate.day);
        final startDateOnly = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

        // Filter transaksi yang masuk dalam range
        if ((txDateOnly.isAfter(startDateOnly) ||
                txDateOnly.isAtSameMomentAs(startDateOnly)) &&
            (txDateOnly.isBefore(endDateOnly) ||
                txDateOnly.isAtSameMomentAs(endDateOnly))) {
          final amount = (transaction['amount'] is String)
              ? double.tryParse(transaction['amount'] as String) ?? 0
              : (transaction['amount'] as num?)?.toDouble() ?? 0;

          // Get category_id from transaction
          final categoryId = transaction['category_id'] is String
              ? int.tryParse(transaction['category_id'] as String)
              : transaction['category_id'] as int?;

          // Lookup kategori dari cache
          final category = categoryId != null
              ? categoriesMap[categoryId]
              : null;
          final categoryKind = category?.kind == CategoryKind.income
              ? 'income'
              : 'expense';

          if (categoryKind == 'income') {
            income += amount;
          } else {
            expense += amount;
          }
        }
      } catch (e) {
        // Ignore parse errors
      }
    }

    return {'income': income, 'expense': expense, 'total': income + expense};
  }

  // Get date range berdasarkan dateFilterType
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
      // monthly
      final startOfMonth = DateTime(currentDate.year, currentDate.month, 1);
      final endOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0);
      return {'start': startOfMonth, 'end': endOfMonth};
    }
  }

  // Filter transactions berdasarkan date range
  List<Map<String, dynamic>> _getFilteredTransactions() {
    final dateRange = _getDateRange();
    final startDate = dateRange['start'] as DateTime;
    final endDate = dateRange['end'] as DateTime;

    final filtered = <Map<String, dynamic>>[];
    for (var transaction in transactions) {
      final dateStr = transaction['trx_date'] as String?;
      if (dateStr == null) continue;

      try {
        final txDate = DateTime.parse(dateStr);
        // Bandingkan hanya tanggal (ignore waktu)
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

  // Group transactions by date
  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate() {
    final groupedMap = <String, List<Map<String, dynamic>>>{};

    // Gunakan filtered transactions berdasarkan date range
    final filteredTransactions = _getFilteredTransactions();

    for (var transaction in filteredTransactions) {
      final dateStr = transaction['trx_date'] as String?;
      if (dateStr == null) continue;

      try {
        final txDate = DateTime.parse(dateStr);
        final dateKey = DateFormat('dd MMM yyyy', 'id_ID').format(txDate);

        if (!groupedMap.containsKey(dateKey)) {
          groupedMap[dateKey] = [];
        }
        groupedMap[dateKey]!.add(transaction);
      } catch (e) {
        // Ignore parse errors
      }
    }

    // Sort dates in descending order
    final sortedKeys = groupedMap.keys.toList();
    sortedKeys.sort((a, b) {
      final dateA = DateFormat('dd MMM yyyy', 'id_ID').parse(a);
      final dateB = DateFormat('dd MMM yyyy', 'id_ID').parse(b);
      return dateB.compareTo(dateA);
    });

    final sortedMap = <String, List<Map<String, dynamic>>>{};
    for (var key in sortedKeys) {
      sortedMap[key] = groupedMap[key]!;
    }

    return sortedMap;
  }

  Widget _buildGroupedTransactionList() {
    final groupedTransactions = _groupTransactionsByDate();

    return Column(
      children: groupedTransactions.entries.map((entry) {
        final dateKey = entry.key;
        final txList = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            // Transactions for this date
            ...txList.map((transaction) {
              final amount = transaction['amount'] ?? '0';
              final note = transaction['note'] ?? 'Transaksi';

              // Get wallet info from cache
              final walletId = transaction['dompet_id'] is String
                  ? int.tryParse(transaction['dompet_id'] as String)
                  : transaction['dompet_id'] as int?;
              final wallet = walletId != null ? walletsMap[walletId] : null;
              final walletName = wallet?['name']?.toString() ?? 'Dompet';

              // Get category info to determine color and icon
              final categoryId = transaction['category_id'] is String
                  ? int.tryParse(transaction['category_id'] as String)
                  : transaction['category_id'] as int?;
              final category = categoryId != null
                  ? categoriesMap[categoryId]
                  : null;
              final categoryKind = category?.kind == CategoryKind.income
                  ? 'income'
                  : 'expense';
              final isIncome = categoryKind == 'income';
              final transactionId = transaction['id'];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DetailTransactionScreen(transactionId: transactionId),
                    ),
                  ).then((result) {
                    // Refresh jika transaksi dihapus
                    if (result == true) {
                      _loadUserData();
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      // Category Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _getColorFromCategory(
                            category,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Icon(
                          _getIconFromCategory(category),
                          size: 20,
                          color: _getColorFromCategory(category),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Transaction Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              walletName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isIncome
                                ? "+Rp ${(amount is String ? double.tryParse(amount) ?? 0 : amount).toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}"
                                : "-Rp ${(amount is String ? double.tryParse(amount) ?? 0 : amount).toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isIncome
                                  ? const Color(0xFF5D9E85)
                                  : const Color(0xFFF75270),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'HH:mm',
                              'id_ID',
                            ).format(DateTime.parse(transaction['updated_at'])),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
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
    });
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
    });
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
                  // Header
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
                  // Filter Options
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Harian Option
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempDateFilterType = 'daily';
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
                                          color: tempDateFilterType == 'daily'
                                              ? const Color(0xFF5D9E85)
                                              : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.today,
                                          color: tempDateFilterType == 'daily'
                                              ? Colors.white
                                              : const Color(0xFF9CA3AF),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Harian",
                                            style: TextStyle(
                                              color: Color(0xFF1F2937),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            "Navigasi per hari",
                                            style: TextStyle(
                                              color: Color(0xFF6B7280),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Radio button
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: tempDateFilterType == 'daily'
                                          ? const Color(0xFF5D9E85)
                                          : const Color(0xFFD1D5DB),
                                      width: 2,
                                    ),
                                  ),
                                  child: tempDateFilterType == 'daily'
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Color(0xFF5D9E85),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Mingguan Option
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempDateFilterType = 'weekly';
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
                                          color: tempDateFilterType == 'weekly'
                                              ? const Color(0xFF5D9E85)
                                              : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.calendar_view_week,
                                          color: tempDateFilterType == 'weekly'
                                              ? Colors.white
                                              : const Color(0xFF9CA3AF),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Mingguan",
                                            style: TextStyle(
                                              color: Color(0xFF1F2937),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            "Navigasi per minggu",
                                            style: TextStyle(
                                              color: Color(0xFF6B7280),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Radio button
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: tempDateFilterType == 'weekly'
                                          ? const Color(0xFF5D9E85)
                                          : const Color(0xFFD1D5DB),
                                      width: 2,
                                    ),
                                  ),
                                  child: tempDateFilterType == 'weekly'
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Color(0xFF5D9E85),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Bulanan Option
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempDateFilterType = 'monthly';
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
                                          color: tempDateFilterType == 'monthly'
                                              ? const Color(0xFF5D9E85)
                                              : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.calendar_today,
                                          color: tempDateFilterType == 'monthly'
                                              ? Colors.white
                                              : const Color(0xFF9CA3AF),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Bulanan",
                                            style: TextStyle(
                                              color: Color(0xFF1F2937),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            "Navigasi per bulan",
                                            style: TextStyle(
                                              color: Color(0xFF6B7280),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Radio button
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: tempDateFilterType == 'monthly'
                                          ? const Color(0xFF5D9E85)
                                          : const Color(0xFFD1D5DB),
                                      width: 2,
                                    ),
                                  ),
                                  child: tempDateFilterType == 'monthly'
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Color(0xFF5D9E85),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
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
                            });
                            Navigator.pop(context);
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

  Widget _buildMonthlySummary() {
    final summary = _calculateMonthlySummary();
    final income = summary['income'] as double? ?? 0.0;
    final expense = summary['expense'] as double? ?? 0.0;

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Pendapatan",
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Pengeluaran",
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
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
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          // Total (Income - Expense)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        Navigator.of(context).pushNamed('/home');
        break;
      case 1:
        // Already on Transaction page
        setState(() => _currentNavIndex = 1);
        break;
      case 2:
        Navigator.of(context).pushNamed('/ringkasan');
        break;
      case 3:
        Navigator.of(context).pushNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate;
    if (dateFilterType == 'daily') {
      formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(currentDate);
    } else if (dateFilterType == 'weekly') {
      // Menampilkan tanggal awal minggu - tanggal akhir minggu
      final startOfWeek = currentDate.subtract(
        Duration(days: currentDate.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final startFormat = DateFormat('dd MMM', 'id_ID').format(startOfWeek);
      final endFormat = DateFormat('dd MMM yyyy', 'id_ID').format(endOfWeek);
      formattedDate = '$startFormat - $endFormat';
    } else {
      // monthly
      formattedDate = DateFormat('MMMM yyyy', 'id_ID').format(currentDate);
    }

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
                          isLoading ? "Loading..." : userName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLoading
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
          // TRANSACTION LIST OR EMPTY STATE
          Expanded(
            child: isLoading
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
                          "Memuat transaksi...",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : transactions.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Image.asset(
                        "assets/images/Money stress-pana 1.png",
                        width: 200,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Tidak ada Transaksi",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Ketuk tombol + untuk menambahkan transaksi pertama Kamu.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Summary Section
                        _buildMonthlySummary(),
                        // Transaction List
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: _buildGroupedTransactionList(),
                        ),
                        const SizedBox(height: 20),
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
              // Transaction was created, reload data
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

  // Helper method to get icon from category
  IconData _getIconFromCategory(Category? category) {
    if (category == null) return Icons.category;

    final iconName = category.icon?.toString();
    if (iconName == null) return Icons.category;

    final iconMap = {
      'shopping_bag': Icons.shopping_bag,
      'shopping_cart': Icons.shopping_cart,
      'school': Icons.school,
      'restaurant': Icons.restaurant,
      'fastfood': Icons.fastfood,
      'coffee': Icons.coffee,
      'card_giftcard': Icons.card_giftcard,
      'local_taxi': Icons.local_taxi,
      'directions_car': Icons.directions_car,
      'two_wheeler': Icons.two_wheeler,
      'flight': Icons.flight,
      'directions_bus': Icons.directions_bus,
      'checkroom': Icons.checkroom,
      'videogame_asset': Icons.videogame_asset,
      'movie': Icons.movie,
      'music_note': Icons.music_note,
      'attach_money': Icons.attach_money,
      'wallet': Icons.wallet,
      'credit_card': Icons.credit_card,
      'laptop': Icons.laptop,
      'phone_iphone': Icons.phone_iphone,
      'headphones': Icons.headphones,
      'camera_alt': Icons.camera_alt,
      'local_hospital': Icons.local_hospital,
      'local_pharmacy': Icons.local_pharmacy,
      'fitness_center': Icons.fitness_center,
      'trending_up': Icons.trending_up,
      'trending_down': Icons.trending_down,
      'home': Icons.home,
      'work': Icons.work,
      'savings': Icons.savings,
      'show_chart': Icons.show_chart,
      'payments': Icons.payments,
      'bolt': Icons.bolt,
      'water_drop': Icons.water_drop,
      'pets': Icons.pets,
      'beach_access': Icons.beach_access,
      'book': Icons.book,
      'more_horiz': Icons.more_horiz,
    };

    return iconMap[iconName.toLowerCase()] ?? Icons.category;
  }

  // Helper method to get color from category
  Color _getColorFromCategory(Category? category) {
    if (category == null) return const Color(0xFF9CA3AF);

    final hexColor = category.colorHex?.toString();
    if (hexColor == null || hexColor.isEmpty) {
      return const Color(0xFF9CA3AF);
    }

    try {
      String cleanHex = hexColor.replaceFirst('#', '').toUpperCase();
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return const Color(0xFF9CA3AF);
    }
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
}
