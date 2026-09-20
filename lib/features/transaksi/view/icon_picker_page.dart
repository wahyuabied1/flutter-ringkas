import 'package:flutter/material.dart';

class IconPickerPage extends StatefulWidget {
  final String initialIcon;

  const IconPickerPage({super.key, required this.initialIcon});

  @override
  State<IconPickerPage> createState() => _IconPickerPageState();
}

class _IconPickerPageState extends State<IconPickerPage> {
  late String selectedIcon;
  TextEditingController searchController = TextEditingController();
  late List<Map<String, dynamic>> filteredIcons;

  // Extended list of available icons
  final List<Map<String, dynamic>> availableIcons = [
    {
      'name': 'Shopping Bag',
      'value': 'shopping_bag',
      'icon': Icons.shopping_bag,
    },
    {
      'name': 'Shopping Cart',
      'value': 'shopping_cart',
      'icon': Icons.shopping_cart,
    },
    {'name': 'School', 'value': 'school', 'icon': Icons.school},
    {'name': 'Restaurant', 'value': 'restaurant', 'icon': Icons.restaurant},
    {'name': 'Fast Food', 'value': 'fastfood', 'icon': Icons.fastfood},
    {'name': 'Coffee', 'value': 'coffee', 'icon': Icons.coffee},
    {'name': 'Gift', 'value': 'card_giftcard', 'icon': Icons.card_giftcard},
    {'name': 'Taxi', 'value': 'local_taxi', 'icon': Icons.local_taxi},
    {'name': 'Car', 'value': 'directions_car', 'icon': Icons.directions_car},
    {'name': 'Bike', 'value': 'two_wheeler', 'icon': Icons.two_wheeler},
    {'name': 'Plane', 'value': 'flight', 'icon': Icons.flight},
    {'name': 'Bus', 'value': 'directions_bus', 'icon': Icons.directions_bus},
    {'name': 'Clothes', 'value': 'checkroom', 'icon': Icons.checkroom},
    {'name': 'Game', 'value': 'videogame_asset', 'icon': Icons.videogame_asset},
    {'name': 'Movie', 'value': 'movie', 'icon': Icons.movie},
    {'name': 'Music', 'value': 'music_note', 'icon': Icons.music_note},
    {'name': 'Money', 'value': 'attach_money', 'icon': Icons.attach_money},
    {'name': 'Wallet', 'value': 'wallet', 'icon': Icons.wallet},
    {'name': 'Credit Card', 'value': 'credit_card', 'icon': Icons.credit_card},
    {'name': 'Laptop', 'value': 'laptop', 'icon': Icons.laptop},
    {'name': 'Phone', 'value': 'phone_iphone', 'icon': Icons.phone_iphone},
    {'name': 'Headphones', 'value': 'headphones', 'icon': Icons.headphones},
    {'name': 'Camera', 'value': 'camera_alt', 'icon': Icons.camera_alt},
    {
      'name': 'Hospital',
      'value': 'local_hospital',
      'icon': Icons.local_hospital,
    },
    {
      'name': 'Pharmacy',
      'value': 'local_pharmacy',
      'icon': Icons.local_pharmacy,
    },
    {
      'name': 'Fitness',
      'value': 'fitness_center',
      'icon': Icons.fitness_center,
    },
    {'name': 'Trending Up', 'value': 'trending_up', 'icon': Icons.trending_up},
    {
      'name': 'Trending Down',
      'value': 'trending_down',
      'icon': Icons.trending_down,
    },
    {'name': 'Home', 'value': 'home', 'icon': Icons.home},
    {'name': 'Work', 'value': 'work', 'icon': Icons.work},
    {'name': 'Savings', 'value': 'savings', 'icon': Icons.savings},
    {'name': 'Investment', 'value': 'trending_up', 'icon': Icons.show_chart},
    {'name': 'Loan', 'value': 'payments', 'icon': Icons.payments},
    {'name': 'Utilities', 'value': 'bolt', 'icon': Icons.bolt},
    {'name': 'Water', 'value': 'water_drop', 'icon': Icons.water_drop},
    {'name': 'Pets', 'value': 'pets', 'icon': Icons.pets},
    {'name': 'Holiday', 'value': 'beach_access', 'icon': Icons.beach_access},
    {'name': 'Book', 'value': 'book', 'icon': Icons.book},
    {
      'name': 'Gift Card',
      'value': 'card_giftcard',
      'icon': Icons.card_giftcard,
    },
    {'name': 'More', 'value': 'more_horiz', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    selectedIcon = widget.initialIcon;
    filteredIcons = availableIcons;
    searchController.addListener(_filterIcons);
  }

  void _filterIcons() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredIcons = availableIcons
          .where((icon) => icon['name'].toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pilih Ikon',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari ikon...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                suffixIcon: searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          searchController.clear();
                          _filterIcons();
                        },
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF9CA3AF),
                        ),
                      )
                    : null,
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
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
          ),
          // Icon grid
          Expanded(
            child: filteredIcons.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ikon tidak ditemukan',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: filteredIcons.length,
                    itemBuilder: (context, index) {
                      final icon = filteredIcons[index];
                      final isSelected = selectedIcon == icon['value'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIcon = icon['value'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5D9E85).withOpacity(0.1)
                                : const Color(0xFFF9FAFB),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF5D9E85)
                                  : const Color(0xFFE5E7EB),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon['icon'],
                                size: 32,
                                color: isSelected
                                    ? const Color(0xFF5D9E85)
                                    : const Color(0xFF6B7280),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  icon['name'],
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF5D9E85)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Submit button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, selectedIcon);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D9E85),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Pilih Ikon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
