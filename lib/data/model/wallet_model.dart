class Wallet {
  final int id;
  final int userId;
  final String name;
  final String currency;
  final double currentBalance;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.currency,
    required this.currentBalance,
    required this.createdAt,
    this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : json['id'],
      userId: json['user_id'] is String
          ? int.tryParse(json['user_id']) ?? 0
          : json['user_id'],
      name: json['name'] ?? '',
      currency: json['currency'] ?? 'IDR',
      currentBalance: _parseBalance(json['current_balance']),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  static double _parseBalance(dynamic balance) {
    if (balance is String) {
      return double.tryParse(balance) ?? 0.0;
    } else if (balance is num) {
      return balance.toDouble();
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'currency': currency,
    'current_balance': currentBalance,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
