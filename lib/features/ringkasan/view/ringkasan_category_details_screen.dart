import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/services/api_service.dart';
import '../../../data/model/category_model.dart';

class RingkasanCategoryDetailsScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String dateFilterType; // 'daily', 'weekly', 'monthly'

  const RingkasanCategoryDetailsScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.dateFilterType,
  });

  @override
  State<RingkasanCategoryDetailsScreen> createState() =>
      _RingkasanCategoryDetailsScreenState();
}

class _RingkasanCategoryDetailsScreenState
    extends State<RingkasanCategoryDetailsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> transactions = [];
  Map<int, Category> categoriesMap = {};
  Map<int, Map<String, dynamic>> walletsMap = {};
  bool isLoading = true;
  String errorMessage = '';

  // Kategori pengeluaran dengan detailnya
  List<Map<String, dynamic>> expenseCategories = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      // Fetch all transactions
      final txData = await _apiService.getTransactionsData(token: token);
      final txList = txData['transactions'] as List<Map<String, dynamic>>;

      // Fetch categories
      final categoriesList = await _apiService.getCategories(token: token);
      final categoryMap = <int, Category>{};
      for (var category in categoriesList) {
        categoryMap[category.id] = category;
      }

      // Fetch wallets
      final walletsResponse = await _apiService.getWallets(token: token);
      final walletsData = walletsResponse['data'] as List? ?? [];
      final walletMap = <int, Map<String, dynamic>>{};
      for (var wallet in walletsData) {
        if (wallet is Map) {
          final walletData = wallet is Map<String, dynamic>
              ? wallet
              : wallet.cast<String, dynamic>();

          final id = walletData['id'] is String
              ? int.tryParse(walletData['id'] as String)
              : walletData['id'] as int?;
          if (id != null) {
            walletMap[id] = walletData;
          }
        }
      }

      // Filter transactions by date range and ONLY expenses
      final filteredTransactions = <Map<String, dynamic>>[];
      for (var tx in txList) {
        final txDate = DateTime.tryParse(tx['trx_date'] ?? '');
        if (txDate != null) {
          // Normalize dates to only compare date part (year, month, day)
          final txDateOnly = DateTime(txDate.year, txDate.month, txDate.day);
          final startDateOnly = DateTime(
            widget.startDate.year,
            widget.startDate.month,
            widget.startDate.day,
          );
          final endDateOnly = DateTime(
            widget.endDate.year,
            widget.endDate.month,
            widget.endDate.day,
          );

          // Check if txDate is between startDate and endDate (inclusive)
          if (!txDateOnly.isBefore(startDateOnly) &&
              !txDateOnly.isAfter(endDateOnly)) {
            // Check if this is an expense (not income)
            final categoryId = tx['category_id'] is String
                ? int.tryParse(tx['category_id'] as String)
                : tx['category_id'] as int?;
            final category = categoryId != null
                ? categoryMap[categoryId]
                : null;
            if (category != null && category.kind == CategoryKind.expense) {
              filteredTransactions.add(tx);
            }
          }
        }
      }

      // Sort by date descending
      filteredTransactions.sort((a, b) {
        final dateA = DateTime.tryParse(a['trx_date'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['trx_date'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      // Group by category and calculate totals
      final categoryTotals = <int, Map<String, dynamic>>{};
      for (var tx in filteredTransactions) {
        final categoryId = tx['category_id'] is String
            ? int.tryParse(tx['category_id'] as String)
            : tx['category_id'] as int?;

        if (categoryId != null && !categoryTotals.containsKey(categoryId)) {
          final category = categoryMap[categoryId];
          categoryTotals[categoryId] = {
            'category': category,
            'totalAmount': 0.0,
            'transactionCount': 0,
            'color': _getColorFromCategory(category),
          };
        }

        if (categoryId != null) {
          final amount = tx['amount'] is String
              ? double.tryParse(tx['amount'] as String) ?? 0
              : (tx['amount'] as num?)?.toDouble() ?? 0;

          categoryTotals[categoryId]!['totalAmount'] += amount;
          categoryTotals[categoryId]!['transactionCount'] =
              (categoryTotals[categoryId]!['transactionCount'] as int) + 1;
        }
      }

      // Convert to list and sort by total amount descending
      final categories = categoryTotals.values.toList();
      categories.sort((a, b) {
        final amountA = a['totalAmount'] as double;
        final amountB = b['totalAmount'] as double;
        return amountB.compareTo(amountA);
      });

      setState(() {
        transactions = filteredTransactions;
        categoriesMap = categoryMap;
        walletsMap = walletMap;
        expenseCategories = categories;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
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
      'local_gas_station': Icons.local_gas_station,
      'favorite': Icons.favorite,
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

  String _getDateRangeLabel() {
    final startFormatted = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(widget.startDate);
    final endFormatted = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(widget.endDate);

    if (widget.dateFilterType == 'daily') {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(widget.startDate);
    }

    return '$startFormatted - $endFormatted';
  }

  // Calculate percentage for each category
  double _calculatePercentage(double amount) {
    double total = 0;
    for (var category in expenseCategories) {
      total += category['totalAmount'] as double;
    }
    if (total == 0) return 0;
    return (amount / total) * 100;
  }

  // Calculate total expense
  double _calculateTotalExpense() {
    double total = 0;
    for (var category in expenseCategories) {
      total += category['totalAmount'] as double;
    }
    return total;
  }

  // Build pie chart sections
  List<PieChartSectionData> _buildPieChartSections() {
    final totalExpense = _calculateTotalExpense();
    if (totalExpense == 0) return [];

    return expenseCategories.map((categoryData) {
      final totalAmount = categoryData['totalAmount'] as double;
      final percentage = (totalAmount / totalExpense) * 100;
      final color = categoryData['color'] as Color;

      return PieChartSectionData(
        color: color,
        value: percentage,
        radius: 50,
        titlePositionPercentageOffset: 0.5,
        showTitle: true,
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Struktur ${widget.dateFilterType == 'daily'
              ? 'Harian'
              : widget.dateFilterType == 'weekly'
              ? 'Mingguan'
              : 'Bulanan'}',
          style: const TextStyle(color: Color(0xFF374151)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $errorMessage',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTransactions,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : expenseCategories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada pengeluaran',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDateRangeLabel(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Chart section
                if (expenseCategories.isNotEmpty)
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
                          "Struktur pengeluaran",
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Chart with percentage labels inside
                        Center(
                          child: SizedBox(
                            height: 300,
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 220,
                                  width: 220,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _buildPieChartSections(),
                                      centerSpaceRadius: 70,
                                      sectionsSpace: 2,
                                    ),
                                  ),
                                ),
                                // Center Total text
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                      "Rp ${_calculateTotalExpense().toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
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
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Divider
                        const Divider(color: Color(0xFFE5E7EB), height: 1),
                      ],
                    ),
                  ),
                // Category breakdown list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: expenseCategories.map((categoryData) {
                      final category = categoryData['category'] as Category;
                      final totalAmount = categoryData['totalAmount'] as double;
                      final transactionCount =
                          categoryData['transactionCount'] as int;
                      final color = categoryData['color'] as Color;
                      final percentage = _calculatePercentage(totalAmount);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Category Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Icon(
                                _getIconFromCategory(category),
                                size: 20,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Category Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$transactionCount transaksi',
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
                            // Amount
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "-Rp ${totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF75270),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
