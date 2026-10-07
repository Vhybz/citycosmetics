import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch_model.dart';
import '../core/supabase_config.dart';
import 'supabase_product_service.dart';

class SupabaseBranchService {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Branch>> getBranches() async {
    final response = await _client
        .from('branches')
        .select()
        .order('name', ascending: true);
    
    return (response as List).map((json) => Branch.fromJson(json)).toList();
  }

  Future<void> createBranch(Branch branch) async {
    await _client.from('branches').insert(branch.toJson());
    try {
      final productService = SupabaseProductService();
      await productService.initializeNewBranchProducts(branch.code);
    } catch (e) {
      debugPrint('Warning initializing branch product catalog: $e');
    }
  }

  Future<Branch?> getBranchByCode(String code) async {
    try {
      final response = await _client
          .from('branches')
          .select()
          .eq('code', code)
          .single();
      return Branch.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateBranchAdmin(String code, String adminId) async {
    await _client
        .from('branches')
        .update({'admin_id': adminId})
        .eq('code', code);
  }
}
