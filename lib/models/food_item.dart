import 'inventory_priority.dart';

enum FreshnessStatus { safe, expiringSoon, expired, unknown }

/// Accounting lifecycle. Only inStock items appear in inventory.
enum FoodStatus { inStock, consumed, discarded }

enum FoodPriority { first, soon, later }

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.storedAt,
    this.status = FoodStatus.inStock,
    this.quantity = '1 item',
    required this.price,
    required this.category,
    this.savedAmount = 0,
    this.wasUseFirst = false,
    this.freshnessStatus = FreshnessStatus.unknown,
    this.expiresAt,
    this.shelfId,
    this.image = '',
    this.confidence,
    this.lastSeen,
    this.removedAt,
    this.outcomeAt,
  });

  final String id;
  final String name;
  final DateTime storedAt;
  final FoodStatus status;
  final String quantity;
  final double price;
  final String category;

  /// Value credited when consumed while in Use First; fixed at that moment.
  final double savedAmount;
  final bool wasUseFirst;
  final FreshnessStatus freshnessStatus;
  final DateTime? expiresAt;
  final int? shelfId;
  final String image;
  final double? confidence;
  final DateTime? lastSeen;
  final DateTime? removedAt;
  final DateTime? outcomeAt;

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final freshness = json['status'] as String? ?? 'unknown';
    return FoodItem(
      id: (json['id'] as num).toInt().toString(),
      name: json['name'] as String,
      storedAt: DateTime.parse(json['stored_at'] as String),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String,
      freshnessStatus: switch (freshness) {
        'safe' => FreshnessStatus.safe,
        'expiring_soon' => FreshnessStatus.expiringSoon,
        'expired' => FreshnessStatus.expired,
        _ => FreshnessStatus.unknown,
      },
      expiresAt: _date(json['expires_at']),
      shelfId: (json['shelf_id'] as num?)?.toInt(),
      image: json['image'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble(),
      lastSeen: _date(json['last_seen']),
      removedAt: _date(json['removed_at']),
    );
  }

  factory FoodItem.fromAccountingEvent(Map<String, dynamic> json) {
    final outcome = json['outcome'] as String;
    final price = (json['price'] as num).toDouble();
    return FoodItem(
      id: (json['item_id'] as num).toInt().toString(),
      name: json['name'] as String,
      storedAt: DateTime.parse(json['stored_at'] as String),
      status: outcome == 'consumed'
          ? FoodStatus.consumed
          : FoodStatus.discarded,
      price: price,
      category: json['category'] as String,
      savedAmount: outcome == 'consumed' && json['use_first'] == true
          ? price
          : 0,
      wasUseFirst: json['use_first'] == true,
      outcomeAt: DateTime.parse(json['occurred_at'] as String),
    );
  }

  static DateTime? _date(Object? value) =>
      value is String && value.isNotEmpty ? DateTime.parse(value) : null;

  FoodItem copyWith({
    String? name,
    double? price,
    String? category,
    FoodStatus? status,
    double? savedAmount,
    bool? wasUseFirst,
    DateTime? removedAt,
    bool clearRemovedAt = false,
    DateTime? outcomeAt,
  }) => FoodItem(
    id: id,
    name: name ?? this.name,
    storedAt: storedAt,
    status: status ?? this.status,
    quantity: quantity,
    price: price ?? this.price,
    category: category ?? this.category,
    savedAmount: savedAmount ?? this.savedAmount,
    wasUseFirst: wasUseFirst ?? this.wasUseFirst,
    freshnessStatus: freshnessStatus,
    expiresAt: expiresAt,
    shelfId: shelfId,
    image: image,
    confidence: confidence,
    lastSeen: lastSeen,
    removedAt: clearRemovedAt ? null : removedAt ?? this.removedAt,
    outcomeAt: outcomeAt ?? this.outcomeAt,
  );

  int get daysLeft => InventoryPriority.daysLeft(this, DateTime.now());
  FoodPriority get priority => InventoryPriority.priority(this, DateTime.now());

  String get emoji => switch (category.toLowerCase()) {
    'meat' => '🍗',
    'produce' || 'fruit' || 'vegetable' => '🥬',
    'dairy' => '🥛',
    _ => '🥑',
  };
}
