import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/l10n/l10n.dart';
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

  String _tr(String english, String arabic, [String? urdu]) => context.trText(
        english: english,
        arabic: arabic,
        urdu: urdu,
      );

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
          SnackBar(
            content: Text(
              _tr(
                'Row ${i + 1}: barcode and quantity are required',
                'الصف ${i + 1}: الباركود والكمية مطلوبان',
                'قطار ${i + 1}: بارکوڈ اور مقدار ضروری ہیں',
              ),
            ),
          ),
        );
        return;
      }
      items.add(
        CreateInboundItem(
          itemId: 2000 + i,
          itemName: _tr(
            'Product ${i + 1}',
            'منتج ${i + 1}',
            'پروڈکٹ ${i + 1}',
          ),
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
        SnackBar(
          content: Text(
            _tr(
              'Failed to create receipt: $e',
              'فشل إنشاء الاستلام: $e',
              'رسید بنانے میں ناکامی: $e',
            ),
          ),
        ),
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
      title: _tr(
        'Scan product barcode',
        'امسح باركود الصنف',
        'پروڈکٹ بارکوڈ اسکین کریں',
      ),
      hintText: _tr(
        'Scan barcode',
        'امسح الباركود',
        'بارکوڈ اسکین کریں',
      ),
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
      appBar: AppBar(
        title: Text(
          _tr('Create Receipt', 'إنشاء استلام', 'رسید بنائیں'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _poController,
                decoration: InputDecoration(
                  labelText: _tr(
                    'PO Number',
                    'رقم أمر الشراء',
                    'پی او نمبر',
                  ),
                  hintText: 'PO.00..',
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _tr(
                      'PO number is required',
                      'رقم أمر الشراء مطلوب',
                      'پی او نمبر ضروری ہے',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _supplierController,
                decoration: InputDecoration(
                  labelText: _tr('Supplier', 'المورد', 'سپلائر'),
                  prefixIcon: const Icon(Icons.business),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _tr(
                      'Supplier is required',
                      'اسم المورد مطلوب',
                      'سپلائر ضروری ہے',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Text(
                _tr(
                  'Products in PO',
                  'المنتجات في أمر الشراء',
                  'پی او میں مصنوعات',
                ),
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
                                  decoration: InputDecoration(
                                    labelText: _tr(
                                      'Product Barcode',
                                      'باركود الصنف',
                                      'پروڈکٹ بارکوڈ',
                                    ),
                                    prefixIcon: const Icon(Icons.qr_code),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return _tr(
                                        'Barcode is required',
                                        'الباركود مطلوب',
                                        'بارکوڈ ضروری ہے',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: () => _importProductFromScan(index),
                                icon: const Icon(Icons.qr_code_scanner),
                                tooltip: _tr(
                                  'Scan barcode',
                                  'امسح الباركود',
                                  'بارکوڈ اسکین کریں',
                                ),
                                color: AppTheme.primary,
                              ),
                              if (_rows.length > 1)
                                IconButton(
                                  onPressed: () => _removeRow(index),
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: _tr(
                                    'Remove row',
                                    'حذف الصف',
                                    'قطار حذف کریں',
                                  ),
                                  color: AppTheme.warning,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: row.quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: _tr(
                                'Expected Quantity',
                                'الكمية المتوقعة',
                                'متوقع مقدار',
                              ),
                              prefixIcon: const Icon(Icons.numbers),
                            ),
                            validator: (value) {
                              final parsed = int.tryParse(value?.trim() ?? '');
                              if (parsed == null || parsed <= 0) {
                                return _tr(
                                  'Expected quantity is required',
                                  'الكمية المتوقعة مطلوبة',
                                  'متوقع مقدار ضروری ہے',
                                );
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
                  label: Text(
                    _tr('Add product', 'إضافة منتج', 'پروڈکٹ شامل کریں'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: canSave ? _submit : null,
                icon: const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? _tr('Creating...', 'جارٍ الإنشاء...', 'بنایا جا رہا ہے...')
                      : _tr(
                          'Create Receipt',
                          'إنشاء استلام',
                          'رسید بنائیں',
                        ),
                ),
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
