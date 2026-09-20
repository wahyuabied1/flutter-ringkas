import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api_service.dart';
import '../../../data/model/category_model.dart';
import 'kategori_page.dart';
import 'dompet_page.dart';

class AddTransactionScreen extends StatefulWidget {
  final dynamic transactionId; // null untuk mode add, id untuk mode edit
  final Map<String, dynamic>? transactionData; // data transaksi untuk edit mode

  const AddTransactionScreen({
    super.key,
    this.transactionId,
    this.transactionData,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isExpense = true; // true = Pengeluaran, false = Pendapatan
  bool isLoading = false;

  final dateController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final _apiService = ApiService();

  String selectedCategory = "Pilih Kategori";
  String selectedWallet = "Pilih Dompet";
  dynamic selectedCategoryId; // Store category ID
  dynamic selectedWalletId; // Store wallet ID
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.transactionData != null) {
      // Mode Edit: Populate form dengan data transaksi
      _populateEditData();
    } else {
      // Mode Add
      _updateDateController();
    }
  }

  void _populateEditData() {
    final data = widget.transactionData!;

    // Set tanggal
    try {
      selectedDate = DateTime.parse(
        data['trx_date'] ?? DateTime.now().toString(),
      );
    } catch (e) {
      selectedDate = DateTime.now();
    }
    _updateDateController();

    // Set amount - hapus minus jika ada
    final amount = data['amount']?.toString() ?? '';
    amountController.text = amount.replaceAll('-', '');

    // Set note
    noteController.text = data['note'] ?? '';

    // Set kategori - gunakan kategori_name dari response dan simpan ID
    selectedCategory = data['kategori_name'] ?? 'Pilih Kategori';
    selectedCategoryId = data['category_id']; // Store ID dari response

    // Set dompet - gunakan dompet_name dari response dan simpan ID
    selectedWallet = data['dompet_name'] ?? 'Pilih Dompet';
    selectedWalletId = data['dompet_id']; // Store ID dari response

    // Determine if income or expense - fetch dari API
    _determineCategoryKindFromAPI(data['kategori_name'], data['category_id']);
  }

  /// Fetch kategori dari API dan tentukan apakah income atau expense
  Future<void> _determineCategoryKindFromAPI(
    String? categoryName,
    dynamic categoryId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) return;

      final categories = await _apiService.getCategories(token: token);

      // Cari kategori berdasarkan ID
      Category? category;
      for (var cat in categories) {
        if (cat.id.toString() == categoryId.toString()) {
          category = cat;
          break;
        }
      }

