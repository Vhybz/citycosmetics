import 'package:flutter/material.dart';
import '../../core/constants.dart';

class WarehouseReportsScreen extends StatelessWidget {
  const WarehouseReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Supply Chain & Warehouse Reports', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Track procurement costs, stock turnover, branch dispatches, and damaged stock losses.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: AppSpacing.l),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: Text('Supply Chain Reports Generator Ready.')),
            ),
          ),
        ],
      ),
    );
  }
}

// Legacy Alias
typedef ReportsScreen = WarehouseReportsScreen;
