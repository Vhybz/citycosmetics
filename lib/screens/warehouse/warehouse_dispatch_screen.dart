import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/product.dart';
import '../../models/warehouse_models.dart';
import '../../services/product_service.dart';
import '../../services/user_provider.dart';
import '../../services/warehouse_service.dart';

class WarehouseDispatchScreen extends ConsumerStatefulWidget {
  const WarehouseDispatchScreen({super.key});

  @override
  ConsumerState<WarehouseDispatchScreen> createState() => _WarehouseDispatchScreenState();
}

class _WarehouseDispatchScreenState extends ConsumerState<WarehouseDispatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dispatchNumberController = TextEditingController();
  final TextEditingController _destinationStoreController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _dispatchDate = DateTime.now();
  final List<DispatchItem> _dispatchItems = [];

  // Item Form Fields
  Product? _selectedProduct;
  final TextEditingController _qtyController = TextEditingController();
  WarehouseBatch? _fefoSuggestedBatch;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final randomStr = (1000 + DateTime.now().millisecond % 9000).toString();
    _dispatchNumberController.text = 'DSP-${DateFormat('yyyyMMdd').format(DateTime.now())}-$randomStr';
    _destinationStoreController.text = 'Main Retail Shop';
  }

  @override
  void dispose() {
    _dispatchNumberController.dispose();
    _destinationStoreController.dispose();
    _notesController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  /// FEFO (First Expired, First Out) Batch Selection Logic
  WarehouseBatch? _findFEFOBatch(Product product, List<WarehouseBatch> allBatches) {
    // Filter batches for this product name/category that are in stock
    final productBatches = allBatches.where((b) => 
      b.productName.toLowerCase() == product.name.toLowerCase() &&
      b.quantity > 0
    ).toList();

    if (productBatches.isEmpty) return null;

    // Sort by Expiry Date ascending (earliest expiring first)
    productBatches.sort((a, b) {
      if (a.expiryDate == null && b.expiryDate == null) return 0;
      if (a.expiryDate == null) return 1; // Put no expiry date at end
      if (b.expiryDate == null) return -1;
      return a.expiryDate!.compareTo(b.expiryDate!);
    });

    return productBatches.first;
  }

  void _onProductSelected(Product? product, List<WarehouseBatch> batches) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _fefoSuggestedBatch = _findFEFOBatch(product, batches);
        // Pre-fill suggested replenishment quantity
        final needed = (product.minStoreStock - product.stockQuantity).clamp(1.0, double.infinity);
        final maxPossible = product.warehouseQuantity;
        final suggested = needed <= maxPossible ? needed : maxPossible;
        _qtyController.text = suggested > 0 ? suggested.toInt().toString() : '1';
      } else {
        _fefoSuggestedBatch = null;
        _qtyController.clear();
      }
    });
  }

  void _addItemToDispatch() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product first.'), backgroundColor: Colors.red),
      );
      return;
    }

    final double qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid dispatch quantity (> 0).'), backgroundColor: Colors.red),
      );
      return;
    }

    if (qty > _selectedProduct!.warehouseQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot dispatch $qty Pcs: Exceeds current Warehouse Stock (${_selectedProduct!.warehouseQuantity.toInt()} Pcs available).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newItem = DispatchItem(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      sku: _selectedProduct!.sku ?? _selectedProduct!.id.substring(0, 8),
      quantityDispatched: qty,
      batchNumber: _fefoSuggestedBatch?.batchNumber ?? 'STD-BATCH',
      expiryDate: _fefoSuggestedBatch?.expiryDate,
    );

    setState(() {
      _dispatchItems.add(newItem);
      // Reset Item Fields
      _selectedProduct = null;
      _fefoSuggestedBatch = null;
      _qtyController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${newItem.productName} (${newItem.quantityDispatched.toInt()} Pcs) added to dispatch list.'), backgroundColor: Colors.green),
    );
  }

  Future<void> _confirmDispatch() async {
    if (_formKey.currentState!.validate()) {
      if (_dispatchItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot confirm dispatch: Please add at least one product item to the dispatch list.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final user = ref.read(currentUserProvider);
        final dispatchRecord = WarehouseDispatchRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          dispatchNumber: _dispatchNumberController.text.trim(),
          date: _dispatchDate,
          destinationStore: _destinationStoreController.text.trim(),
          items: List.from(_dispatchItems),
          notes: _notesController.text.trim(),
          dispatchedBy: user != null ? '${user.firstName} ${user.surname}' : 'Warehouse Staff',
          isConfirmed: true,
        );

        await ref.read(warehouseDispatchProvider.notifier).confirmDispatch(dispatchRecord);

        // Refresh products list so stock numbers update instantly in UI
        await ref.read(productProvider.notifier).loadProducts(silent: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dispatch ${dispatchRecord.dispatchNumber} confirmed! Warehouse stock deducted & Store stock updated.'),
              backgroundColor: AppColors.accentGreen,
            ),
          );

          // Reset Form
          setState(() {
            _dispatchItems.clear();
            _notesController.clear();
            final randomStr = (1000 + DateTime.now().millisecond % 9000).toString();
            _dispatchNumberController.text = 'DSP-${DateFormat('yyyyMMdd').format(DateTime.now())}-$randomStr';
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error confirming dispatch: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final products = ref.watch(productProvider).value ?? [];
    final batches = ref.watch(warehouseBatchProvider).value ?? [];

    final lowStoreStockProducts = products.where((p) => p.needsDispatch).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Form(
        key: _formKey,
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
                    backgroundColor: AppColors.accentGreen,
                    child: Icon(Icons.local_shipping_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Store Replenishment Dispatch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Low Store Stock → Create Dispatch → FEFO Batch Selection → Deduct Warehouse → Increase Store Stock', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Low Store Stock Replenishment Alert Banner
            if (lowStoreStockProducts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A1C08) : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(color: Colors.amber.shade600),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Store Replenishment Needed (${lowStoreStockProducts.length} Products Low in Shop)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Click any low-stock product below to pre-select it for dispatch:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: lowStoreStockProducts.map((p) {
                        return ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 14),
                          label: Text('${p.name} (Shop: ${p.stockQuantity.toInt()} Pcs / WHS: ${p.warehouseQuantity.toInt()} Pcs)', style: const TextStyle(fontSize: 11)),
                          backgroundColor: Colors.amber.shade100,
                          onPressed: () => _onProductSelected(p, batches),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),
            ],

            // Dispatch Header Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Dispatch Tracking Header', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dispatchNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Dispatch #',
                            prefixIcon: Icon(Icons.confirmation_number_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: TextFormField(
                          controller: _destinationStoreController,
                          decoration: const InputDecoration(
                            labelText: 'Destination Store',
                            prefixIcon: Icon(Icons.storefront_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter destination store' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dispatchDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _dispatchDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Dispatch Date',
                              prefixIcon: Icon(Icons.calendar_today_rounded),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(DateFormat('yyyy-MM-dd').format(_dispatchDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Dispatch Notes / Requisition Ref',
                            prefixIcon: Icon(Icons.note_alt_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Item Selection & FEFO Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2. Select Product & Pick Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.m),
                  DropdownButtonFormField<Product>(
                    value: _selectedProduct,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Product to Dispatch',
                      prefixIcon: Icon(Icons.inventory_2_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: products.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.name} [SKU: ${p.sku ?? p.id.substring(0, 8)}] (WHS: ${p.warehouseQuantity.toInt()} Pcs | Shop: ${p.stockQuantity.toInt()} Pcs)'),
                      );
                    }).toList(),
                    onChanged: (p) => _onProductSelected(p, batches),
                  ),

                  if (_selectedProduct != null) ...[
                    const SizedBox(height: AppSpacing.m),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(AppRadius.s),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text('Stock Overview for ${_selectedProduct!.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Available Warehouse Stock: ${_selectedProduct!.warehouseQuantity.toInt()} Pcs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                              Text('Current Store Stock: ${_selectedProduct!.stockQuantity.toInt()} Pcs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade800)),
                              Text('Min Threshold: ${_selectedProduct!.minStoreStock.toInt()} Pcs', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),

                          // FEFO Batch Suggestion
                          if (_fefoSuggestedBatch != null) ...[
                            const Divider(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: Colors.orange, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'FEFO Suggested Batch: ${_fefoSuggestedBatch!.batchNumber} '
                                  '(${_fefoSuggestedBatch!.expiryDate != null ? "Expires: ${DateFormat('yyyy-MM-dd').format(_fefoSuggestedBatch!.expiryDate!)}" : "No expiry date"})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          decoration: const InputDecoration(
                            labelText: 'Dispatch Quantity (Pcs)',
                            prefixIcon: Icon(Icons.numbers_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      ElevatedButton.icon(
                        onPressed: _addItemToDispatch,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('ADD TO DISPATCH LIST', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Multi-item Review Table
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('3. Review Dispatch Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Chip(
                        label: Text('${_dispatchItems.length} Products | Total: ${_dispatchItems.fold(0.0, (s, i) => s + i.quantityDispatched).toInt()} Pcs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  if (_dispatchItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No products added to dispatch list yet. Select a product above and click "ADD TO DISPATCH LIST".',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 40,
                        dataRowMinHeight: 48,
                        columns: const [
                          DataColumn(label: Text('Product / SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Quantity Dispatched', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Batch #', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Remove', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _dispatchItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return DataRow(
                            cells: [
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('SKU: ${item.sku}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              )),
                              DataCell(Text('${item.quantityDispatched.toInt()} Pcs', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                              DataCell(Text(item.batchNumber ?? 'STD-BATCH')),
                              DataCell(Text(item.expiryDate != null ? DateFormat('yyyy-MM-dd').format(item.expiryDate!) : 'N/A')),
                              DataCell(IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => setState(() => _dispatchItems.removeAt(idx)),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Final Confirmation Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _confirmDispatch,
                icon: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isSubmitting ? 'CONFIRMING DISPATCH...' : 'CONFIRM DISPATCH (DEDUCT WAREHOUSE & ADD TO STORE)',
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
