// lib/invoices/invoice_list_page.dart
import 'package:flutter/material.dart';

import 'invoice.dart';
import 'invoice_storage.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  final InvoiceStorage _storage = InvoiceStorage();
  List<Invoice> _invoices = <Invoice>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final invoices = await _storage.loadInvoices();
    setState(() {
      _invoices = invoices;
      _isLoading = false;
    });
  }

  Future<void> _saveInvoices() async {
    await _storage.saveInvoices(_invoices);
  }

  double get _totalPaid {
    return _invoices
        .where((i) => i.status == InvoiceStatus.paid)
        .fold<double>(0.0, (sum, i) => sum + i.total);
  }

  double get _totalOutstanding {
    return _invoices
        .where((i) => i.status != InvoiceStatus.paid)
        .fold<double>(0.0, (sum, i) => sum + i.total);
  }

  int get _overdueCount {
    return _invoices.where((i) => i.isOverdue).length;
  }

  Future<void> _createNewInvoice() async {
    final draft = Invoice.newDraft();
    final updated = await Navigator.of(context).push<Invoice>(
      MaterialPageRoute(
        builder: (_) => EditInvoicePage(
          invoice: draft,
          title: 'New invoice',
        ),
      ),
    );

    if (updated != null) {
      setState(() {
        _invoices.add(updated);
      });
      await _saveInvoices();
    }
  }

  Future<void> _editInvoice(Invoice invoice) async {
    final updated = await Navigator.of(context).push<Invoice>(
      MaterialPageRoute(
        builder: (_) => EditInvoicePage(
          invoice: invoice,
          title: 'Edit invoice',
        ),
      ),
    );

    if (updated != null) {
      setState(() {
        final index = _invoices.indexWhere((i) => i.id == updated.id);
        if (index != -1) {
          _invoices[index] = updated;
        }
      });
      await _saveInvoices();
    }
  }

  Future<void> _markAsPaid(Invoice invoice) async {
    setState(() {
      final index = _invoices.indexWhere((i) => i.id == invoice.id);
      if (index != -1) {
        _invoices[index] = invoice.copyWith(status: InvoiceStatus.paid);
      }
    });
    await _saveInvoices();
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete invoice'),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _invoices.removeWhere((i) => i.id == invoice.id);
      });
      await _saveInvoices();
    }
  }

  void _openPreview(Invoice invoice) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoicePreviewPage(invoice: invoice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewInvoice,
        label: const Text('New invoice'),
        icon: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _invoices.isEmpty
                ? _EmptyState(onCreate: _createNewInvoice)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryRow(
                        totalOutstanding: _totalOutstanding,
                        totalPaid: _totalPaid,
                        overdueCount: _overdueCount,
                        currencySymbol: _invoices.first.currencySymbol,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          elevation: 1,
                          child: ListView.separated(
                            itemCount: _invoices.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final invoice = _invoices[index];
                              return ListTile(
                                onTap: () => _openPreview(invoice),
                                onLongPress: () => _editInvoice(invoice),
                                leading: Icon(
                                  invoice.status == InvoiceStatus.paid
                                      ? Icons.check_circle
                                      : invoice.isOverdue
                                          ? Icons.error_outline
                                          : Icons.receipt_long,
                                ),
                                title: Text(
                                  '${invoice.number} • ${invoice.clientName.isEmpty ? 'Unnamed client' : invoice.clientName}',
                                ),
                                subtitle: Text(
                                  'Due ${_formatDate(invoice.dueDate)} • ${_statusLabel(invoice)}',
                                ),
                                trailing: SizedBox(
                                  width: 170,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              _formatMoney(
                                                invoice.total,
                                                invoice.currencySymbol,
                                              ),
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              invoice.status ==
                                                      InvoiceStatus.paid
                                                  ? 'Paid'
                                                  : invoice.isOverdue
                                                      ? 'Overdue'
                                                      : 'Outstanding',
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color: invoice.status ==
                                                        InvoiceStatus.paid
                                                    ? Colors.green
                                                    : invoice.isOverdue
                                                        ? Colors.red
                                                        : theme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editInvoice(invoice);
                                          } else if (value == 'markPaid') {
                                            _markAsPaid(invoice);
                                          } else if (value == 'delete') {
                                            _deleteInvoice(invoice);
                                          } else if (value == 'preview') {
                                            _openPreview(invoice);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'preview',
                                            child: Text('View'),
                                          ),
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem(
                                            value: 'markPaid',
                                            child: Text('Mark as paid'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long, size: 48),
              const SizedBox(height: 16),
              const Text(
                'No invoices yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your first invoice in a few clicks.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Create invoice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double totalOutstanding;
  final double totalPaid;
  final int overdueCount;
  final String currencySymbol;

  const _SummaryRow({
    required this.totalOutstanding,
    required this.totalPaid,
    required this.overdueCount,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Outstanding',
            value: _formatMoney(totalOutstanding, currencySymbol),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Paid',
            value: _formatMoney(totalPaid, currencySymbol),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Overdue',
            value: '$overdueCount',
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${_two(date.month)}-${_two(date.day)}';
}

String _two(int value) => value.toString().padLeft(2, '0');

String _formatMoney(double amount, String currencySymbol) {
  return '$currencySymbol${amount.toStringAsFixed(2)}';
}

String _statusLabel(Invoice invoice) {
  switch (invoice.status) {
    case InvoiceStatus.draft:
      return 'Draft';
    case InvoiceStatus.sent:
      return 'Sent';
    case InvoiceStatus.paid:
      return 'Paid';
  }
}

/// Edit screen for the business owner.
class EditInvoicePage extends StatefulWidget {
  final Invoice invoice;
  final String title;

  const EditInvoicePage({
    super.key,
    required this.invoice,
    required this.title,
  });

  @override
  State<EditInvoicePage> createState() => _EditInvoicePageState();
}

class _EditInvoicePageState extends State<EditInvoicePage> {
  late TextEditingController _clientNameController;
  late TextEditingController _clientEmailController;
  late TextEditingController _notesController;
  late TextEditingController _currencyController;

  late DateTime _issueDate;
  late DateTime _dueDate;
  late InvoiceStatus _status;
  late String _currencySymbol;
  late List<InvoiceItem> _items;

  @override
  void initState() {
    super.initState();
    final invoice = widget.invoice;
    _clientNameController =
        TextEditingController(text: invoice.clientName);
    _clientEmailController =
        TextEditingController(text: invoice.clientEmail ?? '');
    _notesController = TextEditingController(text: invoice.notes ?? '');
    _issueDate = invoice.issueDate;
    _dueDate = invoice.dueDate;
    _status = invoice.status;
    _currencySymbol = invoice.currencySymbol;
    _currencyController = TextEditingController(text: _currencySymbol);
    _items = List<InvoiceItem>.from(invoice.items);
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _notesController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _pickIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _issueDate = picked;
        if (_dueDate.isBefore(_issueDate)) {
          _dueDate = _issueDate.add(const Duration(days: 14));
        }
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: _issueDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _addLineItem() {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _items = List<InvoiceItem>.from(_items)
        ..add(
          InvoiceItem(
            id: id,
            description: '',
            quantity: 1,
            unitPrice: 0,
          ),
        );
    });
  }

  void _updateItemDescription(int index, String value) {
    final item = _items[index];
    _items[index] = item.copyWith(description: value);
  }

  void _updateItemQuantity(int index, String value) {
    final parsed = int.tryParse(value) ?? 0;
    final item = _items[index];
    _items[index] = item.copyWith(quantity: parsed);
  }

  void _updateItemPrice(int index, String value) {
    final cleaned = value.replaceAll(',', '');
    final parsed = double.tryParse(cleaned) ?? 0.0;
    final item = _items[index];
    _items[index] = item.copyWith(unitPrice: parsed);
  }

  void _removeItem(int index) {
    setState(() {
      _items = List<InvoiceItem>.from(_items)..removeAt(index);
      if (_items.isEmpty) {
        _addLineItem();
      }
    });
  }

  void _save() {
    final clientName = _clientNameController.text.trim();
    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a client name')),
      );
      return;
    }

    final nonEmptyItems = _items.where((item) {
      final hasDesc = item.description.trim().isNotEmpty;
      final hasAmount = item.total > 0;
      return hasDesc || hasAmount;
    }).toList();

    if (nonEmptyItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least one line item with an amount')),
      );
      return;
    }

    final updated = widget.invoice.copyWith(
      clientName: clientName,
      clientEmail: _clientEmailController.text.trim().isEmpty
          ? null
          : _clientEmailController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      issueDate: _issueDate,
      dueDate: _dueDate,
      items: nonEmptyItems,
      status: _status,
      currencySymbol: _currencySymbol.trim().isEmpty
          ? widget.invoice.currencySymbol
          : _currencySymbol.trim(),
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _items.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: client + email
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Client name',
                        child: TextField(
                          controller: _clientNameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Who is this invoice for?',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _LabeledField(
                        label: 'Client email (optional)',
                        child: TextField(
                          controller: _clientEmailController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'client@email.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Dates + status
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Issue date',
                        child: OutlinedButton(
                          onPressed: _pickIssueDate,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_formatDate(_issueDate)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _LabeledField(
                        label: 'Due date',
                        child: OutlinedButton(
                          onPressed: _pickDueDate,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_formatDate(_dueDate)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _LabeledField(
                        label: 'Status',
                        child: DropdownButtonFormField<InvoiceStatus>(
                          value: _status,
                          items: const [
                            DropdownMenuItem(
                              value: InvoiceStatus.draft,
                              child: Text('Draft'),
                            ),
                            DropdownMenuItem(
                              value: InvoiceStatus.sent,
                              child: Text('Sent'),
                            ),
                            DropdownMenuItem(
                              value: InvoiceStatus.paid,
                              child: Text('Paid'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _status = value;
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Currency symbol',
                  child: SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _currencyController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '\$',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _currencySymbol = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Line items',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(width: 0.5),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < _items.length; i++)
                        _LineItemRow(
                          index: i,
                          item: _items[i],
                          currencySymbol: _currencySymbol,
                          onDescriptionChanged: (value) {
                            setState(() {
                              _updateItemDescription(i, value);
                            });
                          },
                          onQuantityChanged: (value) {
                            setState(() {
                              _updateItemQuantity(i, value);
                            });
                          },
                          onPriceChanged: (value) {
                            setState(() {
                              _updateItemPrice(i, value);
                            });
                          },
                          onRemove: () => _removeItem(i),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addLineItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add line item'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: ${_formatMoney(total, _currencySymbol)}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                _LabeledField(
                  label: 'Notes (optional)',
                  child: TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText:
                          'Payment terms, bank details, or anything else your client should know.',
                    ),
                    minLines: 3,
                    maxLines: 6,
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: const Text('Save invoice'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _LineItemRow extends StatelessWidget {
  final int index;
  final InvoiceItem item;
  final String currencySymbol;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String> onQuantityChanged;
  final ValueChanged<String> onPriceChanged;
  final VoidCallback onRemove;

  const _LineItemRow({
    required this.index,
    required this.item,
    required this.currencySymbol,
    required this.onDescriptionChanged,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextFormField(
              initialValue: item.description,
              decoration: InputDecoration(
                labelText: index == 0 ? 'Description' : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: onDescriptionChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue:
                  item.quantity == 0 ? '' : item.quantity.toString(),
              decoration: InputDecoration(
                labelText: index == 0 ? 'Qty' : null,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: onQuantityChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: item.unitPrice == 0
                  ? ''
                  : item.unitPrice.toStringAsFixed(2),
              decoration: InputDecoration(
                labelText: index == 0 ? 'Unit price' : null,
                border: const OutlineInputBorder(),
                prefixText: currencySymbol,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: onPriceChanged,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              _formatMoney(item.total, currencySymbol),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            tooltip: 'Remove line',
          ),
        ],
      ),
    );
  }
}

/// Read-only "client view" for the invoice.
class InvoicePreviewPage extends StatelessWidget {
  final Invoice invoice;

  const InvoicePreviewPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.number}'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Your Business Name',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Invoice ${invoice.number}',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text('Issue: ${_formatDate(invoice.issueDate)}'),
                          Text('Due: ${_formatDate(invoice.dueDate)}'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Client info
                  Text(
                    'Bill to:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice.clientName.isEmpty
                        ? 'Client name'
                        : invoice.clientName,
                  ),
                  if (invoice.clientEmail != null &&
                      invoice.clientEmail!.isNotEmpty) ...[
                    Text(invoice.clientEmail!),
                  ],
                  const SizedBox(height: 24),
                  // Line items
                  Table(
                    border: TableBorder.symmetric(
                      inside: const BorderSide(width: 0.5),
                      outside: const BorderSide(width: 0.5),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(5),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(3),
                      3: FlexColumnWidth(3),
                    },
                    children: [
                      const TableRow(
                        decoration:
                            BoxDecoration(color: Color(0xFFEFEFEF)),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Description',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Qty',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Unit price',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      ...invoice.items.map(
                        (item) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                item.description.isEmpty
                                    ? 'Item'
                                    : item.description,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text('${item.quantity}'),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(_formatMoney(
                                item.unitPrice,
                                invoice.currencySymbol,
                              )),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(_formatMoney(
                                item.total,
                                invoice.currencySymbol,
                              )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total: ${_formatMoney(invoice.total, invoice.currencySymbol)}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (invoice.notes != null &&
                      invoice.notes!.trim().isNotEmpty) ...[
                    Text(
                      'Notes',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(invoice.notes!.trim()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
