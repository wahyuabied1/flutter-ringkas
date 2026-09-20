class Transaction {
  final int id;
  final int userId;
  final int categoryId;
  final int walletId;
  final double amount;
  final String note;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Additional fields for display
  final String? categoryName;
  final String? categoryKind;
  final String? walletName;

  Transaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.walletId,
    required this.amount,
    required this.note,
    required this.transactionDate,
    required this.createdAt,
    this.updatedAt,
    this.categoryName,
    this.categoryKind,
    this.walletName,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : json['id'],
      userId: json['user_id'] is String
          ? int.tryParse(json['user_id']) ?? 0
          : json['user_id'],
      categoryId: json['category_id'] is String
          ? int.tryParse(json['category_id']) ?? 0
          : json['category_id'],
      walletId: json['dompet_id'] is String
          ? int.tryParse(json['dompet_id']) ?? 0
          : json['dompet_id'],
      amount: _parseAmount(json['amount']),
      note: json['note'] ?? '',
      transactionDate:
          DateTime.tryParse(json['trx_date'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      categoryName: json['kategori_name'] ?? json['category_name'],
      categoryKind: json['kind'],
      walletName: json['dompet_name'] ?? json['wallet_name'],
    );
  }

  static double _parseAmount(dynamic amount) {
    if (amount is String) {
      return double.tryParse(amount) ?? 0.0;
    } else if (amount is num) {
      return amount.toDouble();
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'category_id': categoryId,
    'dompet_id': walletId,
    'amount': amount,
    'note': note,
    'trx_date': transactionDate.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'kategori_name': categoryName,
    'kind': categoryKind,
    'dompet_name': walletName,
  };
}
