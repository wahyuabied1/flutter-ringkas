enum CategoryKind { income, expense }

class Category {
  final int id;
  final int userId;
  final int? parentId;
  final String name;
  final CategoryKind kind;
  final String? colorHex;
  final String? icon;

  Category({
    required this.id,
    required this.userId,
    this.parentId,
    required this.name,
    required this.kind,
    this.colorHex,
    this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Parse id - handle string or int from API
    final id = json['id'] is String
        ? int.tryParse(json['id'] as String) ?? 0
        : (json['id'] as int?) ?? 0;

    // Parse userId - handle string or int from API
    final userId = json['user_id'] is String
        ? int.tryParse(json['user_id'] as String) ?? 0
        : (json['user_id'] as int?) ?? 0;

    // Parse name - check both 'name' and 'NAME' fields (API might use either)
    final name = (json['name'] ?? json['NAME'])?.toString() ?? 'Unknown';

    return Category(
      id: id,
      userId: userId,
      parentId: json['parent_id'] is String
          ? int.tryParse(json['parent_id'] as String)
          : json['parent_id'] as int?,
      name: name,
      kind: json['kind'] == 'income'
          ? CategoryKind.income
          : CategoryKind.expense,
      colorHex: json['color_hex']?.toString() ?? json['color']?.toString(),
      icon: json['icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'parent_id': parentId,
      'name': name,
      'kind': kind.name,
      'color_hex': colorHex,
      'icon': icon,
    };
  }
}
