import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/main_app_bar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/role_pop_scope.dart';
import '../../services/birthday_service.dart';
import '../../widgets/passcode_guard.dart';
import 'warehouse_dashboard.dart';
import 'shipment_intake_screen.dart';
import 'warehouse_processing_screen.dart';
import 'stock_dispatch_screen.dart';
import 'warehouse_inventory_screen.dart';
import 'requisition_orders_screen.dart';
import 'damage_management_screen.dart';
import 'warehouse_reports_screen.dart';
import 'bulk_breakdown_screen.dart';
import '../profile_screen.dart';

enum WarehouseScreen {
  dashboard,
  shipmentIntake,
  warehouseProcessing,
  stockDispatch,
  inventory,
  orders,
  damageManagement,
  reports,
  profile,
  bulkBreakdown,
}

final warehouseNavProvider = StateNotifierProvider<WarehouseNavNotifier, WarehouseScreen>((ref) {
  return WarehouseNavNotifier();
});

class WarehouseNavNotifier extends StateNotifier<WarehouseScreen> {
  WarehouseNavNotifier() : super(WarehouseScreen.dashboard);

  void setScreen(WarehouseScreen screen) {
    state = screen;
  }
}

class WarehouseShell extends ConsumerWidget {
  const WarehouseShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        BirthdayService.checkAndShowBirthdayWish(context, user);
      }
    });

    final currentScreen = ref.watch(warehouseNavProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final theme = Theme.of(context);

    return RolePopScope(
      currentRoute: '/warehouse',
      child: PopScope(
        canPop: currentScreen == WarehouseScreen.dashboard,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (currentScreen != WarehouseScreen.dashboard) {
            ref.read(warehouseNavProvider.notifier).setScreen(WarehouseScreen.dashboard);
          }
        },
        child: PasscodeGuard(
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: MainAppBar(
              title: _getScreenTitle(currentScreen),
              onProfileTap: () => ref.read(warehouseNavProvider.notifier).setScreen(WarehouseScreen.profile),
            ),
            drawer: isDesktop ? null : Drawer(child: _buildSidebar(ref, currentScreen, user, context)),
            body: Row(
              children: [
                if (isDesktop) _buildSidebar(ref, currentScreen, user, context),
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: true,
                    child: _buildContent(currentScreen),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getScreenTitle(WarehouseScreen screen) {
    switch (screen) {
      case WarehouseScreen.dashboard: return 'Central Warehouse Dashboard';
      case WarehouseScreen.shipmentIntake: return 'Procurement & Shipment Intake';
      case WarehouseScreen.warehouseProcessing: return 'Stock Unboxing & Barcode Tagging';
      case WarehouseScreen.stockDispatch: return 'Stock Dispatch to Shop';
      case WarehouseScreen.inventory: return 'Warehouse Inventory';
      case WarehouseScreen.orders: return 'Shop Requisition Requests';
      case WarehouseScreen.damageManagement: return 'Damaged & Expired Stock';
      case WarehouseScreen.reports: return 'Supply Chain Reports';
      case WarehouseScreen.profile: return 'Personal Profile';
      case WarehouseScreen.bulkBreakdown: return 'Bulk Package Unboxing';
    }
  }

  Widget _buildSidebar(WidgetRef ref, WarehouseScreen current, UserAccount user, BuildContext context) {
    const currentRoute = '/warehouse';
    final menuItems = [
      SidebarItem(icon: Icons.dashboard_rounded, title: 'Dashboard', route: 'warehouse:dashboard'),
      SidebarItem(icon: Icons.move_to_inbox_rounded, title: 'Shipment Intake', route: 'warehouse:shipmentIntake'),
      SidebarItem(icon: Icons.inventory_2_rounded, title: 'Stock Processing', route: 'warehouse:warehouseProcessing'),
      SidebarItem(icon: Icons.unarchive_rounded, title: 'Bulk Unboxing', route: 'warehouse:bulkBreakdown'),
      SidebarItem(icon: Icons.local_shipping_rounded, title: 'Stock Dispatch', route: 'warehouse:stockDispatch'),
      SidebarItem(icon: Icons.warehouse_rounded, title: 'Warehouse Stock', route: 'warehouse:inventory'),
      SidebarItem(icon: Icons.shopping_bag_rounded, title: 'Shop Requests', route: 'warehouse:orders'),
      SidebarItem(icon: Icons.report_problem_rounded, title: 'Damaged Stock', route: 'warehouse:damageManagement'),
      SidebarItem(icon: Icons.assessment_rounded, title: 'Reports', route: 'warehouse:reports'),
    ];

    return AppSidebar(
      userId: user.id,
      userName: user.name,
      userRole: 'WAREHOUSE MANAGER',
      currentRoute: 'warehouse:${current.name}',
      items: menuItems,
      onTap: (route) {
        if (route.startsWith('warehouse:')) {
          final screenStr = route.split(':')[1];
          final screen = WarehouseScreen.values.byName(screenStr);
          ref.read(warehouseNavProvider.notifier).setScreen(screen);
        } else {
          MenuService.navigate(context, route, currentRoute);
        }
      },
    );
  }

  Widget _buildContent(WarehouseScreen screen) {
    switch (screen) {
      case WarehouseScreen.dashboard: return const WarehouseDashboard();
      case WarehouseScreen.shipmentIntake: return const ShipmentIntakeScreen();
      case WarehouseScreen.warehouseProcessing: return const WarehouseProcessingScreen();
      case WarehouseScreen.stockDispatch: return const StockDispatchScreen();
      case WarehouseScreen.inventory: return const WarehouseInventoryScreen();
      case WarehouseScreen.orders: return const RequisitionOrdersScreen();
      case WarehouseScreen.damageManagement: return const DamageManagementScreen();
      case WarehouseScreen.reports: return const WarehouseReportsScreen();
      case WarehouseScreen.profile: return const ProfileView();
      case WarehouseScreen.bulkBreakdown: return const BulkBreakdownScreen();
    }
  }
}

// Legacy alias for compatibility
typedef ButcherShell = WarehouseShell;
