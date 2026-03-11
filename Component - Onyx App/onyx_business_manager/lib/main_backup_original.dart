import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const OnyxApp());
}

/// Root Onyx app
class OnyxApp extends StatelessWidget {
  const OnyxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onyx Business Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const OnyxHomePage(),
    );
  }
}

/// Simple business profile – stage 1
class BusinessProfile {
  String businessName;
  String ownerName;
  String email;
  String phone;
  String address;

  BusinessProfile({
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
  });

  bool get isComplete =>
      businessName.isNotEmpty &&
      ownerName.isNotEmpty &&
      email.isNotEmpty &&
      address.isNotEmpty;
}

enum InvoiceStatus { draft, sent, paid, overdue }

extension InvoiceStatusLabel on InvoiceStatus {
  String get label {
    switch (this) {
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

  Color color(ColorScheme scheme) {
    switch (this) {
      case InvoiceStatus.draft:
        return scheme.secondary;
      case InvoiceStatus.sent:
        return scheme.primary;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
    }
  }
}

class Client {
  final String name;
  final String email;
  final String phone;

  Client({
    required this.name,
    required this.email,
    required this.phone,
  });
}

class InvoiceLineItem {
  final String description;
  final int quantity;
  final double unitPrice;

  InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final Client client;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceLineItem> items;
  InvoiceStatus status;
  final String? notes;
  final String? paymentLink;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.client,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.status,
    this.notes,
    this.paymentLink,
  });

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.total);

  double get total => subtotal;

  bool get isOverdue =>
      status != InvoiceStatus.paid &&
      DateTime.now().isAfter(
        DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59),
      );

  bool get isPaid => status == InvoiceStatus.paid;
}

/// Home page – simple overview + invoice list
class OnyxHomePage extends StatefulWidget {
  const OnyxHomePage({super.key});

  @override
  State<OnyxHomePage> createState() => _OnyxHomePageState();
}

enum InvoiceFilter { all, dueSoon, overdue, paid }

class _OnyxHomePageState extends State<OnyxHomePage> {
  late BusinessProfile _businessProfile;
  final List<Invoice> _invoices = [];
  InvoiceFilter _filter = InvoiceFilter.all;
  int _invoiceCounter = 1;

  @override
  void initState() {
    super.initState();
    _businessProfile = BusinessProfile(
      businessName: 'Your Business',
      ownerName: 'Owner Name',
      email: 'owner@example.com',
      phone: '',
      address: '',
    );
  }

  String _nextInvoiceNumber() {
    final number = _invoiceCounter.toString().padLeft(3, '0');
    _invoiceCounter++;
    return number;
  }

