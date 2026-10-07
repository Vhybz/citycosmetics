import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../core/uuid_utils.dart';
import 'product_service.dart';
import '../core/supabase_config.dart';

final productServiceProvider = Provider<ProductService>((ref) {
  return SupabaseProductService();
});

class SupabaseProductService implements ProductService {
  SupabaseClient get _client => SupabaseConfig.client;

  @override
  Future<List<Product>> getProducts(String branchCode) async {
    final response = await _client
        .from('products')
        .select()
        .eq('branch_code', branchCode)
        .eq('is_deleted', false);
    
    List<Product> products = (response as List).map((json) => Product.fromJson(json)).toList();

    if (products.isEmpty && branchCode.isNotEmpty) {
      await initializeNewBranchProducts(branchCode);
      final refetched = await _client
          .from('products')
          .select()
          .eq('branch_code', branchCode)
          .eq('is_deleted', false);
      products = (refetched as List).map((json) => Product.fromJson(json)).toList();
    }

    return products;
  }

  Future<void> initializeNewBranchProducts(String newBranchCode) async {
    try {
      if (newBranchCode.trim().isEmpty) return;

      final response = await _client
          .from('products')
          .select()
          .eq('is_deleted', false);

      final List<dynamic> rawList = response as List? ?? [];
      if (rawList.isEmpty) return;

      final allProducts = rawList.map((e) => Product.fromJson(e)).toList();

      final Map<String, Product> masterCatalog = {};
      for (final p in allProducts) {
        final key = (p.sku != null && p.sku!.trim().isNotEmpty)
            ? p.sku!.trim().toUpperCase()
            : p.name.trim().toLowerCase();

        if (!masterCatalog.containsKey(key) || p.branchCode == 'HQ' || p.branchCode == null) {
          masterCatalog[key] = p;
        }
      }

      final existingForBranch = await _client
          .from('products')
          .select('name, sku')
          .eq('branch_code', newBranchCode)
          .eq('is_deleted', false);

      final existingKeys = (existingForBranch as List? ?? []).map((e) {
        final sku = e['sku']?.toString().trim().toUpperCase();
        final name = e['name']?.toString().trim().toLowerCase();
        return (sku != null && sku.isNotEmpty) ? sku : (name ?? '');
      }).toSet();

      final List<Map<String, dynamic>> newProductRows = [];

      for (final entry in masterCatalog.entries) {
        final key = entry.key;
        if (existingKeys.contains(key)) continue;

        final master = entry.value;
        final cleanBranch = newBranchCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final newProductId = 'prod_${cleanBranch}_${UuidUtils.generate()}';

        final newBranchProduct = Product(
          id: newProductId,
          branchCode: newBranchCode,
          name: master.name,
          retailPrice: master.retailPrice,
          wholesalePrice: master.wholesalePrice,
          costPrice: master.costPrice,
          retailBrackets: master.retailBrackets,
          wholesaleBrackets: master.wholesaleBrackets,
          imageUrl: master.imageUrl,
          category: master.category,
          stockQuantity: 0.0,
          warehouseQuantity: 0.0,
          dailyStockAdded: 0.0,
          minStoreStock: master.minStoreStock,
          sku: master.sku,
          brand: master.brand,
          size: master.size,
          warehouseLocation: master.warehouseLocation,
          unit: master.unit,
          hasPacks: master.hasPacks,
          hasBoxes: master.hasBoxes,
          pcsPerPack: master.pcsPerPack,
          packsPerBox: master.packsPerBox,
          pcsPerBox: master.pcsPerBox,
          discountPercentage: master.discountPercentage,
          promoStartDate: master.promoStartDate,
          promoEndDate: master.promoEndDate,
          promoTarget: master.promoTarget,
          promoCustomerTarget: master.promoCustomerTarget,
          targetCustomerId: master.targetCustomerId,
          isDeleted: false,
          isUnlimited: master.isUnlimited,
          lowStockThreshold: master.lowStockThreshold,
          lastStockUpdate: DateTime.now(),
        );

        newProductRows.add(newBranchProduct.toJson());
      }

      if (newProductRows.isNotEmpty) {
        for (var i = 0; i < newProductRows.length; i += 50) {
          final chunk = newProductRows.sublist(i, (i + 50 > newProductRows.length) ? newProductRows.length : i + 50);
          await _client.from('products').insert(chunk);
        }
        debugPrint('Initialized ${newProductRows.length} zero-quantity products for branch "$newBranchCode" with master prices.');
      }
    } catch (e) {
      debugPrint('Error initializing branch products for $newBranchCode: $e');
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    final response = await _client
        .from('products')
        .select()
        .eq('id', id)
        .single();
    
    return Product.fromJson(response);
  }

  @override
  Future<void> addProduct(Product product) async {
    await _client.from('products').insert(product.toJson());
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _client
        .from('products')
        .update(product.toJson())
        .eq('id', product.id);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client
        .from('products')
        .delete()
        .eq('id', id);
  }

  @override
  Future<void> updateStock(String id, double newQuantity) async {
    await _client
        .from('products')
        .update({'stock_quantity': newQuantity})
        .eq('id', id);
  }

  Future<void> incrementStock(String id, double amount) async {
    await _client.rpc('increment_stock', params: {
      'p_id': id,
      'p_amount': amount,
    });
  }

  @override
  Future<void> applyPromotion(String id, double percentage, DateTime? start, DateTime? end, PromoTarget target, PromoCustomerTarget customerTarget, [String? targetCustomerId]) async {
    await _client
        .from('products')
        .update({
          'discount_percentage': percentage,
          'promo_start': start?.toIso8601String(),
          'promo_end': end?.toIso8601String(),
          'promo_target': target.name,
          'promo_customer_target': customerTarget.name,
          'target_customer_id': targetCustomerId,
        })
        .eq('id', id);
  }

  @override
  Future<String?> uploadProductImage(Uint8List bytes, String fileName) async {
    try {
      final storage = _client.storage.from('product-images');
      final path = 'products/$fileName';
      
      await storage.uploadBinary(
        path, 
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      
      return storage.getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload Error: $e');
      return null;
    }
  }

  @override
  Stream<List<Product>> watchProducts(String branchCode) {
    try {
      return _client
          .from('products')
          .stream(primaryKey: ['id'])
          .eq('branch_code', branchCode)
          .asyncMap((data) async {
            List<Product> products = data
                .map((json) => Product.fromJson(json))
                .where((p) => !p.isDeleted)
                .toList();

            if (products.isEmpty && branchCode.isNotEmpty) {
              await initializeNewBranchProducts(branchCode);
              final refetched = await _client
                  .from('products')
                  .select()
                  .eq('branch_code', branchCode)
                  .eq('is_deleted', false);
              products = (refetched as List).map((json) => Product.fromJson(json)).toList();
            }

            return products;
          });
    } catch (e) {
      debugPrint('Error watching products: $e');
      return Stream.value([]);
    }
  }
}
