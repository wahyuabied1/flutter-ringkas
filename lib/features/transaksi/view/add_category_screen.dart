import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api_service.dart';
import 'color_picker_page.dart';
import 'icon_picker_page.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final categoryNameController = TextEditingController();
  final ApiService _apiService = ApiService();

  String selectedKind = 'expense'; // Default ke expense
  String selectedColor = '#5D9E85'; // Default color
  String selectedIcon = 'shopping_bag'; // Default icon
  bool isLoading = false;

  @override
  void dispose() {
    categoryNameController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.startsWith('#')) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _getIconData(String iconValue) {
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
    return iconMap[iconValue] ?? Icons.category;
  }

  String _getIconName(String iconValue) {
    final nameMap = {
      'shopping_bag': 'Shopping Bag',
      'shopping_cart': 'Shopping Cart',
      'school': 'School',
      'restaurant': 'Restaurant',
      'fastfood': 'Fast Food',
      'coffee': 'Coffee',
      'card_giftcard': 'Gift',
      'local_taxi': 'Taxi',
      'directions_car': 'Car',
      'two_wheeler': 'Bike',
      'flight': 'Plane',
      'directions_bus': 'Bus',
      'checkroom': 'Clothes',
      'videogame_asset': 'Game',
      'movie': 'Movie',
      'music_note': 'Music',
      'attach_money': 'Money',
      'wallet': 'Wallet',
      'credit_card': 'Credit Card',
      'laptop': 'Laptop',
      'phone_iphone': 'Phone',
      'headphones': 'Headphones',
      'camera_alt': 'Camera',
      'local_hospital': 'Hospital',
      'local_pharmacy': 'Pharmacy',
      'fitness_center': 'Fitness',
      'trending_up': 'Trending Up',
      'trending_down': 'Trending Down',
      'home': 'Home',
      'work': 'Work',
      'savings': 'Savings',
      'show_chart': 'Investment',
      'payments': 'Loan',
      'bolt': 'Utilities',
      'water_drop': 'Water',
      'pets': 'Pets',
      'beach_access': 'Holiday',
      'book': 'Book',
      'more_horiz': 'More',
    };
    return nameMap[iconValue] ?? 'Icon';
  }

  Future<void> _submitCategory() async {
    if (categoryNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kategori tidak boleh kosong')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final userIdStr = prefs.getString('userId');

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      // userId tidak wajib: server menentukan pemilik kategori dari token
      final userId = int.tryParse(userIdStr ?? '');

      // Call API to create category
      await _apiService.createCategory(
        userId: userId,
        name: categoryNameController.text,
        kind: selectedKind,
        colorHex: selectedColor,
        icon: selectedIcon,
        token: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil ditambahkan'),
            backgroundColor: Color(0xFF5D9E85),
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
          'Tambah Kategori',
          style: TextStyle(color: Color(0xFF374151)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama Kategori
            const Text(
              'Nama Kategori',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: categoryNameController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama kategori',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF5D9E85),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Jenis Kategori
            const Text(
              'Jenis Kategori',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedKind = 'income'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedKind == 'income'
                            ? const Color(0xFF5D9E85)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedKind == 'income'
                              ? const Color(0xFF5D9E85)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        'Pendapatan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selectedKind == 'income'
                              ? Colors.white
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedKind = 'expense'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedKind == 'expense'
                            ? const Color(0xFFF75270)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedKind == 'expense'
                              ? const Color(0xFFF75270)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        'Pengeluaran',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selectedKind == 'expense'
                              ? Colors.white
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pilih Warna
            const Text(
              'Pilih Warna',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ColorPickerPage(initialColor: selectedColor),
                  ),
                );
                if (result != null) {
                  setState(() => selectedColor = result);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _hexToColor(selectedColor),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _hexToColor(selectedColor).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Warna Terpilih',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedColor.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pilih Icon
            const Text(
              'Pilih Icon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        IconPickerPage(initialIcon: selectedIcon),
                  ),
                );
                if (result != null) {
                  setState(() => selectedIcon = result);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _hexToColor(selectedColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconData(selectedIcon),
                        color: _hexToColor(selectedColor),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Icon Terpilih',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getIconName(selectedIcon),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _hexToColor(selectedColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconData(selectedIcon),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryNameController.text.isEmpty
                                ? 'Nama Kategori'
                                : categoryNameController.text,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedKind == 'income'
                                ? 'Pendapatan'
                                : 'Pengeluaran',
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedKind == 'income'
                                  ? const Color(0xFF5D9E85)
                                  : const Color(0xFFF75270),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D9E85),
                  disabledBackgroundColor: const Color(0xFFD1D5DB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Tambah Kategori',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