  List<Invoice> get _filteredInvoices {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inSevenDays = today.add(const Duration(days: 7));

    return _invoices.where((invoice) {
      switch (_filter) {
        case InvoiceFilter.all:
          return true;
        case InvoiceFilter.paid:
          return invoice.isPaid;
        case InvoiceFilter.overdue:
          return invoice.isOverdue;
        case InvoiceFilter.dueSoon:
          final due = DateTime(
              invoice.dueDate.year, invoice.dueDate.month, invoice.dueDate.day);
          final isUnpaid = !invoice.isPaid;
          return isUnpaid &&
              !invoice.isOverdue &&
              !due.isBefore(today) &&
              !due.isAfter(inSevenDays);
      }
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  double get _totalOutstanding {
    return _invoices
        .where((i) => !i.isPaid)
        .fold(0.0, (sum, i) => sum + i.total);
  }

  int get _overdueCount =>
      _invoices.where((i) => i.isOverdue).length;

  int get _dueSoonCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inSevenDays = today.add(const Duration(days: 7));
    return _invoices.where((invoice) {
      final due = DateTime(
          invoice.dueDate.year, invoice.dueDate.month, invoice.dueDate.day);
      final isUnpaid = !invoice.isPaid;
      return isUnpaid &&
          !invoice.isOverdue &&
          !due.isBefore(today) &&
          !due.isAfter(inSevenDays);
    }).length;
  }

  Future<void> _openBusinessProfileEditor() async {
    final updated = await showDialog<BusinessProfile>(
      context: context,
      builder: (context) => _EditBusinessProfileDialog(
        profile: _businessProfile,
      ),
    );

    if (updated != null) {
      setState(() {
        _businessProfile = updated;
      });
    }
  }

  Future<void> _createInvoice() async {
    final invoice = await Navigator.push<Invoice>(
      context,
      MaterialPageRoute(
        builder: (context) => NewInvoicePage(
          businessProfile: _businessProfile,
          nextInvoiceNumber: _nextInvoiceNumber(),
        ),
      ),
    );

    if (invoice != null) {
      setState(() {
        _invoices.add(invoice);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice created')),
      );
    }
  }

  Future<void> _openInvoiceDetails(Invoice invoice) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsPage(
          businessProfile: _businessProfile,
          invoice: invoice,
        ),
      ),
    );
    // Invoice is mutated in details page; refresh UI
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _businessProfile.businessName.isEmpty
              ? 'Onyx Business Manager'
              : _businessProfile.businessName,
        ),
        actions: [
          IconButton(
            tooltip: 'Business profile',
            icon: const Icon(Icons.business),
            onPressed: _openBusinessProfileEditor,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createInvoice,
        icon: const Icon(Icons.add),
        label: const Text('New invoice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _OverviewRow(
              totalOutstanding: _totalOutstanding,
              overdueCount: _overdueCount,
              dueSoonCount: _dueSoonCount,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    label: 'All',
                    value: InvoiceFilter.all,
                  ),
                  _buildFilterChip(
                    label: 'Due soon',
                    value: InvoiceFilter.dueSoon,
                  ),
                  _buildFilterChip(
                    label: 'Overdue',
                    value: InvoiceFilter.overdue,
                  ),
                  _buildFilterChip(
                    label: 'Paid',
                    value: InvoiceFilter.paid,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredInvoices.isEmpty
                  ? _EmptyInvoicesState(
                      onCreate: _createInvoice,
                    )
                  : ListView.separated(
                      itemCount: _filteredInvoices.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final invoice = _filteredInvoices[index];
                        final statusColor = invoice.status.color(scheme);
                        final amountText =
                            '\$${invoice.total.toStringAsFixed(2)}';

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openInvoiceDetails(invoice),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      scheme.primary.withOpacity(0.1),
                                  child: Text(
                                    invoice.client.name.isNotEmpty
                                        ? invoice.client.name[0]
                                            .toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        invoice.client.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Invoice #${invoice.invoiceNumber} · Due ${_formatDate(invoice.dueDate)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      amountText,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        invoice.isOverdue
                                            ? 'Overdue'
                                            : invoice.status.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  FilterChip _buildFilterChip({
    required String label,
    required InvoiceFilter value,
  }) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filter = value;
        });
      },
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final double totalOutstanding;
  final int overdueCount;
  final int dueSoonCount;

  const _OverviewRow({
    required this.totalOutstanding,
    required this.overdueCount,
    required this.dueSoonCount,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;
    final children = [
      _OverviewCard(
        title: 'Outstanding',
        value: '\$${totalOutstanding.toStringAsFixed(2)}',
        subtitle: 'Unpaid invoices',
        icon: Icons.payments_outlined,
      ),
      _OverviewCard(
        title: 'Due soon',
        value: '$dueSoonCount',
        subtitle: 'Next 7 days',
        icon: Icons.schedule,
      ),
      _OverviewCard(
        title: 'Overdue',
        value: '$overdueCount',
        subtitle: 'Needs attention',
        icon: Icons.warning_amber_rounded,
      ),
    ];

    if (isWide) {
      return Row(
        children: children
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: c,
                ),
              ),
            )
            .toList()
          ..last = Expanded(child: children.last),
      );
    } else {
      return Column(
        children: [
          _OverviewCard(
            title: 'Outstanding',
            value: '\$${totalOutstanding.toStringAsFixed(2)}',
            subtitle: 'Unpaid invoices',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: 8),
          _OverviewCard(
            title: 'Due soon',
            value: '$dueSoonCount',
            subtitle: 'Next 7 days',
            icon: Icons.schedule,
          ),
          const SizedBox(height: 8),
          _OverviewCard(
            title: 'Overdue',
            value: '$overdueCount',
            subtitle: 'Needs attention',
            icon: Icons.warning_amber_rounded,
          ),
        ],
      );
    }
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.primary.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInvoicesState extends StatelessWidget {
  final Future<void> Function() onCreate;

  const _EmptyInvoicesState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: scheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'No invoices yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first invoice in a few taps.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create invoice'),
          ),
        ],
      ),
    );
  }
}

/// Business profile dialog
class _EditBusinessProfileDialog extends StatefulWidget {
  final BusinessProfile profile;

  const _EditBusinessProfileDialog({required this.profile});

  @override
  State<_EditBusinessProfileDialog> createState() =>
      _EditBusinessProfileDialogState();
}

