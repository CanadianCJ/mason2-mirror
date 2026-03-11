// lib/invoices/invoices_list_screen.dart
import 'package:flutter/material.dart';
import 'models.dart';
import 'invoice_edit_screen.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  final List<Invoice> _invoices = [];

  @override
  void initState() {
    super.initState();

    // One sample invoice so the screen isn't empty.
    _invoices.add(
      Invoice(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        invoiceNumber: 'INV-0001',
        customerName: 'Sample Client',
        customerEmail: 'client@example.com',
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        status: InvoiceStatus.draft,
        items: const [
          InvoiceLine(
            description: 'Sample service',
            quantity: 2,
            unitPrice: 100,
          ),
        ],
        notes: 'Thanks for your business!',
        paymentInstructions: 'E-transfer to you@example.com',
        currencyCode: 'CAD',
        taxRatePercent: 0,
      ),
    );
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

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatMoney(double value, String currency) {
    return '$currency ${value.toStringAsFixed(2)}';
  }

  Future<void> _createInvoice() async {
    final created = await Navigator.push<Invoice>(
      context,
      MaterialPageRoute(
        builder: (_) => const InvoiceEditScreen(),
      ),
    );

    if (!mounted) return;

    if (created != null) {
      setState(() {
        _invoices.add(created);
      });
    }
  }

  Future<void> _editInvoice(Invoice invoice) async {
    final updated = await Navigator.push<Invoice>(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceEditScreen(existing: invoice),
      ),
    );

    if (!mounted) return;

    if (updated != null) {
      setState(() {
        final index = _invoices.indexWhere((i) => i.id == updated.id);
        if (index != -1) {
          _invoices[index] = updated;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createInvoice,
        child: const Icon(Icons.add),
      ),
      body: _invoices.isEmpty
          ? const Center(
              child: Text('No invoices yet. Tap + to create one.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _invoices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final invoice = _invoices[index];
                return ListTile(
                  title: Text(
                    '${invoice.invoiceNumber} • ${invoice.customerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Due ${_formatDate(invoice.dueDate)} • ${_statusLabel(invoice.status)}',
                  ),
                  trailing: Text(
                    _formatMoney(invoice.total, invoice.currencyCode),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _editInvoice(invoice),
                );
              },
            ),
    );
  }
}
