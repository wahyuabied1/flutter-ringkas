import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../data/services/api_service.dart';
import '../../../data/model/category_model.dart';

class RingkasanTransactionListScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String dateFilterType; // 'daily', 'weekly', 'monthly'

  const RingkasanTransactionListScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.dateFilterType,
  });

  @override
  State<RingkasanTransactionListScreen> createState() =>
      _RingkasanTransactionListScreenState();
}

class _RingkasanTransactionListScreenState
    extends State<RingkasanTransactionListScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> transactions = [];
  Map<int, Category> categoriesMap = {};
  Map<int, Map<String, dynamic>> walletsMap = {};
  bool isLoading = true;
  String errorMessage = '';

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

      // Filter transactions by date range
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
            filteredTransactions.add(tx);
          }
        }
      }

      // Sort by date descending
      filteredTransactions.sort((a, b) {
        final dateA = DateTime.tryParse(a['trx_date'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['trx_date'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      setState(() {
        transactions = filteredTransactions;
        categoriesMap = categoryMap;
        walletsMap = walletMap;
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

    final iconName = category.icon?.toString().toLowerCase();
    if (iconName == null) return Icons.category;

    const iconMap = {
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

    return iconMap[iconName] ?? Icons.category;
  }

  // Helper method to get color from category
  Color _getColorFromCategory(Category? category) {
    if (category == null) return const Color(0xFF9CA3AF);

    final hexColor = category.colorHex?.toString();
    if (hexColor == null) return const Color(0xFF9CA3AF);

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

  // Group transactions by date
  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate() {
    final groupedMap = <String, List<Map<String, dynamic>>>{};

    for (var transaction in transactions) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transaksi ${widget.dateFilterType == 'daily'
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
          : transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada transaksi',
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
                // Transaction list - grouped by date
                Expanded(child: _buildGroupedTransactionList()),
              ],
            ),
    );
  }

  Widget _buildGroupedTransactionList() {
    final groupedTransactions = _groupTransactionsByDate();

    return ListView(
      padding: const EdgeInsets.all(16),
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
              final categoryId = transaction['category_id'] is String
                  ? int.tryParse(transaction['category_id'] as String)
                  : transaction['category_id'] as int?;
              final category = categoryId != null
                  ? categoriesMap[categoryId]
                  : null;

              final amount = transaction['amount'] is String
                  ? double.tryParse(transaction['amount'] as String) ?? 0
                  : (transaction['amount'] as num?)?.toDouble() ?? 0;

              final isIncome = category?.kind == CategoryKind.income;
              final note = transaction['note'] ?? 'Transaksi';
              final walletName = transaction['dompet_name'] ?? 'Dompet';
              final txDateTime =
                  DateTime.tryParse(transaction['updated_at'] ?? '') ??
                  DateTime.now();

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
                              ? "+Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}"
                              : "-Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
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
                          DateFormat('HH:mm', 'id_ID').format(txDateTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      }).toList(),
    );
  }
}
