import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/warehouse_models.dart';
import '../core/supabase_config.dart';

class SupabaseWarehouseService {
  SupabaseClient get _client => SupabaseConfig.client;

  Stream<List<ShipmentLog>> watchShipmentLogs(String branchCode) {
    try {
      return _client
          .from('slaughter_logs')
          .stream(primaryKey: ['id'])
          .eq('branch_code', branchCode)
          .order('slaughter_time', ascending: false)
          .map((data) => data.map((json) => ShipmentLog.fromJson(json)).toList());
    } catch (e) {
      debugPrint('SupabaseWarehouseService Stream Error: $e');
      return Stream.value([]);
    }
  }

  Future<List<ShipmentLog>> getShipmentLogs(String branchCode) async {
    try {
      final data = await _client
          .from('slaughter_logs')
          .select()
          .eq('branch_code', branchCode)
          .order('slaughter_time', ascending: false);
      return (data as List).map((json) => ShipmentLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting shipment logs: $e');
      return [];
    }
  }

  Future<void> addShipmentLog(ShipmentLog log, [String? branchCode]) async {
    try {
      final json = log.toJson();
      if (branchCode != null) json['branch_code'] = branchCode;
      await _client.from('slaughter_logs').insert(json);
    } catch (e) {
      debugPrint('Error inserting shipment log: $e');
      rethrow;
    }
  }

  Future<void> updateShipmentStatus(String id, String status) async {
    try {
      await _client.from('slaughter_logs').update({'status': status}).eq('id', id);
    } catch (e) {
      debugPrint('Error updating shipment status: $e');
      rethrow;
    }
  }

  Stream<List<WarehouseBatch>> watchWarehouseBatches(String branchCode) {
    try {
      return _client
          .from('meat_batches')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => WarehouseBatch.fromJson(json)).toList());
    } catch (e) {
      debugPrint('Error watching warehouse batches: $e');
      return Stream.value([]);
    }
  }

  Future<void> addWarehouseBatch(WarehouseBatch batch, [String? branchCode]) async {
    try {
      final json = batch.toJson();
      if (branchCode != null) json['branch_code'] = branchCode;
      await _client.from('meat_batches').insert(json);
    } catch (e) {
      debugPrint('Error inserting warehouse batch: $e');
      rethrow;
    }
  }
}

final supabaseWarehouseServiceProvider = Provider<SupabaseWarehouseService>((ref) {
  return SupabaseWarehouseService();
});

// Alias for legacy compatibility
typedef SupabaseButcherService = SupabaseWarehouseService;
final supabaseButcherServiceProvider = supabaseWarehouseServiceProvider;
