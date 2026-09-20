import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api_service.dart';
import '../../../data/model/category_model.dart';
import 'add_transaction_screen.dart';

class DetailTransactionScreen extends StatefulWidget {
  final dynamic transactionId;
  final String? token;

  const DetailTransactionScreen({
    super.key,
    required this.transactionId,
    this.token,
  });

  @override
  State<DetailTransactionScreen> createState() =>
      _DetailTransactionScreenState();
}

class _DetailTransactionScreenState extends State<DetailTransactionScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? transactionDetail;
  String categoryKind = 'expense'; // Simpan kind dari kategori
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactionDetail();
  }

  Future<void> _loadTransactionDetail() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get token from SharedPreferences if not provided
      String token = widget.token ?? '';
      if (token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('authToken') ?? '';
      }

      if (token.isEmpty) {
        setState(() {
          errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
          isLoading = false;
        });
        return;
      }

      final detail = await _apiService.getTransactionById(
        token: token,
        id: widget.transactionId,
      );

      // Fetch kategori kind dari API
      final kind = await _determineCategoryKind(detail['category_id']);

      setState(() {
        transactionDetail = detail;
        categoryKind = kind;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat detail transaksi: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    try {
      double value = 0;
      if (amount is String) {
        value = double.tryParse(amount) ?? 0;
      } else if (amount is num) {
        value = amount.toDouble();
      }
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(value);
    } catch (e) {
      return 'Rp 0';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('HH:mm', 'id_ID').format(date);
    } catch (e) {
      return '-';
    }
  }

  /// Determine kategori kind berdasarkan category_id dengan fetch dari API
  Future<String> _determineCategoryKind(dynamic categoryId) async {
    try {
      if (categoryId == null) return 'expense';

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) return 'expense';

      final categories = await _apiService.getCategories(token: token);

      Category? category;
      for (var cat in categories) {
        if (cat.id.toString() == categoryId.toString()) {
          category = cat;
          break;
        }
      }

      if (category != null) {
        return category.kind == CategoryKind.income ? 'income' : 'expense';
      }

      return 'expense';
    } catch (e) {
      return 'expense'; // Default ke expense jika error
    }
  }

  Color _getCategoryColor(String? kind) {
    final categoryKind = kind?.toString().toLowerCase() ?? 'expense';
    if (categoryKind == 'income') {
      return const Color(0xFF5D9E85);
    }
    return const Color(0xFFF75270);
  }

  IconData _getCategoryIcon(String? kind) {
    final categoryKind = kind?.toString().toLowerCase() ?? 'expense';
    if (categoryKind == 'income') {
      return Icons.arrow_downward;
    }
    return Icons.arrow_upward;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            'Detail Transaksi',
            style: TextStyle(color: Color(0xFF374151)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF5D9E85)),
              )
            : errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Color(0xFFF75270),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadTransactionDetail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D9E85),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : transactionDetail == null
            ? const Center(
                child: Text(
                  'Data transaksi tidak ditemukan',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header dengan Icon dan Amount
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
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
                      child: Column(
                        children: [
                          // Icon Container
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(
                                categoryKind,
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Icon(
                              _getCategoryIcon(categoryKind),
                              size: 40,
                              color: _getCategoryColor(categoryKind),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Amount
                          Text(
                            _formatCurrency(transactionDetail?['amount']),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: _getCategoryColor(categoryKind),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Note/Description
                          Text(
                            transactionDetail?['note'] ??
                                'Transaksi Tanpa Keterangan',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Detail Information
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Transaksi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Kategori
                          _buildDetailRow(
                            label: 'Kategori',
                            value:
                                transactionDetail?['kategori_name'] ??
                                transactionDetail?['category']?['name'] ??
                                'Kategori Tidak Diketahui',
                          ),
                          const SizedBox(height: 12),
                          // Dompet
                          _buildDetailRow(
                            label: 'Dompet',
                            value:
                                transactionDetail?['dompet_name'] ??
                                transactionDetail?['wallet']?['name'] ??
                                'Dompet Tidak Diketahui',
                          ),
                          const SizedBox(height: 12),
                          // Tanggal dan Waktu dari updated_at
                          _buildDetailRow(
                            label: 'Tanggal & Waktu',
                            value:
                                '${_formatDate(transactionDetail?['trx_date'])} ${_formatTime(transactionDetail?['updated_at'])}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to edit screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddTransactionScreen(
                                    transactionId: widget.transactionId,
                                    transactionData: transactionDetail,
                                  ),
                                ),
                              ).then((result) {
                                // Refresh dan pop jika transaksi diubah
                                if (result == true) {
                                  _loadTransactionDetail().then((_) {
                                    // After detail reload, pop back to transaction list with true
                                    Navigator.pop(context, true);
                                  });
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5D9E85),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _showDeleteConfirmation();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF75270),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Hapus',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Hapus Transaksi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus transaksi ini? Tindakan ini tidak dapat dibatalkan.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF5D9E85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteTransaction();
              },
              child: const Text(
                'Hapus',
                style: TextStyle(
                  color: Color(0xFFF75270),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction() async {
    try {
      String token = '';
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token tidak ditemukan. Silakan login kembali.'),
            ),
          );
        }
        return;
      }

      await _apiService.deleteTransaction(
        token: token,
        id: widget.transactionId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus transaksi: ${e.toString()}')),
        );
      }
    }
  }
}
