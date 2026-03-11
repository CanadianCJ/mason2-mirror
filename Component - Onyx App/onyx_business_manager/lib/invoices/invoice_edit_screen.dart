// lib/invoices/invoice_edit_screen.dart
import 'package:flutter/material.dart';
import 'models.dart';

class InvoiceEditScreen extends StatefulWidget {
  final Invoice? existing;

  const InvoiceEditScreen({super.key, this.existing});

  @override
  State<InvoiceEditScreen> createState() => _InvoiceEditScreenState();
}

class _InvoiceEditScreenState extends State<InvoiceEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _customerNameController;
  late TextEditingController _customerEmailController;
  late TextEditingController _invoiceNumberController;
  late TextEditingController _notesController;
  late TextEditingController _paymentInstructionsController;
  late TextEditingController _taxRateController;

  late DateTime _issueDate;
  late DateTime _dueDate;
  late InvoiceStatus _status;
  late String _currencyCode;

  final List<_LineItemControllers> _lineItems = [];

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    _customerNameController =
        TextEditingController(text: existing?.customerName ?? '');
    _customerEmailController =
        TextEditingController(text: existing?.customerEmail ?? '');
    _invoiceNumberController =
        TextEditingController(text: existing?.invoiceNumber ?? _defaultInvoiceNumber());
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _paymentInstructionsController =
        TextEditingController(text: existing?.paymentInstructions ?? '');
    _taxRateController = TextEditingController(
      text: existing?.taxRatePercent?.toString() ?? '',
    );

    _issueDate = existing?.issueDate ?? DateTime.now();
    _dueDate = existing?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _status = existing?.status ?? InvoiceStatus.draft;
    _currencyCode = existing?.currencyCode ?? 'CAD';

    if (existing != null && existing.items.isNotEmpty) {
      for (final item in existing.items) {
        _lineItems.add(
          _LineItemControllers(
            description: item.description,
            quantity: item.quantity.toString(),
            unitPrice: item.unitPrice.toString(),
          ),
        );
      }
    } else {
      _lineItems.add(
        _LineItemControllers(
          description: '',
          quantity: '1',
          unitPrice: '0',
        ),
      );
    }
  }

  String _defaultInvoiceNumber() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'INV-$y$m$d';
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _paymentInstructionsController.dispose();
    _taxRateController.dispose();
    for (final li in _lineItems) {
      li.dispose();
    }
    super.dispose();
  }

  double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }

  double _calculateSubtotal() {
    double sum = 0.0;
    for (final li in _lineItems) {
      final qty = _parseDouble(li.quantityController.text);
      final price = _parseDouble(li.unitPriceController.text);
      sum += qty * price;
    }
    return sum;
  }

  String _formatMoney(double value) {
    return '$_currencyCode ${value.toStringAsFixed(2)}';
  }

  Future<void> _pickDate({
    required bool isIssueDate,
  }) async {
    final initial = isIssueDate ? _issueDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  String _statusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Build line items
    final items = <InvoiceLine>[];
    for (final li in _lineItems) {
      final desc = li.descriptionController.text.trim();
      final qty = _parseDouble(li.quantityController.text);
      final price = _parseDouble(li.unitPriceController.text);
      if (desc.isEmpty || (qty == 0 && price == 0)) {
        continue;
      }
      items.add(
        InvoiceLine(
          description: desc,
          quantity: qty == 0 ? 1 : qty,
          unitPrice: price,
        ),
      );
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one line item.'),
        ),
      );
      return;
    }

    final taxRate = _taxRateController.text.trim().isEmpty
        ? null
        : _parseDouble(_taxRateController.text.trim());

    final existing = widget.existing;
    final invoice = Invoice(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNumber: _invoiceNumberController.text.trim(),
      customerName: _customerNameController.text.trim(),
      customerEmail:
          _customerEmailController.text.trim().isEmpty ? null : _customerEmailController.text.trim(),
      issueDate: _issueDate,
      dueDate: _dueDate,
      status: _status,
      items: items,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      paymentInstructions: _paymentInstructionsController.text.trim().isEmpty
          ? null
          : _paymentInstructionsController.text.trim(),
      currencyCode: _currencyCode,
      taxRatePercent: taxRate,
    );

    Navigator.of(context).pop(invoice);
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(
        _LineItemControllers(
          description: '',
          quantity: '1',
          unitPrice: '0',
        ),
      );
    });
  }

  void _removeLineItem(int index) {
    if (_lineItems.length == 1) return;
    setState(() {
      final li = _lineItems.removeAt(index);
      li.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal();
    final taxRate = _taxRateController.text.trim().isEmpty
        ? 0.0
        : _parseDouble(_taxRateController.text.trim());
    final taxAmount = subtotal * (taxRate / 100.0);
    final total = subtotal + taxAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Invoice' : 'Edit Invoice'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: Client
                const Text(
                  'Client',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Customer name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customerEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Customer email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),
                // Section: Invoice basics
                const Text(
                  'Invoice details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _invoiceNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Invoice number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Issue date'),
                        subtitle: Text(_formatDate(_issueDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _pickDate(isIssueDate: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Due date'),
                        subtitle: Text(_formatDate(_dueDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _pickDate(isIssueDate: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<InvoiceStatus>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: InvoiceStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_statusLabel(status)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _status = value;
                    });
                  },
                ),

                const SizedBox(height: 16),
                // Section: Line items
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Line items',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addLineItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add item'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: List.generate(_lineItems.length, (index) {
                    final li = _lineItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: li.descriptionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Description',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeLineItem(index),
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Remove item',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: li.quantityController,
                                    decoration: const InputDecoration(
                                      labelText: 'Quantity',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: li.unitPriceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Price per unit',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),
                // Section: Tax + totals
                const Text(
                  'Totals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _taxRateController,
                  decoration: const InputDecoration(
                    labelText: 'Tax % (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                Text('Subtotal: ${_formatMoney(subtotal)}'),
                Text('Tax: ${_formatMoney(taxAmount)}'),
                Text(
                  'Total: ${_formatMoney(total)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),
                // Section: Notes & payment
                const Text(
                  'Notes & payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _paymentInstructionsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'How to pay (e-transfer, bank details, etc.)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _LineItemControllers {
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;

  _LineItemControllers({
    String description = '',
    String quantity = '1',
    String unitPrice = '0',
  })  : descriptionController = TextEditingController(text: description),
        quantityController = TextEditingController(text: quantity),
        unitPriceController = TextEditingController(text: unitPrice);

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}
