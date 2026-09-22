import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/model/category_model.dart';
import '../../../data/model/wallet_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/receipt_parser.dart';
import '../../profile/view/add_wallet_screen.dart';

enum _Step { pick, processing, review, error }

/// Pindai screenshot notifikasi/struk pembayaran (OVO, GoPay, dll), baca
/// nominal-tanggal-jenisnya secara otomatis dengan OCR di perangkat (tidak
/// ada gambar yang dikirim ke internet), lalu tampilkan hasilnya untuk
/// diperiksa sebelum disimpan sebagai transaksi biasa.
class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final _apiService = ApiService();
  _Step _step = _Step.pick;
  String? _errorMessage;
  String _rawText = '';

  List<Wallet> _wallets = [];
  List<Category> _categories = [];

  bool isExpense = true;
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  int? selectedCategoryId;
  int? selectedWalletId;
  bool isSaving = false;

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  List<Category> get _categoriesForKind => _categories
      .where((c) => c.kind == (isExpense ? CategoryKind.expense : CategoryKind.income))
      .toList();

  Future<void> _pickAndProcess() async {
    final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _step = _Step.processing;
      _errorMessage = null;
    });

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(file.path));
      final text = result.text;
      if (text.trim().isEmpty) {
        setState(() {
          _step = _Step.error;
          _errorMessage = 'Tidak ada teks yang terbaca dari gambar ini. '
              'Coba screenshot yang lebih jelas, atau isi manual.';
        });
        return;
      }
      await _prepareReview(text);
    } catch (e) {
      setState(() {
        _step = _Step.error;
        _errorMessage = 'Gagal memproses gambar: $e';
      });
    } finally {
      await recognizer.close();
    }
  }

  Future<void> _prepareReview(String rawText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      if (token.isEmpty) throw Exception('Token tidak ditemukan. Silakan masuk kembali.');

      final results = await Future.wait([
        _apiService.getWalletsList(token: token),
        _apiService.getCategories(token: token),
      ]);
      final wallets = results[0] as List<Wallet>;
      final categories = results[1] as List<Category>;

      final parsed = parseReceipt(rawText);
      final guessedCategoryId = guessCategoryId(
        categories: categories,
        kind: parsed.kind,
        note: parsed.note,
      );

      if (!mounted) return;
      setState(() {
        _rawText = rawText;
        _wallets = wallets;
        _categories = categories;
        isExpense = parsed.kind == TrxKind.expense;
        amountController.text = parsed.amount == null ? '' : parsed.amount!.toStringAsFixed(0);
        noteController.text = parsed.note;
        selectedDate = parsed.date ?? DateTime.now();
        selectedCategoryId = guessedCategoryId;
        selectedWalletId = wallets.isNotEmpty ? wallets.first.id : null;
        _step = _Step.review;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _setKind(bool expense) {
    setState(() {
      isExpense = expense;
      if (!_categoriesForKind.any((c) => c.id == selectedCategoryId)) {
        selectedCategoryId = null;
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateTime(
          picked.year, picked.month, picked.day, selectedDate.hour, selectedDate.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Jumlah harus berupa angka lebih dari 0')));
      return;
    }
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu')));
      return;
    }
    if (selectedWalletId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih dompet terlebih dahulu')));
      return;
    }

    setState(() => isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      if (token.isEmpty) throw Exception('Token tidak ditemukan');

      final trxDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDate);
      await _apiService.createTransaction(
        userId: prefs.getString('userId') ?? '',
        type: isExpense ? 'Pengeluaran' : 'Pendapatan',
        amount: amount,
        note: noteController.text.trim().isEmpty ? 'Transaksi' : noteController.text.trim(),
        trxDate: trxDate,
        categoryId: selectedCategoryId,
        walletId: selectedWalletId,
        token: token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Transaksi dari struk berhasil disimpan')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
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
        title: const Text('Pindai Struk', style: TextStyle(color: Color(0xFF374151))),
      ),
      body: switch (_step) {
        _Step.pick => _buildPick(),
        _Step.processing => const _CenterMessage(
            message: 'Membaca gambar...',
            child: CircularProgressIndicator(color: Color(0xFF5D9E85)),
          ),
        _Step.error => _buildError(),
        _Step.review => _buildReview(),
      },
    );
  }

  Widget _buildPick() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 72, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            const Text(
              'Pindai Screenshot Struk',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nominal, tanggal, dan jenis transaksi dari screenshot OVO, GoPay, '
              'atau e-wallet lain dibaca otomatis langsung di HP kamu (tidak '
              'dikirim ke internet). Hasilnya tetap bisa diperiksa dan diedit '
              'sebelum disimpan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickAndProcess,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Pilih Screenshot dari Galeri'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D9E85),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => setState(() => _step = _Step.pick),
              child: const Text('Coba Screenshot Lain'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final result = await Navigator.of(context).pushNamed('/add-transaction');
                if (mounted && result == true) Navigator.pop(context, true);
              },
              child: const Text('Isi Manual Saja'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    final categories = _categoriesForKind;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDBA74)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFC2410C), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hasil baca otomatis. Periksa dan perbaiki sebelum disimpan.',
                  style: TextStyle(fontSize: 13, color: Color(0xFFC2410C)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _KindButton(
                label: 'Pengeluaran',
                selected: isExpense,
                color: const Color(0xFFF75270),
                onTap: () => _setKind(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KindButton(
                label: 'Pemasukan',
                selected: !isExpense,
                color: const Color(0xFF5D9E85),
                onTap: () => _setKind(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _label('Jumlah'),
        _box(TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'Rp ', border: InputBorder.none),
        )),
        const SizedBox(height: 16),
        _label('Catatan'),
        _box(TextField(controller: noteController, decoration: const InputDecoration(border: InputBorder.none))),
        const SizedBox(height: 16),
        _label('Tanggal'),
        InkWell(
          onTap: _selectDate,
          child: _box(Text(DateFormat('dd/MM/yyyy   HH:mm', 'id_ID').format(selectedDate))),
        ),
        const SizedBox(height: 16),
        _label('Kategori'),
        _box(DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            value: categories.any((c) => c.id == selectedCategoryId) ? selectedCategoryId : null,
            hint: const Text('Pilih kategori'),
            items: categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => selectedCategoryId = v),
          ),
        )),
        const SizedBox(height: 16),
        _label('Dompet'),
        _wallets.isEmpty
            ? OutlinedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddWalletScreen()),
                  );
                  final wallets = await _apiService.getWalletsList(
                    token: (await SharedPreferences.getInstance()).getString('authToken') ?? '',
                  );
                  setState(() {
                    _wallets = wallets;
                    selectedWalletId = wallets.isNotEmpty ? wallets.first.id : null;
                  });
                },
                child: const Text('Kamu belum punya dompet — ketuk untuk menambah'),
              )
            : _box(DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: selectedWalletId,
                  items: _wallets
                      .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedWalletId = v),
                ),
              )),
        const SizedBox(height: 16),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Lihat teks hasil pemindaian', style: TextStyle(fontSize: 13)),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_rawText, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _step = _Step.pick),
          icon: const Icon(Icons.image_outlined, size: 18),
          label: const Text('Ganti Screenshot'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5D9E85),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Simpan Transaksi'),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      );

  Widget _box(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: child,
      );
}

class _KindButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _KindButton({
    required this.label, required this.selected, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : const Color(0xFF374151), fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  final Widget child;
  final String message;
  const _CenterMessage({required this.child, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child,
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
