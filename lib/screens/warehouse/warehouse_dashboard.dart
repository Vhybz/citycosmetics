import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../widgets/kpi_card.dart';
import '../../services/warehouse_service.dart';
import '../../services/user_provider.dart';
import 'warehouse_shell.dart';

class WarehouseDashboard extends ConsumerWidget {
  const WarehouseDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final shipmentsAsync = ref.watch(shipmentLogProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Welcome Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.l),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Central Warehouse Operations',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome ${user?.firstName ?? "Manager"}. Manage cosmetics procurement, unboxing, stock tagging, and branch dispatches.',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // KPI Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              final crossAxisCount = isDesktop ? 4 : 2;

              final logs = shipmentsAsync.asData?.value ?? [];
              final totalShipments = logs.length;
              final pendingCount = logs.where((l) => l.status.name == 'pending' || l.status.name == 'receiving').length;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.m,
                mainAxisSpacing: AppSpacing.m,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  KpiCard(
                    title: 'Total Shipments',
                    value: '$totalShipments',
                    icon: Icons.local_shipping_rounded,
                    color: Colors.blue,
                  ),
                  KpiCard(
                    title: 'Pending Unboxing',
                    value: '$pendingCount',
                    icon: Icons.inventory_2_rounded,
                    color: Colors.orange,
                  ),
                  KpiCard(
                    title: 'Warehouse Items',
                    value: '1,240',
                    icon: Icons.inventory_rounded,
                    color: Colors.green,
                  ),
                  KpiCard(
                    title: 'Branch Dispatches',
                    value: '18 Today',
                    icon: Icons.outbox_rounded,
                    color: Colors.purple,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Quick Action Shortcuts
          Text('Quick Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.m),

          Wrap(
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.m,
            children: [
              _buildShortcutButton(
                context,
                ref,
                title: 'New Shipment Intake',
                icon: Icons.move_to_inbox_rounded,
                color: Colors.blue,
                screen: WarehouseScreen.shipmentIntake,
              ),
              _buildShortcutButton(
                context,
                ref,
                title: 'Stock Unboxing & Barcode',
                icon: Icons.qr_code_scanner_rounded,
                color: Colors.orange,
                screen: WarehouseScreen.warehouseProcessing,
              ),
              _buildShortcutButton(
                context,
                ref,
                title: 'Dispatch to Shop',
                icon: Icons.local_shipping_rounded,
                color: Colors.green,
                screen: WarehouseScreen.stockDispatch,
              ),
              _buildShortcutButton(
                context,
                ref,
                title: 'Damaged Stock Log',
                icon: Icons.report_problem_rounded,
                color: Colors.red,
                screen: WarehouseScreen.damageManagement,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutButton(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required Color color,
    required WarehouseScreen screen,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => ref.read(warehouseNavProvider.notifier).setScreen(screen),
      borderRadius: BorderRadius.circular(AppRadius.m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: AppSpacing.s),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// Legacy Alias
typedef ButcherDashboard = WarehouseDashboard;
