import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../data/services/api_service.dart';
import '../../../data/model/category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "User";
  double balance = 0;
  DateTime currentDate = DateTime.now();
  bool isLoading = true;
  int _currentNavIndex = 0;
  final ApiService _apiService = ApiService();

  // New state variables
  List<Map<String, dynamic>> wallets = [];
  int? selectedWalletId;
  List<Map<String, dynamic>> transactions = [];
  Map<int, Category> categoriesMap = {};
  Map<int, Map<String, dynamic>> walletsMap = {};

  // Monthly summary from API
  double monthlySummaryIncome = 0;
  double monthlySummaryExpense = 0;
  double monthlySummaryTotal = 0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadUserData();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Reset state ke default
      setState(() {
        userName = "User";
        balance = 0;
        wallets = [];
        selectedWalletId = null;
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
          isLoading = false;
        });
        return;
      }

      // Fetch wallets from API
      final walletsResponse = await _apiService.getWallets(token: token);
      final walletsData = walletsResponse['data'] as List? ?? [];
      final totalCurrentBalance = walletsResponse['total_current_balance'];

      // Use total_current_balance from API, convert to double if needed
      double totalBalance = 0;
      if (totalCurrentBalance is String) {
        totalBalance = double.tryParse(totalCurrentBalance) ?? 0;
      } else if (totalCurrentBalance is num) {
        totalBalance = totalCurrentBalance.toDouble();
      }

      // Build wallets map - safely cast each wallet
      final walletMap = <int, Map<String, dynamic>>{};
      final processedWallets = <Map<String, dynamic>>[];

      for (var wallet in walletsData) {
        if (wallet is Map) {
          final walletData = wallet is Map<String, dynamic>
              ? wallet
              : wallet.cast<String, dynamic>();
          processedWallets.add(walletData);

          final id = walletData['id'] is String
              ? int.tryParse(walletData['id'] as String)
              : walletData['id'] as int?;
          if (id != null) {
            walletMap[id] = walletData;
          }
        }
      }

      // Set selected wallet ke wallet pertama jika ada
      int? firstWalletId;
      if (processedWallets.isNotEmpty) {
        firstWalletId = processedWallets[0]['id'] is String
            ? int.tryParse(processedWallets[0]['id'] as String)
            : processedWallets[0]['id'] as int?;
      }

      // Fetch transactions with summary data
      final txData = await _apiService.getTransactionsData(token: token);
      final txList = txData['transactions'] as List<Map<String, dynamic>>;

      // Parse monthly summary from API
      double monthlyIncome = 0;
      double monthlyExpense = 0;
      final totalTranx = txData['total_transaksi'];
      if (totalTranx is String) {
        final parsedTotal = double.tryParse(totalTranx) ?? 0;
        monthlyExpense = parsedTotal.abs(); // abs because it's negative
      } else if (totalTranx is num) {
        monthlyExpense = totalTranx.toDouble().abs();
      }

      // Fetch categories untuk mapping
      final categoriesList = await _apiService.getCategories(token: token);
      final categoryMap = <int, Category>{};
      for (var category in categoriesList) {
        categoryMap[category.id] = category;
      }

      setState(() {
        userName = cachedName.isNotEmpty ? cachedName : "User";
        balance = totalBalance;
        wallets = processedWallets;
        selectedWalletId = firstWalletId;
        transactions = txList;
        categoriesMap = categoryMap;
        walletsMap = walletMap;
        monthlySummaryIncome = monthlyIncome;
        monthlySummaryExpense = monthlyExpense;
        monthlySummaryTotal = monthlyIncome - monthlyExpense;
        isLoading = false;
      });

      // Simpan ke SharedPreferences untuk backup
      await prefs.setDouble('initialBalance', totalBalance);
    } catch (e) {
      // Fallback ke SharedPreferences jika API error
      print('Error loading home data: $e');
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userName = prefs.getString('name') ?? "User";
        balance = prefs.getDouble('initialBalance') ?? 0;
        wallets = [];
        selectedWalletId = null;
        isLoading = false;
      });
    }
  }

  // Calculate monthly summary for selected wallet
  Map<String, dynamic> _calculateMonthlySummaryForWallet() {
    double income = 0;
    double expense = 0;

    final selectedMonth = currentDate.month;
    final selectedYear = currentDate.year;

    for (var transaction in transactions) {
      final dateStr = transaction['trx_date'] as String?;
      if (dateStr == null) continue;

      // Filter by selected wallet
      final txWalletId = transaction['dompet_id'] is String
          ? int.tryParse(transaction['dompet_id'] as String)
          : transaction['dompet_id'] as int?;
      if (selectedWalletId != null && txWalletId != selectedWalletId) {
        continue;
      }

      try {
        final txDate = DateTime.parse(dateStr);
        if (txDate.month == selectedMonth && txDate.year == selectedYear) {
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

  void _prevDate() => setState(
    () => currentDate = DateTime(currentDate.year, currentDate.month - 1),
  );
  void _nextDate() => setState(
    () => currentDate = DateTime(currentDate.year, currentDate.month + 1),
  );

  void _onWalletSelected(int? walletId) {
    setState(() {
      selectedWalletId = walletId;
    });
  }

  Widget _buildWalletSelectorList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: wallets.length,
      itemBuilder: (context, index) {
        final walletData = wallets[index];

        final walletId = walletData['id'] is String
            ? int.tryParse(walletData['id'] as String)
            : walletData['id'] as int?;

        final walletName = walletData['name']?.toString() ?? 'Dompet';

        final balanceData =
            walletData['current_balance'] ?? walletData['initial_balance'];
        double walletBalance = 0;
        if (balanceData is String) {
          walletBalance = double.tryParse(balanceData) ?? 0;
        } else if (balanceData is num) {
          walletBalance = balanceData.toDouble();
        }

        final isSelected = selectedWalletId == walletId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _onWalletSelected(walletId),
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
                            Icons.account_balance_wallet,
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
                              walletName,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rp ${walletBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
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
                  // Radio button
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
        );
      },
    );
  }

  void _onNavTap(int index) {
    if (_currentNavIndex == index)
      return; // Jangan buat setState jika sudah di tab yang sama

    switch (index) {
      case 0:
        // Already on Home - reset state
        setState(() => _currentNavIndex = 0);
        break;
      case 1:
        Navigator.of(context).pushNamed('/transaction');
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
    String formattedDate = DateFormat('MMMM yyyy', 'id_ID').format(currentDate);

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

          // CONTENT AREA
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
                          "Memuat data...",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Bulan Ini Section
                        _buildMonthlySummaryWidget(),
                        const SizedBox(height: 20),
                        // Wallet Selector
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Dompet Saat Ini",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildWalletSelectorList(),
                            ],
                          ),
                        ),
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
          onPressed: () {
            Navigator.of(context).pushNamed('/add-transaction');
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

  Widget _buildMonthlySummaryWidget() {
    final summary = _calculateMonthlySummaryForWallet();
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
            "Total Bulan Ini",
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
          // Total
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
