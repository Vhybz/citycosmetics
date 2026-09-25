import 'package:flutter/material.dart';
import '../../core/constants.dart';

class StockDispatchScreen extends StatelessWidget {
  const StockDispatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock Dispatch to Shop Branches', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Transfer stock incrementally ("small small") from the Central Warehouse to retail shop branches.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: AppSpacing.l),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: Text('Stock Dispatch Hub Active.')),
            ),
          ),
        ],
      ),
    );
  }
}

// Legacy Alias
typedef StockTransferScreen = StockDispatchScreen;
