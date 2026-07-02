class Medicine {
  final int? id;
  final String name;
  final String dosage;
  final String type; // Tablet, Capsule, Syrup, Injection, Drops, Cream
  final int totalStock;
  final int currentStock;
  final int lowStockAlert;
  final String color; // hex like #RRGGBB
  final int profileId;
  final String notes;
  final DateTime createdAt;

  Medicine({
    this.id,
    required this.name,
    required this.dosage,
    required this.type,
    required this.totalStock,
    required this.currentStock,
    required this.lowStockAlert,
    required this.color,
    required this.profileId,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'type': type,
        'totalStock': totalStock,
        'currentStock': currentStock,
        'lowStockAlert': lowStockAlert,
        'color': color,
        'profileId': profileId,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Medicine.fromMap(Map<String, dynamic> map) => Medicine(
        id: map['id'] as int?,
        name: map['name'] as String,
        dosage: map['dosage'] as String,
        type: map['type'] as String,
        totalStock: map['totalStock'] as int,
        currentStock: map['currentStock'] as int,
        lowStockAlert: map['lowStockAlert'] as int,
        color: map['color'] as String,
        profileId: map['profileId'] as int,
        notes: (map['notes'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Medicine copyWith({
    int? id,
    String? name,
    String? dosage,
    String? type,
    int? totalStock,
    int? currentStock,
    int? lowStockAlert,
    String? color,
    int? profileId,
    String? notes,
  }) =>
      Medicine(
        id: id ?? this.id,
        name: name ?? this.name,
        dosage: dosage ?? this.dosage,
        type: type ?? this.type,
        totalStock: totalStock ?? this.totalStock,
        currentStock: currentStock ?? this.currentStock,
        lowStockAlert: lowStockAlert ?? this.lowStockAlert,
        color: color ?? this.color,
        profileId: profileId ?? this.profileId,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );

  bool get isLowStock => currentStock <= lowStockAlert && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;

  double get stockPercentage =>
      totalStock > 0 ? (currentStock / totalStock).clamp(0.0, 1.0) : 0.0;
}