      if (category != null) {
        setState(() {
          isExpense = category!.kind == CategoryKind.expense;
        });
      }
    } catch (e) {
      // Fallback ke default (expense)
      setState(() {
        isExpense = true;
      });
    }
  }

  void _updateDateController() {
    final formatter = DateFormat('dd/MM/yyyy   HH:mm', 'id_ID');
    dateController.text = formatter.format(selectedDate);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _updateDateController();
      });
    }
  }

  Future<void> _submitTransaction() async {
    // Validasi input
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah tidak boleh kosong')),
      );
      return;
    }

    if (noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan tidak boleh kosong')),
      );
      return;
    }

    if (selectedCategory == "Pilih Kategori") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    if (selectedWallet == "Pilih Dompet") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet terlebih dahulu')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final userId = prefs.getString('userId') ?? '';

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      // Parse amount
      final amount = double.tryParse(amountController.text);
      if (amount == null) {
        throw Exception('Jumlah harus berupa angka');
      }

      // Format date for API (YYYY-MM-DD HH:MM:SS)
      final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      final trxDate = formatter.format(selectedDate);

      // Extract/Get category ID
      final isEditMode = widget.transactionId != null;
      final categoryId = isEditMode
          ? selectedCategoryId // Use stored ID from edit mode
          : _extractIdFromString(selectedCategory); // Extract from add mode
      if (categoryId == null) {
        throw Exception('ID kategori tidak valid');
      }

      // Extract/Get wallet ID
      final walletId = isEditMode
          ? selectedWalletId // Use stored ID from edit mode
          : _extractIdFromString(selectedWallet); // Extract from add mode
      if (walletId == null) {
        throw Exception('ID dompet tidak valid');
      }

      if (isEditMode) {
        // Update transaction
        await _apiService.updateTransaction(
          token: token,
          id: widget.transactionId,
          amount: amount,
          note: noteController.text,
          trxDate: trxDate,
          categoryId: categoryId,
          walletId: walletId,
        );
      } else {
        // Create transaction
        await _apiService.createTransaction(
          userId: userId,
          type: isExpense ? 'Pengeluaran' : 'Pendapatan',
          amount: amount,
          note: noteController.text,
          trxDate: trxDate,
          categoryId: categoryId,
          walletId: walletId,
          token: token,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Transaksi berhasil diperbarui'
                  : 'Transaksi berhasil disimpan',
            ),
          ),
        );
        Navigator.pop(context, true);
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

  // Helper function to extract ID from format "Nama - id"
  String? _extractIdFromString(String value) {
    if (value.contains(' - ')) {
      final parts = value.split(' - ');
      return parts.last;
    }
    return null;
  }

  // Helper function to extract name from format "Nama - id"
  String _extractNameFromString(String value) {
    if (value.contains(' - ')) {
      final parts = value.split(' - ');
      return parts.first;
    }
    return value;
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
          widget.transactionId != null
              ? "Edit Transaksi"
              : (isExpense ? "Pengeluaran" : "Pendapatan"),
          style: const TextStyle(color: Color(0xFF374151)),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _submitTransaction,
            child: Text(
              widget.transactionId != null ? "PERBARUI" : "SIMPAN",
              style: TextStyle(
                color: isLoading
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF5D9E85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TAB Pemasukan / Pengeluaran
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    isExpense = false;
                    // Reset kategori saat switch ke Pendapatan
                    selectedCategory = "Pilih Kategori";
                    selectedCategoryId = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isExpense ? Colors.white : const Color(0xFF5D9E85),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Pendapatan",
                      style: TextStyle(
                        color: isExpense
                            ? const Color(0xFF374151)
                            : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    isExpense = true;
                    // Reset kategori saat switch ke Pengeluaran
                    selectedCategory = "Pilih Kategori";
                    selectedCategoryId = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isExpense ? const Color(0xFFF75270) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Pengeluaran",
                      style: TextStyle(
                        color: isExpense
                            ? Colors.white
                            : const Color(0xFF374151),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // FORM INPUT
          inputLabel("Tanggal"),
          datePickerBox(dateController),

          inputLabel("Jumlah"),
          inputBox(controller: amountController, hint: "Rp 0"),

          inputLabel("Deskripsi"),
          inputBox(controller: noteController, hint: "Deskripsi singkat"),

          inputLabel("Kategori"),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KategoriPage(isExpense: isExpense),
                ),
              );
              if (result != null) {
                setState(() {
                  selectedCategory = result;
                  selectedCategoryId = _extractIdFromString(result);
                });
              }
            },
            child: dropdownBox(
              selectedCategory == "Pilih Kategori"
                  ? selectedCategory
                  : _extractNameFromString(selectedCategory),
              () {},
            ),
          ),

          inputLabel("Dompet"),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DompetPage()),
              );
              if (result != null) {
                setState(() {
                  selectedWallet = result;
                  selectedWalletId = _extractIdFromString(result);
                });
              }
            },
            child: dropdownBox(
              selectedWallet == "Pilih Dompet"
                  ? selectedWallet
                  : _extractNameFromString(selectedWallet),
              () {},
            ),
          ),
        ],
      ),
    );
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
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0x7F9CA3AF), // 50% transparency
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget datePickerBox(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: _selectDate,
      decoration: InputDecoration(
        hintText: "Pilih tanggal",
        hintStyle: const TextStyle(
          color: Color(0x7F9CA3AF), // 50% transparency
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF9CA3AF)),
      ),
    );
  }

  Widget dropdownBox(String label, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color.fromARGB(255, 0, 0, 0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          const Icon(
            Icons.arrow_drop_down,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ],
      ),
    );
  }
}
