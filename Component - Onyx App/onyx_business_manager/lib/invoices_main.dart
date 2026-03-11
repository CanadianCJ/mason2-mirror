import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OnyxApp());
}

class OnyxApp extends StatelessWidget {
  const OnyxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onyx – Business Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const OnyxHomePage(),
    );
  }
}

class OnyxHomePage extends StatelessWidget {
  const OnyxHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Onyx – Business Manager'),
          centerTitle: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Invoices'),
              Tab(text: 'Expenses'),
              Tab(text: 'Tasks'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            InvoiceScreen(),
            ExpensesScreen(),
            TasksScreen(),
          ],
        ),
      ),
    );
  }
}

double _parseDouble(String value) {
  return double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;
}

/// ======================== INVOICES ========================

class InvoiceItem {
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController priceController;

  InvoiceItem({
    required this.descriptionController,
    required this.quantityController,
    required this.priceController,
  });
}

class SavedClient {
  final String id;
  final String name;
  final String email;
  final String address;

  SavedClient({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
  });

  factory SavedClient.fromJson(Map<String, dynamic> json) {
    return SavedClient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'address': address,
      };
}

class SavedInvoice {
  final String id;
  final String clientName;
  final double total;
  final DateTime createdAt;

  SavedInvoice({
    required this.id,
    required this.clientName,
    required this.total,
    required this.createdAt,
  });

  factory SavedInvoice.fromJson(Map<String, dynamic> json) {
    return SavedInvoice(
      id: json['id'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'total': total,
        'createdAt': createdAt.toIso8601String(),
      };
}

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _invoiceTitleController = TextEditingController();
  final _taxRateController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  List<InvoiceItem> _items = [];
  List<SavedClient> _clients = [];
  SavedClient? _selectedClient;

  List<SavedInvoice> _recentInvoices = [];

  @override
  void initState() {
    super.initState();
    _items = [
      InvoiceItem(
        descriptionController: TextEditingController(),
        quantityController: TextEditingController(text: '1'),
        priceController: TextEditingController(text: '0'),
      ),
    ];
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();

    final clientsJson = prefs.getString('onyx_clients_v1');
    if (clientsJson != null) {
      final List<dynamic> decoded = jsonDecode(clientsJson);
      _clients = decoded
          .whereType<Map<String, dynamic>>()
          .map(SavedClient.fromJson)
          .toList();
    }

    final invoicesJson = prefs.getString('onyx_invoices_v1');
    if (invoicesJson != null) {
      final List<dynamic> decoded = jsonDecode(invoicesJson);
      _recentInvoices = decoded
          .whereType<Map<String, dynamic>>()
          .map(SavedInvoice.fromJson)
          .toList();
    }

    if (mounted) {
      setState(() {});
    }
  }

  double get _subtotal {
    double sum = 0.0;
    for (final item in _items) {
      final qty = _parseDouble(item.quantityController.text);
      final price = _parseDouble(item.priceController.text);
      sum += qty * price;
    }
    return sum;
  }

  double get _taxRate => _parseDouble(_taxRateController.text);
  double get _taxAmount => _subtotal * _taxRate / 100.0;
  double get _total => _subtotal + _taxAmount;

  void _addItem() {
    setState(() {
      _items.add(
        InvoiceItem(
          descriptionController: TextEditingController(),
          quantityController: TextEditingController(text: '1'),
          priceController: TextEditingController(text: '0'),
        ),
      );
    });
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;
    setState(() {
      _items.removeAt(index);
    });
  }

  void _newInvoice() {
    setState(() {
      _invoiceTitleController.clear();
      _taxRateController.text = '0';
      _notesController.clear();
      _items = [
        InvoiceItem(
          descriptionController: TextEditingController(),
          quantityController: TextEditingController(text: '1'),
          priceController: TextEditingController(text: '0'),
        ),
      ];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New invoice started')),
    );
  }

  void _clearClient() {
    setState(() {
      _clientNameController.clear();
      _clientEmailController.clear();
      _clientAddressController.clear();
      _selectedClient = null;
    });
  }

  Future<void> _saveClient() async {
    final name = _clientNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a client name first')),
      );
      return;
    }

    final email = _clientEmailController.text.trim();
    final address = _clientAddressController.text.trim();

    final id = _selectedClient?.id ??
        'CLIENT-${DateTime.now().millisecondsSinceEpoch}';

    final client = SavedClient(
      id: id,
      name: name,
      email: email,
      address: address,
    );

    final existingIndex = _clients.indexWhere((c) => c.id == id);
    if (existingIndex >= 0) {
      _clients[existingIndex] = client;
    } else {
      _clients.add(client);
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_clients.map((c) => c.toJson()).toList());
    await prefs.setString('onyx_clients_v1', encoded);

    setState(() {
      _selectedClient = client;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Client saved')),
    );
  }

  void _applyClient(SavedClient client) {
    setState(() {
      _selectedClient = client;
      _clientNameController.text = client.name;
      _clientEmailController.text = client.email;
      _clientAddressController.text = client.address;
    });
  }

  Future<void> _saveInvoice() async {
    final clientName = _clientNameController.text.trim();
    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a client name before saving')),
      );
      return;
    }

