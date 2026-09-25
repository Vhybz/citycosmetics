import 'package:flutter/foundation.dart';

enum ShipmentStatus { pending, receiving, inspected, completed, processed }

enum BatchStatus { 
  transporting, 
  received, 
  receiving,
  unboxing,
  preparing,
  cutting,
  packaging, 
  shelfReady,
  dispatched,
  completed 
}

// Keep enum aliases for legacy compatibility
typedef SlaughterStatus = ShipmentStatus;
typedef MeatBatchStatus = BatchStatus;

enum ShipmentCategory { cosmetics, skincare, fragrance, haircare, makeup, accessories, general }

class ShipmentLog {
  final String id;
  final String tagNumber; // Unique shipment tracking #
  final String supplierName;
  final String? invoiceNumber;
  final DateTime arrivalDate;
  final double? shipmentCost;
  final double totalItemsReceived;
  final ShipmentStatus status;
  final String? receivedBy;
  final String? notes;

  ShipmentLog({
    required this.id,
    required this.tagNumber,
    required this.supplierName,
    this.invoiceNumber,
    required this.arrivalDate,
    this.shipmentCost,
    this.totalItemsReceived = 0,
    this.status = ShipmentStatus.pending,
    this.receivedBy,
    this.notes,
  });

  // Alias getters for UI compatibility
  String get animalType => supplierName;
  double get liveWeight => totalItemsReceived;
  double get meatWeight => totalItemsReceived;
  double? get farmPrice => shipmentCost;

  ShipmentLog copyWith({
    String? id,
    String? tagNumber,
    String? supplierName,
    String? invoiceNumber,
    DateTime? arrivalDate,
    double? shipmentCost,
    double? totalItemsReceived,
    ShipmentStatus? status,
    String? receivedBy,
    String? notes,
  }) {
    return ShipmentLog(
      id: id ?? this.id,
      tagNumber: tagNumber ?? this.tagNumber,
      supplierName: supplierName ?? this.supplierName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      shipmentCost: shipmentCost ?? this.shipmentCost,
      totalItemsReceived: totalItemsReceived ?? this.totalItemsReceived,
      status: status ?? this.status,
      receivedBy: receivedBy ?? this.receivedBy,
      notes: notes ?? this.notes,
    );
  }

  factory ShipmentLog.fromJson(Map<String, dynamic> json) {
    return ShipmentLog(
      id: json['id']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? json['tagNumber']?.toString() ?? 'SHIP-001',
      supplierName: json['type']?.toString() ?? json['animal_type']?.toString() ?? json['supplier_name']?.toString() ?? 'General Cosmetics Supplier',
      invoiceNumber: json['invoice_number']?.toString() ?? json['manual_farm_tag']?.toString(),
      arrivalDate: json['slaughter_time'] != null 
          ? DateTime.tryParse(json['slaughter_time'].toString()) ?? DateTime.now() 
          : (json['slaughter_date'] != null 
              ? DateTime.tryParse(json['slaughter_date'].toString()) ?? DateTime.now() 
              : DateTime.now()),
      shipmentCost: (json['farm_price'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? (json['shipment_cost'] as num?)?.toDouble(),
      totalItemsReceived: (json['initial_weight'] as num?)?.toDouble() ?? (json['carcass_weight'] as num?)?.toDouble() ?? (json['live_weight'] as num?)?.toDouble() ?? 0,
      status: ShipmentStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(), 
        orElse: () => ShipmentStatus.completed,
      ),
      receivedBy: json['butcher_name']?.toString() ?? json['received_by']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag_number': tagNumber,
      'type': supplierName,
      'animal_type': supplierName,
      'manual_farm_tag': invoiceNumber,
      'invoice_number': invoiceNumber,
      'slaughter_time': arrivalDate.toIso8601String(),
      'slaughter_date': arrivalDate.toIso8601String(),
      'farm_price': shipmentCost,
      'price': shipmentCost,
      'initial_weight': totalItemsReceived,
      'live_weight': totalItemsReceived,
      'carcass_weight': totalItemsReceived,
      'status': status.name,
      'butcher_name': receivedBy,
      'notes': notes,
    };
  }
}

// Alias for UI screen compatibility
typedef SlaughterLog = ShipmentLog;

class BatchSource {
  final String name;
  final String location;
  final String owner;

