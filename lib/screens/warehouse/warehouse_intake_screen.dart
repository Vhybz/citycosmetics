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

class WarehouseIntakeScreen extends ConsumerStatefulWidget {
  const WarehouseIntakeScreen({super.key});

  @override
  ConsumerState<WarehouseIntakeScreen> createState() => _WarehouseIntakeScreenState();
}

class _WarehouseIntakeScreenState extends ConsumerState<WarehouseIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _intakeNumberController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _intakeDate = DateTime.now();
  final List<IntakeItem> _intakeItems = [];

  // Current Item Form Fields
  Product? _selectedProduct;
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  DateTime? _itemExpiryDate;
  ProductCondition _itemCondition = ProductCondition.good;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final randomStr = (1000 + DateTime.now().millisecond % 9000).toString();
    _intakeNumberController.text = 'INT-${DateFormat('yyyyMMdd').format(DateTime.now())}-$randomStr';
  }

  @override
  void dispose() {
    _intakeNumberController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    _qtyController.dispose();
    _batchController.dispose();
    _locationController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  void _addItemToIntake() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product first.'), backgroundColor: Colors.red),
      );
      return;
    }

    final double qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid received quantity (> 0).'), backgroundColor: Colors.red),
      );
      return;
    }

    final batch = _batchController.text.trim().isEmpty 
        ? 'BATCH-${DateFormat('yyyyMM').format(DateTime.now())}' 
        : _batchController.text.trim();

    final newItem = IntakeItem(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      sku: _selectedProduct!.sku ?? _selectedProduct!.id.substring(0, 8),
      category: _selectedProduct!.category,
      brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : _selectedProduct!.brand,
      quantityReceived: qty,
      batchNumber: batch,
      expiryDate: _itemExpiryDate,
      condition: _itemCondition,
      warehouseLocation: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : 'Section A',
    );

    setState(() {
      _intakeItems.add(newItem);
      // Reset Item Fields
      _selectedProduct = null;
      _qtyController.clear();
      _batchController.clear();
      _locationController.clear();
      _brandController.clear();
      _itemExpiryDate = null;
      _itemCondition = ProductCondition.good;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${newItem.productName} (${newItem.quantityReceived.toInt()} Pcs) added to intake list.'), backgroundColor: Colors.green),
    );
  }

  Future<void> _confirmIntake() async {
    if (_formKey.currentState!.validate()) {
      if (_intakeItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot confirm intake: Please add at least one product item to the intake list.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final user = ref.read(currentUserProvider);
        final intakeRecord = WarehouseIntakeRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          intakeNumber: _intakeNumberController.text.trim(),
          date: _intakeDate,
          supplierName: _supplierController.text.trim(),
          items: List.from(_intakeItems),
          notes: _notesController.text.trim(),
          receivedBy: user != null ? '${user.firstName} ${user.surname}' : 'Warehouse Staff',
          isConfirmed: true,
        );

        await ref.read(warehouseIntakeProvider.notifier).confirmIntake(intakeRecord);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Intake ${intakeRecord.intakeNumber} confirmed! Stock added to warehouse.'),
              backgroundColor: AppColors.accentGreen,
            ),
          );

          // Reset Form
          setState(() {
            _intakeItems.clear();
            _supplierController.clear();
            _notesController.clear();
            final randomStr = (1000 + DateTime.now().millisecond % 9000).toString();
            _intakeNumberController.text = 'INT-${DateFormat('yyyyMMdd').format(DateTime.now())}-$randomStr';
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error confirming intake: $e'), backgroundColor: Colors.red),
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
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.move_to_inbox_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Goods Intake Workflow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Supplier → Receive Goods → Check Goods → Record Intake → Add to Warehouse Stock', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Intake Header Form Card
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
                  const Text('1. Intake Summary Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.m),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _intakeNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Intake Tracking #',
                                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: TextFormField(
                                  controller: _supplierController,
                                  decoration: const InputDecoration(
                                    labelText: 'Supplier Name',
                                    hintText: 'e.g. L\'Oréal Ghana / Beauty Wholesale',
                                    prefixIcon: Icon(Icons.business_rounded),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter supplier name' : null,
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
                                      initialDate: _intakeDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) setState(() => _intakeDate = picked);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Arrival Date',
                                      prefixIcon: Icon(Icons.calendar_today_rounded),
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(DateFormat('yyyy-MM-dd').format(_intakeDate)),
                                  ),
                                ),
                              ),
                              if (isWide) const SizedBox(width: AppSpacing.m),
                              if (isWide)
                                Expanded(
                                  child: TextFormField(
                                    controller: _notesController,
                                    decoration: const InputDecoration(
                                      labelText: 'General Notes / Invoice #',
                                      prefixIcon: Icon(Icons.note_alt_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (!isWide) ...[
                            const SizedBox(height: AppSpacing.m),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'General Notes / Invoice #',
                                prefixIcon: Icon(Icons.note_alt_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Item Entry Form Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2. Add Products to Intake List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.m),
                  DropdownButtonFormField<Product>(
                    value: _selectedProduct,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Product / SKU',
                      prefixIcon: Icon(Icons.inventory_2_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: products.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.name} [SKU: ${p.sku ?? p.id.substring(0, 8)}] (${p.category})'),
                      );
                    }).toList(),
                    onChanged: (p) {
                      setState(() {
                        _selectedProduct = p;
                        if (p?.brand != null) _brandController.text = p!.brand!;
                        if (p?.warehouseLocation != null) _locationController.text = p!.warehouseLocation!;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          decoration: const InputDecoration(
                            labelText: 'Quantity Received (Pcs)',
                            prefixIcon: Icon(Icons.numbers_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: TextFormField(
                          controller: _batchController,
                          decoration: const InputDecoration(
                            labelText: 'Batch Number',
                            hintText: 'e.g. BATCH-2026-A',
                            prefixIcon: Icon(Icons.qr_code_rounded),
                            border: OutlineInputBorder(),
                          ),
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
                              initialDate: _itemExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) setState(() => _itemExpiryDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Expiry Date',
                              prefixIcon: Icon(Icons.event_outlined),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_itemExpiryDate != null 
                              ? DateFormat('yyyy-MM-dd').format(_itemExpiryDate!) 
                              : 'Select Expiry Date'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: DropdownButtonFormField<ProductCondition>(
                          value: _itemCondition,
                          decoration: const InputDecoration(
                            labelText: 'Item Condition',
                            prefixIcon: Icon(Icons.health_and_safety_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: ProductCondition.values.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()));
                          }).toList(),
                          onChanged: (c) => setState(() => _itemCondition = c!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Warehouse Location',
                            hintText: 'e.g. Aisle 2-B / Shelf 4',
                            prefixIcon: Icon(Icons.place_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: 'Brand / Manufacturer',
                            hintText: 'e.g. Anua / CeraVe',
                            prefixIcon: Icon(Icons.branding_watermark_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _addItemToIntake,
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: const Text('ADD PRODUCT TO INTAKE LIST', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Multi-item Table Review Card
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
                      const Text('3. Review Intake Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Chip(
                        label: Text('${_intakeItems.length} Products | Total: ${_intakeItems.fold(0.0, (s, i) => s + i.quantityReceived).toInt()} Pcs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  if (_intakeItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No product items added yet. Select a product above and click "ADD PRODUCT TO INTAKE LIST".',
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
                          DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Qty Received', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Batch #', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Condition', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Remove', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _intakeItems.asMap().entries.map((entry) {
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
                              DataCell(Text(item.category)),
                              DataCell(Text('${item.quantityReceived.toInt()} Pcs', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                              DataCell(Text(item.batchNumber)),
                              DataCell(Text(item.expiryDate != null ? DateFormat('yyyy-MM-dd').format(item.expiryDate!) : 'N/A')),
                              DataCell(Text(item.condition.name.toUpperCase(), style: TextStyle(color: item.condition == ProductCondition.good ? Colors.green : Colors.red))),
                              DataCell(Text(item.warehouseLocation ?? 'Section A')),
                              DataCell(IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => setState(() => _intakeItems.removeAt(idx)),
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
                onPressed: _isSubmitting ? null : _confirmIntake,
                icon: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isSubmitting ? 'CONFIRMING INTAKE...' : 'CONFIRM INTAKE & ADD TO WAREHOUSE STOCK',
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