class _EditBusinessProfileDialogState
    extends State<_EditBusinessProfileDialog> {
  late TextEditingController _businessName;
  late TextEditingController _ownerName;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _address;

  @override
  void initState() {
    super.initState();
    _businessName =
        TextEditingController(text: widget.profile.businessName);
    _ownerName =
        TextEditingController(text: widget.profile.ownerName);
    _email = TextEditingController(text: widget.profile.email);
    _phone = TextEditingController(text: widget.profile.phone);
    _address = TextEditingController(text: widget.profile.address);
  }

  @override
  void dispose() {
    _businessName.dispose();
    _ownerName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _save() {
    if (_businessName.text.trim().isEmpty ||
        _ownerName.text.trim().isEmpty ||
        _email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Business name, owner, and email are required.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      BusinessProfile(
        businessName: _businessName.text.trim(),
        ownerName: _ownerName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Business profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _businessName,
              decoration: const InputDecoration(
                labelText: 'Business name',
              ),
            ),
            TextField(
              controller: _ownerName,
              decoration: const InputDecoration(
                labelText: 'Owner name',
              ),
            ),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
              ),
            ),
            TextField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Address',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// New invoice page
class NewInvoicePage extends StatefulWidget {
  final BusinessProfile businessProfile;
  final String nextInvoiceNumber;

  const NewInvoicePage({
    super.key,
    required this.businessProfile,
    required this.nextInvoiceNumber,
  });

  @override
  State<NewInvoicePage> createState() => _NewInvoicePageState();
}

class _LineItemInput {
  final TextEditingController description =
      TextEditingController();
  final TextEditingController quantity =
      TextEditingController(text: '1');
  final TextEditingController unitPrice =
      TextEditingController();

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }
}

class _NewInvoicePageState extends State<NewInvoicePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _clientName;
  late TextEditingController _clientEmail;
  late TextEditingController _clientPhone;
  late TextEditingController _notes;
  late TextEditingController _paymentLink;

  DateTime? _dueDate;
  final List<_LineItemInput> _items = [];

  @override
  void initState() {
    super.initState();
    _clientName = TextEditingController();
    _clientEmail = TextEditingController();
    _clientPhone = TextEditingController();
    _notes = TextEditingController();
    _paymentLink = TextEditingController();
    _addItem();
  }

  @override
  void dispose() {
    _clientName.dispose();
    _clientEmail.dispose();
    _clientPhone.dispose();
    _notes.dispose();
    _paymentLink.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_LineItemInput());
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final item = _items.removeAt(index);
      item.dispose();
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  double get _previewTotal {
    double total = 0.0;
    for (final item in _items) {
      final qty =
          int.tryParse(item.quantity.text.trim()) ?? 0;
      final price =
          double.tryParse(item.unitPrice.text.trim()) ?? 0.0;
      total += qty * price;
    }
    return total;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a due date')),
      );
      return;
    }

    final items = <InvoiceLineItem>[];
    for (final item in _items) {
      final desc = item.description.text.trim();
      final qty =
          int.tryParse(item.quantity.text.trim()) ?? 0;
      final price =
          double.tryParse(item.unitPrice.text.trim()) ?? 0.0;
      if (desc.isNotEmpty && qty > 0 && price >= 0) {
        items.add(
          InvoiceLineItem(
            description: desc,
            quantity: qty,
            unitPrice: price,
          ),
        );
      }
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Add at least one valid line item.')),
      );
      return;
    }

    final client = Client(
      name: _clientName.text.trim(),
      email: _clientEmail.text.trim(),
      phone: _clientPhone.text.trim(),
    );

    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNumber: widget.nextInvoiceNumber,
      client: client,
      issueDate: DateTime.now(),
      dueDate: _dueDate!,
      items: items,
      status: InvoiceStatus.draft,
      notes: _notes.text.trim().isEmpty
          ? null
          : _notes.text.trim(),
      paymentLink: _paymentLink.text.trim().isEmpty
          ? null
          : _paymentLink.text.trim(),
    );

    Navigator.of(context).pop(invoice);
  }

  @override
  Widget build(BuildContext context) {
    final total = _previewTotal;

    return Scaffold(
      appBar: AppBar(
        title:
            Text('New invoice #${widget.nextInvoiceNumber}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.businessProfile.businessName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.businessProfile.address.isNotEmpty)
              Text(
                widget.businessProfile.address,
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 16),
            const Text(
              'Client details',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _clientName,
              decoration: const InputDecoration(
                labelText: 'Client name *',
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Client name is required';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _clientEmail,
              decoration: const InputDecoration(
                labelText: 'Client email',
              ),
            ),
            TextFormField(
              controller: _clientPhone,
              decoration: const InputDecoration(
                labelText: 'Client phone',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due date'),
                    subtitle: Text(
                      _dueDate == null
                          ? 'Tap to choose'
                          : _formatDate(_dueDate!),
                    ),
                    onTap: _pickDueDate,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Estimated total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Line items',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildLineItemFields(),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add line item'),
            ),
            const Divider(height: 32),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Visible to the client',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _paymentLink,
              decoration: const InputDecoration(
                labelText: 'Payment link (optional)',
                hintText:
                    'Paste a Stripe/PayPal/Interac link',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Save invoice'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLineItemFields() {
    final widgets = <Widget>[];
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: item.description,
                        decoration:
                            const InputDecoration(
                          labelText: 'Description *',
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Add a description';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () =>
                          _removeItem(i),
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: item.quantity,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          labelText: 'Qty',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: item.unitPrice,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(
                          labelText: 'Unit price',
                          prefixText: '\$',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

/// Invoice details page
class InvoiceDetailsPage extends StatelessWidget {
  final BusinessProfile businessProfile;
  final Invoice invoice;

  const InvoiceDetailsPage({
    super.key,
    required this.businessProfile,
    required this.invoice,
  });

  String _buildInvoiceText() {
    final buffer = StringBuffer();
    buffer.writeln(
        '${businessProfile.businessName} – Invoice #${invoice.invoiceNumber}');
    buffer.writeln(
        'Client: ${invoice.client.name} (${invoice.client.email})');
    buffer.writeln(
        'Issue date: ${_formatDate(invoice.issueDate)}');
    buffer.writeln(
        'Due date: ${_formatDate(invoice.dueDate)}');
    buffer.writeln('');
    buffer.writeln('Items:');
    for (final item in invoice.items) {
      buffer.writeln(
          '- ${item.description} (${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}) = \$${item.total.toStringAsFixed(2)}');
    }
    buffer.writeln('');
    buffer.writeln(
        'Total: \$${invoice.total.toStringAsFixed(2)}');
    if (invoice.notes != null &&
        invoice.notes!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Notes: ${invoice.notes}');
    }
    if (invoice.paymentLink != null &&
        invoice.paymentLink!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln(
          'Payment link: ${invoice.paymentLink}');
    }
    return buffer.toString();
  }

  Future<void> _copyInvoiceText(BuildContext context) async {
    final text = _buildInvoiceText();
    await Clipboard.setData(
      ClipboardData(text: text),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice copied')),
    );
  }

  Future<void> _launchPaymentLink(
      BuildContext context) async {
    final link = invoice.paymentLink;
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No payment link set')),
      );
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid payment link')),
      );
      return;
    }

    try {
      final ok = await canLaunchUrl(uri);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Could not open payment link')),
        );
        return;
      }
      await launchUrl(uri,
          mode: LaunchMode.externalApplication);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Could not open payment link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Invoice #${invoice.invoiceNumber}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            businessProfile.businessName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (businessProfile.address.isNotEmpty)
            Text(
              businessProfile.address,
              style: const TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 12),
          _DetailsRow(
            label: 'Client',
            value: invoice.client.name,
          ),
          if (invoice.client.email.isNotEmpty)
            _DetailsRow(
              label: 'Email',
              value: invoice.client.email,
            ),
          if (invoice.client.phone.isNotEmpty)
            _DetailsRow(
              label: 'Phone',
              value: invoice.client.phone,
            ),
          _DetailsRow(
            label: 'Issue date',
            value: _formatDate(invoice.issueDate),
          ),
          _DetailsRow(
            label: 'Due date',
            value: _formatDate(invoice.dueDate),
          ),
          _DetailsRow(
            label: 'Status',
            value: invoice.isOverdue
                ? 'Overdue'
                : invoice.status.label,
          ),
          const SizedBox(height: 16),
          const Text(
            'Line items',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...invoice.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.description),
              subtitle: Text(
                  '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}'),
              trailing: Text(
                '\$${item.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Divider(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: \$${invoice.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (invoice.notes != null &&
              invoice.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Notes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(invoice.notes!),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copyInvoiceText(context),
                icon: const Icon(Icons.copy),
                label: const Text('Copy invoice text'),
              ),
              if (invoice.paymentLink != null &&
                  invoice.paymentLink!.isNotEmpty)
                FilledButton.icon(
                  onPressed: () =>
                      _launchPaymentLink(context),
                  icon: const Icon(Icons.payment),
                  label:
                      const Text('Open payment link'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Status changes (draft/sent/paid) will be handled in a later step – for now this page is focused on clean viewing & sharing.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailsRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple date formatter without extra packages
String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
