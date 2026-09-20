import 'package:flutter/material.dart';

class ColorPickerPage extends StatefulWidget {
  final String initialColor;

  const ColorPickerPage({super.key, required this.initialColor});

  @override
  State<ColorPickerPage> createState() => _ColorPickerPageState();
}

class _ColorPickerPageState extends State<ColorPickerPage> {
  late String selectedColor;

  // Extended list of available colors
  final List<Map<String, dynamic>> availableColors = [
    // Primary Colors
    {'name': 'Red', 'hex': '#EF4444'},
    {'name': 'Orange', 'hex': '#F97316'},
    {'name': 'Amber', 'hex': '#F59E0B'},
    {'name': 'Yellow', 'hex': '#FBBF24'},
    {'name': 'Lime', 'hex': '#84CC16'},
    {'name': 'Green', 'hex': '#5D9E85'},
    {'name': 'Emerald', 'hex': '#10B981'},
    {'name': 'Teal', 'hex': '#14B8A6'},
    {'name': 'Cyan', 'hex': '#06B6D4'},
    {'name': 'Sky', 'hex': '#0EA5E9'},
    {'name': 'Blue', 'hex': '#3B82F6'},
    {'name': 'Indigo', 'hex': '#6366F1'},
    {'name': 'Violet', 'hex': '#8B5CF6'},
    {'name': 'Purple', 'hex': '#A855F7'},
    {'name': 'Fuchsia', 'hex': '#D946EF'},
    {'name': 'Pink', 'hex': '#EC4899'},
    {'name': 'Rose', 'hex': '#F43F5E'},
    {'name': 'Slate', 'hex': '#64748B'},
    {'name': 'Gray', 'hex': '#6B7280'},
    {'name': 'Zinc', 'hex': '#71717A'},
    {'name': 'Neutral', 'hex': '#737373'},
    {'name': 'Stone', 'hex': '#78716C'},
    // Additional shades
    {'name': 'Dark Red', 'hex': '#DC2626'},
    {'name': 'Dark Orange', 'hex': '#EA580C'},
    {'name': 'Dark Green', 'hex': '#16A34A'},
    {'name': 'Dark Blue', 'hex': '#1D4ED8'},
    {'name': 'Dark Purple', 'hex': '#7C3AED'},
    {'name': 'Light Pink', 'hex': '#FBCFE8'},
    {'name': 'Light Blue', 'hex': '#BFDBFE'},
    {'name': 'Light Green', 'hex': '#BBCF63'},
  ];

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  Color _hexToColor(String hexString) {
    String cleanHex = hexString.replaceFirst('#', '').toUpperCase();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    return Color(int.parse(cleanHex, radix: 16));
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
          'Pilih Warna',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview Warna',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _hexToColor(selectedColor),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _hexToColor(
                                selectedColor,
                              ).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        selectedColor.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Color grid
              const Text(
                'Pilihan Warna',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: availableColors.length,
                itemBuilder: (context, index) {
                  final color = availableColors[index];
                  final isSelected = selectedColor == color['hex'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color['hex'];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _hexToColor(color['hex']),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF111827)
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _hexToColor(color['hex']).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.check,
                                  color: Color(0xFF111827),
                                  size: 16,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, selectedColor);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D9E85),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Pilih Warna',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
