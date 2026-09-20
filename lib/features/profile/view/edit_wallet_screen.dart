import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api_service.dart';

class EditWalletScreen extends StatefulWidget {
  final Map<String, dynamic> wallet;

  const EditWalletScreen({super.key, required this.wallet});

  @override
  State<EditWalletScreen> createState() => _EditWalletScreenState();
}

class _EditWalletScreenState extends State<EditWalletScreen> {
  final ApiService _apiService = ApiService();

  late TextEditingController walletNameController;
  late TextEditingController initialBalanceController;

  late String selectedCurrency;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    walletNameController = TextEditingController(
      text: widget.wallet['name'] ?? '',
    );
    initialBalanceController = TextEditingController(
      text: widget.wallet['initial_balance']?.toString() ?? '0',
    );
    selectedCurrency = widget.wallet['currency'] ?? 'IDR';
  }

  @override
  void dispose() {
    walletNameController.dispose();
    initialBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submitWallet() async {
    if (walletNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dompet tidak boleh kosong')),
      );
      return;
    }

    if (initialBalanceController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saldo tidak boleh kosong')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      // Parse balance
      final initialBalance = double.tryParse(initialBalanceController.text);
      if (initialBalance == null) {
        throw Exception('Saldo harus berupa angka');
      }

      // Get wallet ID from widget data
      final walletId = widget.wallet['id'];
      if (walletId == null) {
        throw Exception('Wallet ID tidak ditemukan');
      }

      // Call API to update wallet
      await _apiService.updateWallet(
        id: walletId,
        name: walletNameController.text,
        currencyCode: selectedCurrency,
        initialBalance: initialBalance,
        token: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dompet berhasil diperbarui')),
        );
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate wallet was updated
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
          "Edit Dompet",
          style: TextStyle(color: Color(0xFF374151)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // NAMA DOMPET
                inputLabel("Nama Dompet"),
                inputBox(
                  controller: walletNameController,
                  hint: "Contoh: Dompet Utama",
                ),

                // SALDO
                inputLabel("Saldo"),
                inputBox(
                  controller: initialBalanceController,
                  hint: "Rp 0",
                  keyboardType: TextInputType.number,
                ),

                // CURRENCY
                inputLabel("Mata Uang"),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: selectedCurrency,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => selectedCurrency = newValue);
                      }
                    },
                    items: <String>['IDR', 'USD', 'EUR']
                        .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        })
                        .toList(),
                  ),
                ),

                const SizedBox(height: 32),

                // SUBMIT BUTTON
                ElevatedButton(
                  onPressed: isLoading ? null : _submitWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D9E85),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Perbarui Dompet",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // DELETE BUTTON
                ElevatedButton(
                  onPressed: isLoading ? null : _showDeleteConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF75270),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Hapus Dompet",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Dompet"),
        content: const Text("Apakah Anda yakin ingin menghapus dompet ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Batal",
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteWallet();
            },
            child: const Text(
              "Hapus",
              style: TextStyle(color: Color(0xFFF75270)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWallet() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final walletId = widget.wallet['id'];
      if (walletId == null) {
        throw Exception('Wallet ID tidak ditemukan');
      }

      // Call API to delete wallet
      await _apiService.deleteWallet(id: walletId, token: token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dompet berhasil dihapus')),
        );
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate wallet was deleted
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget inputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 16),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF374151), fontSize: 14),
      ),
    );
  }

  Widget inputBox({
    required TextEditingController controller,
    String hint = "",
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