  BatchSource({required this.name, required this.location, required this.owner});

  factory BatchSource.fromJson(Map<String, dynamic> json) {
    return BatchSource(
      name: json['name']?.toString() ?? 'Supplier Warehouse',
      location: json['location']?.toString() ?? 'Main HQ',
      owner: json['owner']?.toString() ?? 'City Cosmetics',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'location': location, 'owner': owner};
}

class WarehouseBatch {
  final String id;
  final String batchNumber;
  final String productName;
  final String category;
  final double quantity;
  final double costPrice;
  final double retailPrice;
  final DateTime? expiryDate;
  final BatchStatus status;
  final String? shelfLocation;
  final BatchSource? source;
  final DateTime createdAt;
  final String? barcode;

  WarehouseBatch({
    required this.id,
    required this.batchNumber,
    required this.productName,
    this.category = 'Cosmetics',
    required this.quantity,
    this.costPrice = 0.0,
    this.retailPrice = 0.0,
    this.expiryDate,
    this.status = BatchStatus.receiving,
    this.shelfLocation,
    this.source,
    required this.createdAt,
    this.barcode,
  });

  // Compatibility aliases
  String get meatType => productName;
  double get weight => quantity;

  factory WarehouseBatch.fromJson(dynamic json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    return WarehouseBatch(
      id: map['id']?.toString() ?? '',
      batchNumber: map['batch_number']?.toString() ?? map['id']?.toString() ?? '',
      productName: map['meat_type']?.toString() ?? map['product_name']?.toString() ?? 'Cosmetic Product',
      category: map['category']?.toString() ?? 'Cosmetics',
      quantity: (map['current_weight'] as num?)?.toDouble() ?? (map['initial_weight'] as num?)?.toDouble() ?? (map['weight'] as num?)?.toDouble() ?? (map['quantity'] as num?)?.toDouble() ?? 0,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
      retailPrice: (map['retail_price'] as num?)?.toDouble() ?? 0,
      expiryDate: map['expiry_date'] != null ? DateTime.tryParse(map['expiry_date'].toString()) : null,
      status: BatchStatus.values.firstWhere(
        (e) => e.name == map['status']?.toString(),
        orElse: () => BatchStatus.preparing,
      ),
      shelfLocation: map['shelf_location']?.toString(),
      source: map['source'] != null 
          ? BatchSource.fromJson(map['source']) 
          : BatchSource(
              name: map['source_name']?.toString() ?? 'Supplier Warehouse',
              location: map['source_location']?.toString() ?? 'HQ',
              owner: map['owner_name']?.toString() ?? 'City Cosmetics',
            ),
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      barcode: map['barcode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_number': batchNumber,
      'meat_type': productName,
      'category': category,
      'initial_weight': quantity,
      'current_weight': quantity,
      'weight': quantity,
      'cost_price': costPrice,
      'retail_price': retailPrice,
      'expiry_date': expiryDate?.toIso8601String(),
      'status': status.name,
      'shelf_location': shelfLocation,
      'source_name': source?.name,
      'source_location': source?.location,
      'owner_name': source?.owner,
      'source': source?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'barcode': barcode,
    };
  }
}

// Alias for UI compatibility
typedef MeatBatch = WarehouseBatch;

class StockUnit {
  final String id;
  final String batchId;
  final String productName;
  final double quantity;
  final double price;
  final DateTime? expiryDate;
  final String? barcode;

  StockUnit({
    required this.id,
    required this.batchId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.expiryDate,
    this.barcode,
  });

  factory StockUnit.fromJson(dynamic json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    return StockUnit(
      id: map['id']?.toString() ?? '',
      batchId: map['batch_id']?.toString() ?? '',
      productName: map['meat_type']?.toString() ?? map['product_name']?.toString() ?? 'Unit Item',
      quantity: (map['weight'] as num?)?.toDouble() ?? (map['quantity'] as num?)?.toDouble() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      expiryDate: map['expiry_date'] != null ? DateTime.tryParse(map['expiry_date'].toString()) : null,
      barcode: map['barcode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'meat_type': productName,
      'weight': quantity,
      'price': price,
      'expiry_date': expiryDate?.toIso8601String(),
      'barcode': barcode,
    };
  }
}

// Alias for UI compatibility
typedef MeatCut = StockUnit;
