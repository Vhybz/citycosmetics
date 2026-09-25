import 'package:flutter/material.dart';
import '../../core/constants.dart';

class BulkBreakdownScreen extends StatelessWidget {
  const BulkBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bulk Package Unboxing Station', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Unpack master cartons and bulk packages into individual retail cosmetic items or gift sets.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: AppSpacing.l),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text('Bulk Carton Unboxing Station Ready.'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Legacy Alias
typedef CarcassBreakdownScreen = BulkBreakdownScreen;
