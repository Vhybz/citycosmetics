import 'package:flutter/material.dart';
import '../../core/constants.dart';

class DamageManagementScreen extends StatelessWidget {
  const DamageManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Damaged & Expired Stock Management', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Log damaged containers, leaking compacts, or expired cosmetic items for loss reporting.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: AppSpacing.l),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: Text('No damaged items logged today.')),
            ),
          ),
        ],
      ),
    );
  }
}

// Legacy Alias
typedef WasteManagementScreen = DamageManagementScreen;
typedef ButcherExpenseScreen = DamageManagementScreen;
