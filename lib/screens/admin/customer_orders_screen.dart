import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/customer_order_model.dart';
import '../../services/customer_order_service.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/role_pop_scope.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';

class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  ConsumerState<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ordersAsync = ref.watch(customerOrdersProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/orders';

    final List<CustomerOrder> allOrders = ordersAsync.value ?? [];

    final filteredOrders = allOrders.where((order) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          order.orderNumber.toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query) ||
          order.customerPhone.contains(query) ||
          (order.businessName != null && order.businessName!.toLowerCase().contains(query));

      if (!matchesQuery) return false;

      if (_selectedStatusFilter == 'All') return true;
      if (_selectedStatusFilter == 'Pending') return order.isPending;
      if (_selectedStatusFilter == 'Approved') return order.isApproved;
      if (_selectedStatusFilter == 'Dispatched') return order.isDispatched;
      if (_selectedStatusFilter == 'Paid via Paystack') return order.isPaidViaPaystack;

      return order.status == _selectedStatusFilter;
    }).toList();

    return RolePopScope(
      currentRoute: currentRoute,
      child: Scaffold(
        appBar: MainAppBar(
          title: 'Incoming Customer Orders',
          onProfileTap: () => Navigator.pushNamed(context, '/profile'),
        ),
        drawer: isDesktop
            ? null
            : Drawer(
                child: AppSidebar(
                  items: ref.watch(menuItemsProvider),
                  currentRoute: currentRoute,
                  userName: user.name,
                  userRole: user.activePrimaryRole.name,
                  userId: user.id,
                  onTap: (route) => MenuService.navigate(context, ref, route, currentRoute),
                ),
              ),
        body: Row(
          children: [
            if (isDesktop)
              AppSidebar(
                items: ref.watch(menuItemsProvider),
                currentRoute: currentRoute,
                userName: user.name,
                userRole: user.activePrimaryRole.name,
                userId: user.id,
                onTap: (route) => MenuService.navigate(context, ref, route, currentRoute),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(AppRadius.m),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.shopping_bag_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Customer B2B Orders Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('Live orders submitted from the Customer App (${allOrders.length} Total Orders)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.l),

                    // Search & Filters Bar
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search by Order #, Customer Name, Phone, or Shop...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = ''))
                                  : null,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.m),

                    // Status Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Pending', 'Approved', 'Dispatched', 'Paid via Paystack'].map((status) {
                          final isSelected = _selectedStatusFilter == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(status, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : theme.colorScheme.onSurface)),
                              selected: isSelected,
                              selectedColor: Colors.blue.shade700,
                              onSelected: (selected) => setState(() => _selectedStatusFilter = status),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.l),

                    // Orders List
                    if (filteredOrders.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(AppRadius.m),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No customer orders found.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _CustomerOrderCard(order: order, isDark: isDark);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerOrderCard extends StatefulWidget {
  final CustomerOrder order;
  final bool isDark;

  const _CustomerOrderCard({required this.order, required this.isDark});

  @override
  State<_CustomerOrderCard> createState() => _CustomerOrderCardState();
}

class _CustomerOrderCardState extends State<_CustomerOrderCard> {
  bool _isExpanded = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'approved':
      case 'processing': return Colors.blue;
      case 'dispatched': return Colors.indigo;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    final statusColor = _getStatusColor(order.status);

    return Consumer(
      builder: (context, ref, child) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.m),
          elevation: widget.isDark ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.m),
            side: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.2),
          ),
          child: Column(
            children: [
              // Order Card Header
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(AppRadius.m),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: Text('#${order.orderNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                            child: Text(order.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                          ),
                          if (order.isPaidViaPaystack) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                              child: const Text('PAYSTACK PAID ✓', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                          const Spacer(),
                          IconButton(
                            icon: Icon(_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Colors.blue),
                            onPressed: () => setState(() => _isExpanded = !_isExpanded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${order.customerName} ${order.businessName != null ? "(${order.businessName})" : ""}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('GHS ${order.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: ${order.customerPhone} • Placed: ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Order Breakdown & Action Buttons
              if (_isExpanded) ...[
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  color: widget.isDark ? const Color(0xFF182030) : Colors.blue.shade50.withValues(alpha: 0.2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Line Items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 8),
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            Expanded(child: Text('${item.productName} [SKU: ${item.sku}]', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                            Text('${item.quantity.toInt()} ${item.unitType} (${item.totalPcs.toInt()} Pcs)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(width: 12),
                            Text('GHS ${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (order.isPending) ...[
                            ElevatedButton.icon(
                              onPressed: () => ref.read(customerOrdersProvider.notifier).approveOrder(order.id),
                              icon: const Icon(Icons.check_circle_outlined, size: 16),
                              label: const Text('APPROVE ORDER'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (order.isApproved) ...[
                            ElevatedButton.icon(
                              onPressed: () => ref.read(customerOrdersProvider.notifier).dispatchOrder(order.id),
                              icon: const Icon(Icons.local_shipping_rounded, size: 16),
                              label: const Text('DISPATCH ORDER'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (order.status == 'dispatched') ...[
                            ElevatedButton.icon(
                              onPressed: () => ref.read(customerOrdersProvider.notifier).markDelivered(order.id),
                              icon: const Icon(Icons.verified_rounded, size: 16),
                              label: const Text('MARK DELIVERED & PAID'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (order.status != 'cancelled' && order.status != 'delivered')
                            OutlinedButton.icon(
                              onPressed: () => ref.read(customerOrdersProvider.notifier).cancelOrder(order.id),
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: const Text('CANCEL'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
