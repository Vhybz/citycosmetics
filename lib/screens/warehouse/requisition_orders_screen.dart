import 'package:flutter/material.dart';
import '../../core/constants.dart';

class RequisitionOrdersScreen extends StatelessWidget {
  const RequisitionOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shop Requisition Requests', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Review and approve stock replenishment requests sent from shop cashiers and store managers.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: AppSpacing.l),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: Text('No pending shop requisition requests.')),
            ),
          ),
        ],
      ),
    );
  }
}

// Legacy Aliases
typedef OrdersScreen = RequisitionOrdersScreen;
typedef HowToUseScreen = RequisitionOrdersScreen;
