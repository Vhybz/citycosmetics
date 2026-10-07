import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_order_model.dart';
import '../core/supabase_config.dart';
import 'user_provider.dart';

class SupabaseCustomerOrderService {
  final _client = SupabaseConfig.client;

  Stream<List<CustomerOrder>> watchOrders(String branchCode) {
    try {
      var query = _client.from('customer_orders').stream(primaryKey: ['id']);
      if (branchCode.isNotEmpty) {
        query = query.eq('branch_code', branchCode);
      }
      return query
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => CustomerOrder.fromJson(Map<String, dynamic>.from(json))).toList())
          .handleError((e, st) {
            debugPrint('Customer Orders Stream Error: $e');
            return <CustomerOrder>[];
          });
    } catch (e) {
      debugPrint('Customer Order Stream Init Error: $e');
      return Stream.value([]);
    }
  }

  Future<void> submitOrder(CustomerOrder order) async {
    try {
      await _client.from('customer_orders').insert(order.toJson());
    } catch (e) {
      debugPrint('Error submitting customer order: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus, {String? paymentStatus}) async {
    try {
      final Map<String, dynamic> updatePayload = {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (paymentStatus != null) {
        updatePayload['payment_status'] = paymentStatus;
      }
      await _client.from('customer_orders').update(updatePayload).eq('id', orderId);
    } catch (e) {
      debugPrint('Error updating customer order status: $e');
      rethrow;
    }
  }
}

final supabaseCustomerOrderServiceProvider = Provider<SupabaseCustomerOrderService>((ref) {
  return SupabaseCustomerOrderService();
});

class CustomerOrdersNotifier extends StateNotifier<AsyncValue<List<CustomerOrder>>> {
  final SupabaseCustomerOrderService _service;
  final Ref ref;
  StreamSubscription? _subscription;

  CustomerOrdersNotifier(this._service, this.ref) : super(const AsyncValue.loading()) {
    _startSubscription();
  }

  void _startSubscription() {
    _subscription?.cancel();
    final user = ref.read(currentUserProvider);
    final branchCode = user?.branchCode ?? '';

    _subscription = _service.watchOrders(branchCode).listen(
      (orders) => state = AsyncValue.data(orders),
      onError: (e, st) => debugPrint('Orders Stream Exception: $e'),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> approveOrder(String orderId) async {
    await _service.updateOrderStatus(orderId, 'approved');
  }

  Future<void> dispatchOrder(String orderId) async {
    await _service.updateOrderStatus(orderId, 'dispatched');
  }

  Future<void> markDelivered(String orderId) async {
    await _service.updateOrderStatus(orderId, 'delivered', paymentStatus: 'paid');
  }

  Future<void> cancelOrder(String orderId) async {
    await _service.updateOrderStatus(orderId, 'cancelled');
  }
}

final customerOrdersProvider = StateNotifierProvider<CustomerOrdersNotifier, AsyncValue<List<CustomerOrder>>>((ref) {
  final service = ref.watch(supabaseCustomerOrderServiceProvider);
  return CustomerOrdersNotifier(service, ref);
});
