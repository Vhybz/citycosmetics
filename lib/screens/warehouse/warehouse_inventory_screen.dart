import 'package:flutter/material.dart';
import '../../core/constants.dart';

class WarehouseInventoryScreen extends StatelessWidget {
  const WarehouseInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Central Warehouse Inventory', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Monitor total bulk stock stored in the central warehouse before dispatching to store branches.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: AppSpacing.l),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: Text('Warehouse Stock Catalog Active.')),
            ),
          ),
        ],
      ),
    );
  }
}

// Legacy Alias
typedef InventoryScreen = WarehouseInventoryScreen;
