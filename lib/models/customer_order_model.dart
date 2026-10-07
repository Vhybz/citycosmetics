import 'package:intl/intl.dart';

class CustomerOrderItem {
  final String productId;
  final String productName;
  final String sku;
  final double quantity;
  final String unitType; // 'Pcs', 'Boxes', 'Packs'
  final double pcsPerBox;
  final double totalPcs;
  final double unitPrice;
  final double totalPrice;

  CustomerOrderItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    this.unitType = 'Pcs',
    this.pcsPerBox = 12.0,
    required this.totalPcs,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory CustomerOrderItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num? ?? 0.0).toDouble();
    final pcsBox = (json['pcs_per_box'] as num? ?? 12.0).toDouble();
    final uType = json['unit_type']?.toString() ?? 'Pcs';
    double calculatedPcs = (json['total_pcs'] as num?)?.toDouble() ?? qty;
    if (uType == 'Boxes' && calculatedPcs == qty) {
      calculatedPcs = qty * pcsBox;
    }

    return CustomerOrderItem(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? 'Cosmetic Product',
      sku: json['sku']?.toString() ?? '',
      quantity: qty,
      unitType: uType,
      pcsPerBox: pcsBox,
      totalPcs: calculatedPcs,
      unitPrice: (json['unit_price'] as num? ?? 0.0).toDouble(),
      totalPrice: (json['total_price'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'sku': sku,
    'quantity': quantity,
    'unit_type': unitType,
    'pcs_per_box': pcsPerBox,
    'total_pcs': totalPcs,
    'unit_price': unitPrice,
    'total_price': totalPrice,
  };
}

class CustomerOrder {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? businessName;
  final List<CustomerOrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'approved', 'processing', 'dispatched', 'delivered', 'cancelled'
  final String paymentMode; // 'paystack', 'pay_on_delivery', 'add_to_credit'
  final String paymentStatus; // 'paid', 'unpaid', 'credit'
  final String? paystackReference;
  final String? deliveryNotes;
  final String? branchCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.businessName,
    required this.items,
    required this.totalAmount,
    this.status = 'pending',
    this.paymentMode = 'pay_on_delivery',
    this.paymentStatus = 'unpaid',
    this.paystackReference,
    this.deliveryNotes,
    this.branchCode,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved' || status == 'processing';
  bool get isDispatched => status == 'dispatched' || status == 'delivered';
  bool get isPaidViaPaystack => paymentMode == 'paystack' && paymentStatus == 'paid';

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return CustomerOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? 'ORD-001',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Customer',
      customerPhone: json['customer_phone']?.toString() ?? '',
      businessName: json['business_name']?.toString(),
      items: rawItems.map((e) => CustomerOrderItem.fromJson(Map<String, dynamic>.from(e))).toList(),
      totalAmount: (json['total_amount'] as num? ?? 0.0).toDouble(),
      status: json['status']?.toString() ?? 'pending',
      paymentMode: json['payment_mode']?.toString() ?? 'pay_on_delivery',
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      paystackReference: json['paystack_reference']?.toString(),
      deliveryNotes: json['delivery_notes']?.toString(),
      branchCode: json['branch_code']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'customer_id': customerId,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'business_name': businessName,
    'items': items.map((e) => e.toJson()).toList(),
    'total_amount': totalAmount,
    'status': status,
    'payment_mode': paymentMode,
    'payment_status': paymentStatus,
    'paystack_reference': paystackReference,
    'delivery_notes': deliveryNotes,
    'branch_code': branchCode,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
