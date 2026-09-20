import 'package:flutter/material.dart';
import 'package:Ringkas/features/profile/view/add_wallet_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api_service.dart';

class DompetPage extends StatefulWidget {
  const DompetPage({super.key});

  @override
  State<DompetPage> createState() => _DompetPageState();
}

class _DompetPageState extends State<DompetPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> wallets = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
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

      final walletResponse = await _apiService.getWallets(token: token);
      final walletList = walletResponse['data'] as List? ?? [];

      setState(() {
        wallets = List<Map<String, dynamic>>.from(
          walletList.map((w) => w is Map ? w.cast<String, dynamic>() : {}),
        );
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic value) {
    late double numValue;

    if (value is String) {
      numValue = double.tryParse(value) ?? 0;
    } else if (value is num) {
      numValue = value.toDouble();
    } else {
      numValue = 0;
    }

    final formatted = numValue
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');

    return 'Rp $formatted';
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
        title: const Text(
          "Pilih Dompet",
          style: TextStyle(color: Color(0xFF374151)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF374151)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddWalletScreen(),
                ),
              ).then((_) {
                _loadWallets();
              });
            },
          ),
        ],
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
                    onPressed: _loadWallets,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : wallets.isEmpty
          ? const Center(child: Text('Tidak ada dompet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wallets.length,
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                final walletName = wallet['name'] ?? 'Dompet';
                final currency = wallet['currency'] ?? 'IDR';
                final balance =
                    wallet['current_balance'] ??
                    wallet['initial_balance'] ??
                    '0';

                return GestureDetector(
                  onTap: () {
                    // Return dompet yang dipilih ke add_transaction_screen (format: Nama - id)
                    final walletId = wallet['id'];
                    Navigator.pop(context, '$walletName - $walletId');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        // Icon dengan background circle
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
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Nama dan saldo dompet
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                walletName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF374151),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatCurrency(balance)} $currency',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Checkbox placeholder
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFD1D5DB),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
