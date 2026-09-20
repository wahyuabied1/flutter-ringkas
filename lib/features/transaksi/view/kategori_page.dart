import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api_service.dart';
import '../../../data/model/category_model.dart';
import 'kategori_settings_page.dart';

class KategoriPage extends StatefulWidget {
  final bool isExpense; // true = Pengeluaran, false = Pendapatan

  const KategoriPage({super.key, this.isExpense = true});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final ApiService _apiService = ApiService();
  List<Category> categories = [];
  List<Category> filteredCategories = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';
  bool _isSearching = false;
  late TextEditingController _searchController;

  bool get isExpense => widget.isExpense;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Ambil token dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final categoryList = await _apiService.getCategories(token: token);

      // Filter berdasarkan kind (income/expense)
      final filteredByKind = categoryList.where((category) {
        if (isExpense) {
          return category.kind == CategoryKind.expense;
        } else {
          return category.kind == CategoryKind.income;
        }
      }).toList();

      setState(() {
        categories = filteredByKind;
        filteredCategories = filteredByKind;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _filterCategories(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredCategories = categories;
      } else {
        filteredCategories = categories
            .where(
              (category) =>
                  category.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  IconData _getIconFromString(String? iconName) {
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
    };

    return iconMap[iconName.toLowerCase()] ?? Icons.category;
  }

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return const Color(0xFF5D9E85); // Default color
    }

    try {
      // Hapus '#' jika ada
      String hex = hexColor.replaceFirst('#', '');

      // Jika hanya 6 karakter, tambah FF di depan untuk alpha
      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      // Parse hex string menjadi Color
      return Color(int.parse('0x$hex'));
    } catch (e) {
      return const Color(0xFF5D9E85); // Default jika parse gagal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    searchQuery = '';
                    filteredCategories = categories;
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
                onPressed: () => Navigator.pop(context),
              ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _filterCategories,
                decoration: InputDecoration(
                  hintText: 'Cari kategori...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(color: Color(0xFF374151)),
              )
            : const Text(
                "Pilih Kategori",
                style: TextStyle(color: Color(0xFF374151)),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF374151)),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF374151)),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  searchQuery = '';
                  filteredCategories = categories;
                });
              },
            ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.settings, color: Color(0xFF374151)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KategoriSettingsPage(),
                  ),
                ).then((_) {
                  // Reload categories when returning from settings
                  _loadCategories();
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
                    onPressed: _loadCategories,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : filteredCategories.isEmpty
          ? Center(
              child: Text(
                searchQuery.isEmpty
                    ? 'Tidak ada kategori'
                    : 'Tidak ada kategori yang cocok',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final category = filteredCategories[index];
                final categoryName = category.name;
                final iconName = category.icon;
                final categoryColor = category.colorHex;

                return GestureDetector(
                  onTap: () {
                    // Return kategori yang dipilih ke add_transaction_screen (format: Nama - id)
                    final categoryId = category.id;
                    Navigator.pop(context, '$categoryName - $categoryId');
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
                            color: _getColorFromHex(categoryColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _getIconFromString(iconName),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Nama kategori
                        Expanded(
                          child: Text(
                            categoryName,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w500,
                            ),
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
                            borderRadius: BorderRadius.circular(6),
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
