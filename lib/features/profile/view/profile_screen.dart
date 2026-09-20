import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../data/services/api_service.dart';
import 'add_wallet_screen.dart';
import 'edit_wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "User";
  double balance = 0;
  bool isLoading = true;
  bool _isBalanceVisible = true; // State untuk show/hide balance
  int _currentNavIndex = 3; // Profile tab
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> wallets = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadUserData();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        userName = "User";
        balance = 0;
        wallets = [];
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
      final walletsDataList = walletsResponse['data'] as List? ?? [];
      final totalCurrentBalance = walletsResponse['total_current_balance'];

      // Use total_current_balance from API, convert to double if needed
      double totalBalance = 0;
      if (totalCurrentBalance is String) {
        totalBalance = double.tryParse(totalCurrentBalance) ?? 0;
      } else if (totalCurrentBalance is num) {
        totalBalance = totalCurrentBalance.toDouble();
      }

      // Get wallets data
      final walletsData = List<Map<String, dynamic>>.from(
        walletsDataList.map((w) => w is Map ? w.cast<String, dynamic>() : {}),
      );

      setState(() {
        userName = cachedName.isNotEmpty ? cachedName : "User";
        balance = totalBalance;
        wallets = walletsData;
        isLoading = false;
      });

      await prefs.setDouble('initialBalance', totalBalance);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userName = prefs.getString('name') ?? "User";
        balance = prefs.getDouble('initialBalance') ?? 0;
        wallets = [];
        isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    if (_currentNavIndex == index) return;

    switch (index) {
      case 0:
        Navigator.of(context).pushNamed('/home');
        break;
      case 1:
        Navigator.of(context).pushNamed('/transaction');
        break;
      case 2:
        Navigator.of(context).pushNamed('/ringkasan');
        break;
      case 3:
        // Already on Profile
        setState(() => _currentNavIndex = 3);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // HEADER - Simple nama only
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.fromSize(size: const Size.fromHeight(40)),
                Text(
                  isLoading ? "Loading..." : userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
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
                          "Memuat profil...",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BALANCE SECTION with curved top border
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "Saldo akun",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLoading
                                        ? "Loading..."
                                        : _isBalanceVisible
                                        ? "Rp ${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}"
                                        : "••••••••••",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5D9E85),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isBalanceVisible = !_isBalanceVisible;
                                      });
                                    },
                                    child: Icon(
                                      _isBalanceVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // DOMPET SECTION
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
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
                                "Dompet",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildWalletGrid(),
                            ],
                          ),
                        ),

                        // LOGOUT BUTTON
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Konfirmasi Logout"),
                                content: const Text(
                                  "Apakah Anda yakin ingin keluar?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      "Tidak",
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.remove('authToken');
                                      await prefs.remove('name');
                                      if (context.mounted) {
                                        Navigator.of(
                                          context,
                                        ).pushNamedAndRemoveUntil(
                                          '/welcome',
                                          (route) => false,
                                        );
                                      }
                                    },
                                    child: const Text(
                                      "Ya",
                                      style: TextStyle(
                                        color: Color(0xFFF75270),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
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
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.logout,
                                        size: 18,
                                        color: Color(0xFFF75270),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "Keluar",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFF75270),
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Color(0xFFF75270),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ],
      ),

      // FLOATING BUTTON
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

      // NAVBAR
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
            Expanded(child: Center(child: SizedBox.shrink())),
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

  Widget _buildWalletGrid() {
    return Column(
      children: [
        // Wallet grid
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 6,
            childAspectRatio: 3 / 2,
          ),
          itemCount: wallets.length + 1, // +1 untuk tombol tambah
          itemBuilder: (context, index) {
            if (index < wallets.length) {
              final wallet = wallets[index];
              final walletName = wallet['name'] ?? 'Dompet';
              final walletBalance =
                  wallet['current_balance'] ?? wallet['initial_balance'];

              // Convert balance to double
              double balance = 0;
              if (walletBalance is String) {
                balance = double.tryParse(walletBalance) ?? 0;
              } else if (walletBalance is num) {
                balance = walletBalance.toDouble();
              }

              return _buildWalletCard(
                wallet: wallet,
                name: walletName,
                balance: balance.toInt(),
              );
            } else {
              // Tombol tambah dompet
              return GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddWalletScreen(),
                    ),
                  );
                  // Reload wallet data jika ada yang ditambahkan
                  if (result == true) {
                    _loadUserData();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 40, color: Color(0xFF1F2937)),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildWalletCard({
    required Map<String, dynamic> wallet,
    required String name,
    required int balance,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditWalletScreen(wallet: wallet),
          ),
        );
        // Reload wallet data jika ada yang diubah
        if (result == true) {
          _loadUserData();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE5F3F0),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF5D9E85),
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Rp ${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
}