    final items = _items
        .map(
          (item) => {
            'description': item.descriptionController.text.trim(),
            'quantity': _parseDouble(item.quantityController.text),
            'price': _parseDouble(item.priceController.text),
          },
        )
        .where((item) => (item['description'] as String).isNotEmpty)
        .toList();

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line item')),
      );
      return;
    }

    final now = DateTime.now();
    final id = 'INV-${now.millisecondsSinceEpoch}';

    final invoiceData = {
      'id': id,
      'clientName': clientName,
      'clientEmail': _clientEmailController.text.trim(),
      'clientAddress': _clientAddressController.text.trim(),
      'title': _invoiceTitleController.text.trim(),
      'notes': _notesController.text.trim(),
      'subtotal': _subtotal,
      'taxRate': _taxRate,
      'taxAmount': _taxAmount,
      'total': _total,
      'items': items,
      'createdAt': now.toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('onyx_invoices_v1');
    List<dynamic> decoded = [];
    if (existingJson != null) {
      decoded = jsonDecode(existingJson);
    }
    decoded.insert(0, invoiceData);

    await prefs.setString('onyx_invoices_v1', jsonEncode(decoded));

    setState(() {
      _recentInvoices = decoded
          .whereType<Map<String, dynamic>>()
          .map(SavedInvoice.fromJson)
          .toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice saved')),
    );
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientAddressController.dispose();
    _invoiceTitleController.dispose();
    _taxRateController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.descriptionController.dispose();
      item.quantityController.dispose();
      item.priceController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1000;

        final mainContent = SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInvoiceHeaderButtons(),
                const SizedBox(height: 16),
                _buildClientSection(),
                const SizedBox(height: 16),
                _buildItemsSection(),
                const SizedBox(height: 16),
                _buildTotalsSection(),
                const SizedBox(height: 16),
                _buildNotesSection(),
              ],
            ),
          ),
        );

        if (!isWide) {
          return mainContent;
        }

        return Row(
          children: [
            Expanded(flex: 3, child: mainContent),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 2,
              child: _buildSidebar(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInvoiceHeaderButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: _newInvoice,
          icon: const Icon(Icons.note_add),
          label: const Text('New Invoice'),
        ),
        ElevatedButton.icon(
          onPressed: _saveInvoice,
          icon: const Icon(Icons.save),
          label: const Text('Save Invoice'),
        ),
      ],
    );
  }

  Widget _buildClientSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_clients.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Saved clients',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedClient?.id,
                      isExpanded: true,
                      items: _clients
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        final client =
                            _clients.firstWhere((c) => c.id == value);
                        _applyClient(client);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Clear client form',
                    onPressed: _clearClient,
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ),
            if (_clients.isNotEmpty) const SizedBox(height: 12),
            TextField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Client name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _clientEmailController,
              decoration: const InputDecoration(
                labelText: 'Client email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _clientAddressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Client address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _invoiceTitleController,
              decoration: const InputDecoration(
                labelText: 'Invoice title / reference',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _saveClient,
                icon: const Icon(Icons.person_add),
                label: const Text('Save Client'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Line Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                for (int i = 0; i < _items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildItemRow(i),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: TextField(
            controller: item.descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: item.quantityController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Qty',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: item.priceController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Unit price',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Remove item',
          onPressed: _items.length == 1 ? null : () => _removeItem(index),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  Widget _buildTotalsSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taxRateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Tax %',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _totalsRow('Subtotal', _subtotal),
                      _totalsRow('Tax', _taxAmount),
                      const Divider(),
                      _totalsRow(
                        'Total',
                        _total,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalsRow(String label, double value, {bool isBold = false}) {
    final style = TextStyle(
      fontSize: isBold ? 16 : 14,
      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Notes / terms (optional)',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent invoices',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _recentInvoices.isEmpty
                ? const Text(
                    'No invoices saved yet.\nSave an invoice to see it here.',
                  )
                : ListView.builder(
                    itemCount: _recentInvoices.length,
                    itemBuilder: (context, index) {
                      final inv = _recentInvoices[index];
                      return Card(
                        child: ListTile(
                          title: Text(inv.clientName.isEmpty
                              ? 'Invoice ${inv.id}'
                              : inv.clientName),
                          subtitle: Text(
                            '${inv.createdAt.toLocal().toString().split(".").first}',
                          ),
                          trailing: Text(
                            '\$${inv.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// ======================== EXPENSES ========================

class Expense {
  final String id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'General',
      date: DateTime.tryParse(json['date'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
      };
}

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'General';
  DateTime _selectedDate = DateTime.now();

  List<Expense> _expenses = [];

  static const List<String> _categories = [
    'General',
    'Supplies',
    'Travel',
    'Marketing',
    'Software',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('onyx_expenses_v1');
    if (jsonStr != null) {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      _expenses = decoded
          .whereType<Map<String, dynamic>>()
          .map(Expense.fromJson)
          .toList();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _persistExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_expenses.map((e) => e.toJson()).toList());
    await prefs.setString('onyx_expenses_v1', encoded);
  }

  double get _totalThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<void> _addExpense() async {
    final description = _descriptionController.text.trim();
    final amount = _parseDouble(_amountController.text);
    if (description.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Enter a description and a positive amount for the expense'),
        ),
      );
      return;
    }

    final expense = Expense(
      id: 'EXP-${DateTime.now().millisecondsSinceEpoch}',
      description: description,
      amount: amount,
      category: _category,
      date: _selectedDate,
    );

    setState(() {
      _expenses.insert(0, expense);
      _descriptionController.clear();
      _amountController.clear();
    });

    await _persistExpenses();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense added')),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildAddExpenseCard(),
          const SizedBox(height: 16),
          Expanded(child: _buildExpensesList()),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.pie_chart_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Total expenses this month: \$${_totalThisMonth.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddExpenseCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _category = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      'Date: ${_selectedDate.toLocal().toString().split(' ').first}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addExpense,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    if (_expenses.isEmpty) {
      return const Center(
        child: Text('No expenses yet'),
      );
    }

    return ListView.builder(
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final e = _expenses[index];
        return Card(
          child: ListTile(
            title: Text(e.description),
            subtitle: Text(
              '${e.category} • ${e.date.toLocal().toString().split(' ').first}',
            ),
            trailing: Text(
              '\$${e.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

/// ======================== TASKS ========================

class Task {
  final String id;
  final String title;
  final bool done;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.done,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      done: json['done'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
      };

  Task copyWith({bool? done}) {
    return Task(
      id: id,
      title: title,
      done: done ?? this.done,
      createdAt: createdAt,
    );
  }
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _taskController = TextEditingController();
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('onyx_tasks_v1');
    if (jsonStr != null) {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      _tasks = decoded
          .whereType<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _persistTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('onyx_tasks_v1', encoded);
  }

  Future<void> _addTask() async {
    final title = _taskController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type a task before adding')),
      );
      return;
    }

    final task = Task(
      id: 'TASK-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      done: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _tasks.insert(0, task);
      _taskController.clear();
    });

    await _persistTasks();
  }

  Future<void> _toggleTask(Task task) async {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index >= 0) {
        _tasks[index] = task.copyWith(done: !task.done);
      }
    });
    await _persistTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _tasks.where((t) => !t.done).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      decoration: const InputDecoration(
                        labelText: 'Quick task',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addTask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add_task),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Remaining: $remaining • Total: ${_tasks.length}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(
                    child: Text('No tasks yet'),
                  )
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return CheckboxListTile(
                        value: task.done,
                        onChanged: (_) => _toggleTask(task),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        secondary: const Icon(Icons.drag_indicator),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
