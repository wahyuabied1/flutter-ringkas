import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api_service.dart';
import '../../../data/model/category_model.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class KategoriSettingsPage extends StatefulWidget {
  const KategoriSettingsPage({super.key});

  @override
  State<KategoriSettingsPage> createState() => _KategoriSettingsPageState();
}

class _KategoriSettingsPageState extends State<KategoriSettingsPage> {
  final ApiService _apiService = ApiService();
  List<Category> categories = [];
  List<Category> filteredCategories = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';
  bool _isSearching = false;
  late TextEditingController _searchController;

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

      setState(() {
        categories = categoryList;
        filteredCategories = categoryList;
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

  Future<void> _deleteCategory(Category category) async {
    try {
      // Check if it's a default category (user_id == null or 0)
      if (category.userId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori default tidak bisa dihapus')),
        );
        return;
      }

      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hapus Kategori'),
          content: Text(
            'Apakah Anda yakin ingin menghapus kategori "${category.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldDelete != true) return;

      // Call API to delete category
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      await _apiService.deleteCategory(categoryId: category.id, token: token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil dihapus'),
            backgroundColor: Color(0xFF5D9E85),
          ),
        );
        _loadCategories();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _editCategory(Category category) {
    // Check if it's a default category (user_id == null or 0)
    if (category.userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori default tidak bisa diubah')),
      );
      return;
    }
    // Navigate to edit category screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCategoryScreen(category: category),
      ),
    ).then((result) {
      if (result == true) {
        _loadCategories(); // Refresh jika ada perubahan
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
        leading: IconButton(
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
                "Pengaturan Kategori",
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
              icon: const Icon(Icons.add, color: Color(0xFF374151)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCategoryScreen(),
                  ),
                ).then((result) {
                  if (result == true) {
                    _loadCategories(); // Refresh categories if new one was added
                  }
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
                final kindLabel = category.kind == CategoryKind.income
                    ? 'Pendapatan'
                    : 'Pengeluaran';

                return Container(
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
                      // Nama kategori dan kind
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF374151),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (category.userId == 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDEEF1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Default',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              kindLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: category.kind == CategoryKind.income
                                    ? const Color(0xFF5D9E85)
                                    : const Color(0xFFF75270),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action buttons
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: category.userId == 0
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF6B7280),
                          size: 20,
                        ),
                        onPressed: category.userId == 0
                            ? null
                            : () => _editCategory(category),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: category.userId == 0
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFFF75270),
                          size: 20,
                        ),
                        onPressed: category.userId == 0
                            ? null
                            : () => _deleteCategory(category),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
