import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../move/presentation/pages/item_lookup_scan_dialog.dart';
import '../../domain/entities/inbound_entities.dart';
import '../controllers/inbound_controller.dart';

class CreateInboundPage extends StatefulWidget {
  const CreateInboundPage({
    super.key,
    this.initialDocumentNumber,
    this.initialSupplier,
  });

  final String? initialDocumentNumber;
  final String? initialSupplier;

  @override
  State<CreateInboundPage> createState() => _CreateInboundPageState();
}

class _CreateInboundPageState extends State<CreateInboundPage> {
  final _poController = TextEditingController();
  final _supplierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<_InboundCreateItemRow> _rows = [];
  bool _isSaving = false;
  String? _prefilledPo;
  bool _listeningForPoChanges = false;

  @override
  void initState() {
    super.initState();
    final po = widget.initialDocumentNumber?.trim() ?? '';
    final supplier = widget.initialSupplier?.trim() ?? '';
    if (po.isNotEmpty) {
      _poController.text = po;
    }
    if (supplier.isNotEmpty) {
      _supplierController.text = supplier;
    }

    _addRow();

    if (po.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final inboundController = context.read<InboundController>();
        _applyPoTemplate(inboundController);
        inboundController.addListener(_applyPoTemplateFromController);
        _listeningForPoChanges = true;
      });
    }
  }

  void _applyPoTemplateFromController() {
    if (!mounted) return;
    _applyPoTemplate(context.read<InboundController>());
  }

  @override
  void dispose() {
    if (_listeningForPoChanges) {
      context.read<InboundController>().removeListener(
            _applyPoTemplateFromController,
          );
    }
    _poController.dispose();
    _supplierController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _applyPoTemplate(InboundController controller) {
    final po = _poController.text.trim();
    if (po.isEmpty || _prefilledPo == po) return;

    final matching = controller.documents
        .where((doc) => doc.documentNumber == po)
        .toList();
    if (matching.isEmpty) {
      if (controller.documents.isNotEmpty) {
        _prefilledPo = po;
      }
      return;
    }

    final template = matching.first;
    final supplierValue = template.supplierName.trim();
    if (supplierValue.isNotEmpty) {
      _supplierController.text = supplierValue;
    }

    final templateRows = <_InboundCreateItemRow>[];
    for (final item in template.items) {
      templateRows.add(
        _InboundCreateItemRow(
          barcode: item.barcode,
          expectedQuantity: item.expectedQuantity.toString(),
        ),
      );
    }

    if (templateRows.isEmpty) {
      templateRows.add(_InboundCreateItemRow());
    }

    for (final row in _rows) {
      row.dispose();
    }
    _rows
      ..clear()
      ..addAll(templateRows);

    _prefilledPo = po;
    if (mounted) setState(() {});
  }

  void _addRow() {
    setState(() {
      _rows.add(_InboundCreateItemRow());
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      final row = _rows.removeAt(index);
      row.dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final po = _poController.text.trim();
    final supplier = _supplierController.text.trim();
    if (po.isEmpty || supplier.isEmpty) return;

    final items = <CreateInboundItem>[];
    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final barcode = row.barcodeController.text.trim();
      final qtyText = row.quantityController.text.trim();
      final qty = int.tryParse(qtyText) ?? 0;
      if (barcode.isEmpty || qty <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Row ${i + 1}: barcode and quantity are required')),
        );
        return;
      }
      items.add(
        CreateInboundItem(
          itemId: 2000 + i,
          itemName: 'Product ${i + 1}',
          barcode: barcode,
          expectedQuantity: qty,
          toLocation: 'A01-01-01',
        ),
      );
    }

    setState(() => _isSaving = true);
    try {
      await context.read<InboundController>().createInboundDocument(
            CreateInboundParams(
              documentNumber: po,
              supplierName: supplier,
              items: items,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create receipt: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _importProductFromScan(int index) async {
    final barcode = await showItemLookupScanDialog(
      context,
      title: 'Scan product barcode',
      hintText: 'Scan barcode',
    );
    final value = barcode?.trim() ?? '';
    if (value.isEmpty || index < 0 || index >= _rows.length) return;
    setState(() {
      _rows[index].barcodeController.text = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_isSaving &&
        _poController.text.trim().isNotEmpty &&
        _supplierController.text.trim().isNotEmpty &&
        _rows.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Receipt')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _poController,
                decoration: const InputDecoration(
                  labelText: 'PO Number',
                  hintText: 'PO.00..',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'PO number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier',
                  prefixIcon: Icon(Icons.business),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Supplier is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Products in PO',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              ..._rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: row.barcodeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Product Barcode',
                                    prefixIcon: Icon(Icons.qr_code),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Barcode is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: () => _importProductFromScan(index),
                                icon: const Icon(Icons.qr_code_scanner),
                                tooltip: 'Scan barcode',
                                color: AppTheme.primary,
                              ),
                              if (_rows.length > 1)
                                IconButton(
                                  onPressed: () => _removeRow(index),
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Remove row',
                                  color: AppTheme.warning,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: row.quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Expected Quantity',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            validator: (value) {
                              final parsed = int.tryParse(value?.trim() ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Expected quantity is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add product'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: canSave ? _submit : null,
                icon: const Icon(Icons.save),
                label: Text(_isSaving ? 'Creating...' : 'Create Receipt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboundCreateItemRow {
  _InboundCreateItemRow({String? barcode, String? expectedQuantity}) {
    if (barcode != null) barcodeController.text = barcode;
    if (expectedQuantity != null) quantityController.text = expectedQuantity;
  }

  final barcodeController = TextEditingController();
  final quantityController = TextEditingController();

  void dispose() {
    barcodeController.dispose();
    quantityController.dispose();
  }
}
