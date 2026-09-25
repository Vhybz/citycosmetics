class Customer {
  final String id;
  final String? branchCode;
  final String name;
  final String phone;
  final String? phone2;
  final String? location;
  final bool isFavorite;
  final double loyaltyPoints;
  final int visitCount;
  final bool isBulkPurchaser;
  final bool isWholesaler;
  final bool isSpecial;
  final double? specialDiscountPercentage;
  final DateTime? lastPromoDate;
  final bool isDeleted;

  Customer({
    required this.id,
    this.branchCode,
    required this.name,
    required this.phone,
    this.phone2,
    this.location,
    this.isFavorite = false,
    this.isBulkPurchaser = false,
    this.isWholesaler = false,
    this.isSpecial = false,
    this.specialDiscountPercentage,
    this.lastPromoDate,
    this.loyaltyPoints = 0.0,
    this.visitCount = 0,
    this.isDeleted = false,
  });

  bool get hasUsedDailyPromoToday {
    if (lastPromoDate == null) return false;
    final now = DateTime.now();
    return lastPromoDate!.year == now.year &&
        lastPromoDate!.month == now.month &&
        lastPromoDate!.day == now.day;
  }

  Customer copyWith({
    String? id,
    String? branchCode,
    String? name,
    String? phone,
    String? phone2,
    String? location,
    bool? isFavorite,
    bool? isBulkPurchaser,
    bool? isWholesaler,
    bool? isSpecial,
    double? specialDiscountPercentage,
    DateTime? lastPromoDate,
    double? loyaltyPoints,
    int? visitCount,
    bool? isDeleted,
  }) {
    return Customer(
      id: id ?? this.id,
      branchCode: branchCode ?? this.branchCode,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      phone2: phone2 ?? this.phone2,
      location: location ?? this.location,
      isFavorite: isFavorite ?? this.isFavorite,
      isBulkPurchaser: isBulkPurchaser ?? this.isBulkPurchaser,
      isWholesaler: isWholesaler ?? this.isWholesaler,
      isSpecial: isSpecial ?? this.isSpecial,
      specialDiscountPercentage: specialDiscountPercentage ?? this.specialDiscountPercentage,
      lastPromoDate: lastPromoDate ?? this.lastPromoDate,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      visitCount: visitCount ?? this.visitCount,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory Customer.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json);
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return Customer(
      id: map['id']?.toString() ?? '',
      branchCode: map['branch_code']?.toString(),
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      phone2: map['phone2']?.toString(),
      location: map['location']?.toString(),
      isFavorite: map['is_favorite'] == true,
      isBulkPurchaser: map['is_bulk_purchaser'] == true,
      isWholesaler: map['is_wholesaler'] == true,
      isSpecial: map['is_special'] == true,
      specialDiscountPercentage: map['special_discount_percentage'] != null
          ? (map['special_discount_percentage'] as num).toDouble()
          : null,
      lastPromoDate: parseDate(map['last_promo_date']),
      loyaltyPoints: (map['loyalty_points'] as num? ?? 0.0).toDouble(),
      visitCount: (map['visit_count'] as num? ?? 0).toInt(),
      isDeleted: map['is_deleted'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_code': branchCode,
      'name': name,
      'phone': phone,
      'phone2': phone2,
      'location': location,
      'is_favorite': isFavorite,
      'is_bulk_purchaser': isBulkPurchaser,
      'is_wholesaler': isWholesaler,
      'is_special': isSpecial,
      'special_discount_percentage': specialDiscountPercentage,
      'last_promo_date': lastPromoDate?.toIso8601String(),
      'loyalty_points': loyaltyPoints,
      'visit_count': visitCount,
      'is_deleted': isDeleted,
    };
  }
}
