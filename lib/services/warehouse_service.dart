import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/warehouse_models.dart';
import 'supabase_warehouse_service.dart';
import 'user_provider.dart';

class ShipmentLogNotifier extends StateNotifier<AsyncValue<List<ShipmentLog>>> {
  final SupabaseWarehouseService _service;
  final Ref ref;
  StreamSubscription? _subscription;

  ShipmentLogNotifier(this._service, this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    ref.listen(currentUserProvider, (previous, next) {
      if (next?.branchCode != previous?.branchCode) {
        _startSubscription();
      }
    });
    _startSubscription();
  }

  void _startSubscription() {
    _subscription?.cancel();
    final user = ref.read(currentUserProvider);
    if (user?.branchCode != null) {
      _subscription = _service.watchShipmentLogs(user!.branchCode!).listen(
        (logs) => state = AsyncValue.data(logs),
        onError: (e, st) {
          debugPrint('Shipment Logs Stream Error: $e');
        },
        cancelOnError: false,
      );
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadLogs({bool silent = false}) async {
    _startSubscription();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addLog(ShipmentLog log) async {
    try {
      final user = ref.read(currentUserProvider);
      await _service.addShipmentLog(log, user?.branchCode);
      await loadLogs();
    } catch (e) {
      debugPrint('Error adding shipment log: $e');
    }
  }

  Future<void> updateStatus(String id, ShipmentStatus status) async {
    try {
      await _service.updateShipmentStatus(id, status.name);
      await loadLogs();
    } catch (e) {
      debugPrint('Error updating shipment status: $e');
    }
  }
}

final shipmentLogProvider = StateNotifierProvider<ShipmentLogNotifier, AsyncValue<List<ShipmentLog>>>((ref) {
  final service = ref.watch(supabaseWarehouseServiceProvider);
  return ShipmentLogNotifier(service, ref);
});

// Legacy Alias Providers
typedef SlaughterLogNotifier = ShipmentLogNotifier;
final slaughterLogProvider = shipmentLogProvider;

class WarehouseBatchNotifier extends StateNotifier<AsyncValue<List<WarehouseBatch>>> {
  final SupabaseWarehouseService _service;
  final Ref ref;
  StreamSubscription? _subscription;

  WarehouseBatchNotifier(this._service, this.ref) : super(const AsyncValue.loading()) {
    _startSubscription();
  }

  void _startSubscription() {
    _subscription?.cancel();
    final user = ref.read(currentUserProvider);
    if (user?.branchCode != null) {
      _subscription = _service.watchWarehouseBatches(user!.branchCode!).listen(
        (batches) => state = AsyncValue.data(batches),
        onError: (e, st) => debugPrint('Warehouse Batches Stream Error: $e'),
        cancelOnError: false,
      );
    } else {
      state = const AsyncValue.data([]);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addBatch(WarehouseBatch batch) async {
    try {
      final user = ref.read(currentUserProvider);
      await _service.addWarehouseBatch(batch, user?.branchCode);
    } catch (e) {
      debugPrint('Error adding warehouse batch: $e');
    }
  }
}

final warehouseBatchProvider = StateNotifierProvider<WarehouseBatchNotifier, AsyncValue<List<WarehouseBatch>>>((ref) {
  final service = ref.watch(supabaseWarehouseServiceProvider);
  return WarehouseBatchNotifier(service, ref);
});

// Legacy Alias Provider
typedef MeatBatchNotifier = WarehouseBatchNotifier;
final meatBatchProvider = warehouseBatchProvider;
