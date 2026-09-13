import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Product product, double quantity, bool isWholesale, {String? selectedUnit}) {
    final price = product.getPrice(isWholesale);
    final basePrice = isWholesale ? product.wholesalePrice : product.retailPrice;
    state = [...state, CartItem(
      product: product, 
      quantity: quantity, 
      priceAtSale: price, 
      originalPrice: basePrice,
      selectedUnit: selectedUnit,
    )];
  }

  void addItemWithCustomPrice(Product product, double quantity, double customPrice, double originalPrice, {String? selectedUnit}) {
    state = [...state, CartItem(
      product: product, 
      quantity: quantity, 
      priceAtSale: customPrice, 
      originalPrice: originalPrice,
      selectedUnit: selectedUnit,
    )];
  }

  void removeItem(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i]
    ];
  }

  void clear() {
    state = [];
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.total);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// Provider to track if we are in Wholesale mode
final isWholesaleProvider = StateProvider<bool>((ref) => false);
