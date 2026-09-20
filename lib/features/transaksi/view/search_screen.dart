import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../../../data/services/api_service.dart';
import '../../../data/model/category_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String userName = "User";
  double balance = 0;
  bool isLoading = false;
  final ApiService _apiService = ApiService();

  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  List<Map<String, dynamic>> searchResults = [];
  Map<int, Category> categoriesMap = {};
  Map<int, Map<String, dynamic>> walletsMap = {};
  List<Category> categories = [];
  List<Map<String, dynamic>> wallets = [];

  // Filter variables
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  int? selectedCategoryId;
  int? selectedWalletId;
  List<int> selectedCategoryIds = [];
  List<int> selectedWalletIds = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('name') ?? '';

      setState(() {
        userName = cachedName.isNotEmpty ? cachedName : "User";
        balance = prefs.getDouble('initialBalance') ?? 0;
      });

      final token = prefs.getString('authToken') ?? '';
      if (token.isEmpty) {
        return;
      }

      // Fetch categories
      final categoriesList = await _apiService.getCategories(token: token);

      final categoryMap = <int, Category>{};
      for (var category in categoriesList) {
        categoryMap[category.id] = category;
      }

      // Fetch wallets
      final walletResponse = await _apiService.getWallets(token: token);
      final walletsList = walletResponse['data'] as List? ?? [];

      final walletMap = <int, Map<String, dynamic>>{};
      for (var wallet in walletsList) {
        final walletData = wallet is Map<String, dynamic>
            ? wallet
            : (wallet as Map).cast<String, dynamic>();
        final id = walletData['id'] is String
            ? int.tryParse(walletData['id'] as String)
            : walletData['id'] as int?;
        if (id != null) {
          walletMap[id] = walletData;
        }
      }

      setState(() {
        categoriesMap = categoryMap;
        walletsMap = walletMap;
        categories = categoriesList;
        wallets = List<Map<String, dynamic>>.from(
          walletsList.map(
            (w) => w is Map<String, dynamic>
                ? w
                : (w as Map).cast<String, dynamic>(),
          ),
        );
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _performSearch(String query) async {
    // If all filters are empty, clear results
    if (query.isEmpty &&
        selectedCategoryIds.isEmpty &&
        selectedWalletIds.isEmpty &&
        selectedStartDate == null &&
        selectedEndDate == null) {
      setState(() {
        searchResults = [];
        searchQuery = "";
      });
      return;
    }

    setState(() {
      searchQuery = query;
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final results = await _apiService.getTransactionsWithFilters(
        token: token,
        search: query.isNotEmpty ? query : null,
        startDate: selectedStartDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedStartDate!)
            : null,
        endDate: selectedEndDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedEndDate!)
            : null,
        categoryIds: selectedCategoryIds.isNotEmpty
            ? selectedCategoryIds
            : null,
        dompetIds: selectedWalletIds.isNotEmpty ? selectedWalletIds : null,
      );

      print(
        'API Call - Search: $query, Dompet: $selectedWalletIds, Category: $selectedCategoryIds, Results: ${results.length}',
      );

      setState(() {
        searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDateFilterBottomSheet(BuildContext context) {
    DateTime? tempStartDate = selectedStartDate;
    DateTime? tempEndDate = selectedEndDate;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Pilih Tanggal",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tanggal Mulai
                  GestureDetector(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: tempStartDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setModalState(() {
                          tempStartDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tanggal Mulai",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tempStartDate != null
                                    ? DateFormat(
                                        'dd MMM yyyy',
                                        'id_ID',
                                      ).format(tempStartDate!)
                                    : "Pilih tanggal",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.calendar_today,
                            color: tempStartDate != null
                                ? const Color(0xFF5D9E85)
                                : const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tanggal Akhir
                  GestureDetector(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: tempEndDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setModalState(() {
                          tempEndDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tanggal Akhir",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tempEndDate != null
                                    ? DateFormat(
                                        'dd MMM yyyy',
                                        'id_ID',
                                      ).format(tempEndDate!)
                                    : "Pilih tanggal",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.calendar_today,
                            color: tempEndDate != null
                                ? const Color(0xFF5D9E85)
                                : const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "Batal",
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedStartDate = tempStartDate;
                              selectedEndDate = tempEndDate;
                            });
                            Navigator.pop(context);
                            _performSearch(searchQuery);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D9E85),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Terapkan",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoryFilter(BuildContext context) {
    // Ensure categories are loaded
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sedang memuat kategori..."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    List<int> tempSelectedIds = List.from(selectedCategoryIds);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Pilih Kategori",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Semua Kategori option
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        border: const Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Category list with checkboxes
                    ...categories.map((category) {
                      final id = category.id;
                      final name = category.name;
                      final iconStr = category.icon ?? 'shopping_bag';
                      final colorHex = category.colorHex ?? '#5D9E85';

                      IconData iconData = _iconFromString(iconStr);
                      Color categoryColor = _colorFromHex(colorHex);

                      final isSelected = tempSelectedIds.contains(id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF0F9F7)
                              : const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF5D9E85)
                                : const Color(0xFFE5E7EB),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked ?? false) {
                                if (!tempSelectedIds.contains(id)) {
                                  tempSelectedIds.add(id);
                                }
                              } else {
                                tempSelectedIds.remove(id);
                              }
                            });
                          },
                          activeColor: const Color(0xFF5D9E85),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  iconData,
                                  color: categoryColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategoryIds = tempSelectedIds;
                    });
                    Navigator.pop(context);
                    _performSearch(searchQuery);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D9E85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Terapkan",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showWalletFilter(BuildContext context) {
    // Ensure wallets are loaded
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sedang memuat dompet..."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    List<int> tempSelectedIds = List.from(selectedWalletIds);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Pilih Dompet",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Semua Dompet option
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        border: Border(
                          bottom: BorderSide(color: const Color(0xFFE5E7EB)),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Wallet list with checkboxes
                    ...wallets.map((wallet) {
                      final id = wallet['id'] is String
                          ? int.tryParse(wallet['id'] as String)
                          : wallet['id'] as int?;
                      final name = wallet['name']?.toString() ?? 'Dompet';

                      if (id == null) {
                        return const SizedBox.shrink();
                      }

                      final isSelected = tempSelectedIds.contains(id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF0F9F7)
                              : const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF5D9E85)
                                : const Color(0xFFE5E7EB),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked ?? false) {
                                if (!tempSelectedIds.contains(id)) {
                                  tempSelectedIds.add(id);
                                }
                              } else {
                                tempSelectedIds.remove(id);
                              }
                            });
                          },
                          activeColor: const Color(0xFF5D9E85),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF5D9E85,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Color(0xFF5D9E85),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedWalletIds = tempSelectedIds;
                    });
                    Navigator.pop(context);
                    _performSearch(searchQuery);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D9E85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Terapkan",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupResultsByDate() {
    final groupedMap = <String, List<Map<String, dynamic>>>{};

    for (var transaction in searchResults) {
      final dateStr = transaction['trx_date'] as String?;
      if (dateStr == null) continue;

      try {
        final txDate = DateTime.parse(dateStr);
        final dateKey = DateFormat('dd MMM yyyy', 'id_ID').format(txDate);

        if (!groupedMap.containsKey(dateKey)) {
          groupedMap[dateKey] = [];
        }
        groupedMap[dateKey]!.add(transaction);
      } catch (e) {
        // Ignore parse errors
      }
    }

    // Sort dates in descending order
    final sortedKeys = groupedMap.keys.toList();
    sortedKeys.sort((a, b) {
      final dateA = DateFormat('dd MMM yyyy', 'id_ID').parse(a);
      final dateB = DateFormat('dd MMM yyyy', 'id_ID').parse(b);
      return dateB.compareTo(dateA);
    });

    final sortedMap = <String, List<Map<String, dynamic>>>{};
    for (var key in sortedKeys) {
      sortedMap[key] = groupedMap[key]!;
    }

    return sortedMap;
  }

  Color _getColorFromCategory(Category? category) {
    if (category == null) return const Color(0xFF6B7280);

    final colorStr = category.colorHex;
    if (colorStr == null) return const Color(0xFF6B7280);

    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xff')));
    } catch (e) {
      return const Color(0xFF6B7280);
    }
  }

  IconData _getIconFromCategory(Category? category) {
    if (category == null) return Icons.attach_money;

    final iconStr = category.icon?.toLowerCase() ?? 'attach_money';

    switch (iconStr) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'school':
        return Icons.school;
      case 'favorite':
        return Icons.favorite;
      case 'trending_up':
        return Icons.trending_up;
      case 'work':
        return Icons.work;
      case 'home':
        return Icons.home;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'videogame_asset':
        return Icons.videogame_asset;
      case 'attach_money':
        return Icons.attach_money;
      case 'laptop':
        return Icons.laptop;
      case 'checkroom':
        return Icons.checkroom;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.attach_money;
    }
  }

  IconData _iconFromString(String iconStr) {
    switch (iconStr.toLowerCase()) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'school':
        return Icons.school;
      case 'favorite':
        return Icons.favorite;
      case 'trending_up':
        return Icons.trending_up;
      case 'work':
        return Icons.work;
      case 'home':
        return Icons.home;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'videogame_asset':
        return Icons.videogame_asset;
      case 'attach_money':
        return Icons.attach_money;
      case 'laptop':
        return Icons.laptop;
      case 'checkroom':
        return Icons.checkroom;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.attach_money;
    }
  }

  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");

    // If color includes alpha (8 chars), use as is
    // If color is just RGB (6 chars), add FF for full opacity
    if (hexColor.length == 8) {
      // Already has alpha channel
      return Color(int.parse("0x$hexColor"));
    } else if (hexColor.length == 6) {
      // Add full opacity alpha channel
      return Color(int.parse("0xFF$hexColor"));
    } else {
      // Invalid color, return default
      return const Color(0xFF5D9E85);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedResults = _groupResultsByDate();

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
          "Cari Transaksi",
          style: TextStyle(color: Color(0xFF374151)),
        ),
      ),
      body: Column(
        children: [
          // SEARCH BOX
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: "Cari transaksi...",
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF9CA3AF)),
                        onPressed: () {
                          searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
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
                  borderSide: const BorderSide(color: Color(0xFF5D9E85)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // FILTER BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tanggal Button
                  OutlinedButton.icon(
                    onPressed: () => _showDateFilterBottomSheet(context),
                    icon: (selectedStartDate != null || selectedEndDate != null)
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedStartDate = null;
                                selectedEndDate = null;
                              });
                              _performSearch(searchQuery);
                            },
                            child: const Icon(Icons.close, size: 16),
                          )
                        : const SizedBox.shrink(),
                    label: const Text(
                      "Tanggal",
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor:
                          (selectedStartDate != null || selectedEndDate != null)
                          ? const Color(0xFF5D9E85)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Kategori Button
                  OutlinedButton.icon(
                    onPressed: () => _showCategoryFilter(context),
                    icon: selectedCategoryIds.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategoryIds = [];
                              });
                              _performSearch(searchQuery);
                            },
                            child: const Icon(Icons.close, size: 16),
                          )
                        : const SizedBox.shrink(),
                    label: Text(
                      selectedCategoryIds.isEmpty
                          ? "Kategori"
                          : "(${selectedCategoryIds.length}) Kategori",
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: selectedCategoryIds.isNotEmpty
                          ? const Color(0xFF5D9E85)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dompet Button
                  OutlinedButton.icon(
                    onPressed: () => _showWalletFilter(context),
                    icon: selectedWalletIds.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedWalletIds = [];
                              });
                              _performSearch(searchQuery);
                            },
                            child: const Icon(Icons.close, size: 16),
                          )
                        : const SizedBox.shrink(),
                    label: Text(
                      selectedWalletIds.isEmpty
                          ? "Dompet"
                          : "(${selectedWalletIds.length}) Dompet",
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: selectedWalletIds.isNotEmpty
                          ? const Color(0xFF5D9E85)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // SEARCH RESULTS
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
                          "Mencari...",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : (searchQuery.isEmpty &&
                      selectedCategoryIds.isEmpty &&
                      selectedWalletIds.isEmpty &&
                      selectedStartDate == null &&
                      selectedEndDate == null)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 48,
                            color: const Color(0xFFD1D5DB),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Ketik untuk mencari transaksi",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : searchResults.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Tidak ada transaksi yang cocok dengan pencarian \"$searchQuery\"",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...groupedResults.entries.map((entry) {
                          final dateKey = entry.key;
                          final txList = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  dateKey,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              // Transactions for this date
                              ...txList.map((transaction) {
                                final amount = transaction['amount'] ?? '0';
                                final note = transaction['note'] ?? 'Transaksi';

                                // Get wallet info
                                final walletId =
                                    transaction['dompet_id'] is String
                                    ? int.tryParse(
                                        transaction['dompet_id'] as String,
                                      )
                                    : transaction['dompet_id'] as int?;
                                final wallet = walletId != null
                                    ? walletsMap[walletId]
                                    : null;
                                final walletName =
                                    wallet?['name']?.toString() ?? 'Dompet';

                                // Get category info
                                final categoryId =
                                    transaction['category_id'] is String
                                    ? int.tryParse(
                                        transaction['category_id'] as String,
                                      )
                                    : transaction['category_id'] as int?;
                                final category = categoryId != null
                                    ? categoriesMap[categoryId]
                                    : null;
                                final isIncome =
                                    category?.kind == CategoryKind.income;

                                final amountDouble = amount is String
                                    ? double.tryParse(amount) ?? 0
                                    : (amount is num ? amount.toDouble() : 0);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Category Icon
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _getColorFromCategory(
                                            category,
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Icon(
                                          _getIconFromCategory(category),
                                          size: 20,
                                          color: _getColorFromCategory(
                                            category,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Transaction Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              note,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              walletName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Amount
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "${isIncome ? '+' : '-'}Rp ${amountDouble.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isIncome
                                                  ? const Color(0xFF5D9E85)
                                                  : const Color(0xFFF75270),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
