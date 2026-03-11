// lib/invoices/invoice.dart
enum InvoiceStatus { draft, sent, paid }

String invoiceStatusToString(InvoiceStatus status) {
  switch (status) {
    case InvoiceStatus.draft:
      return 'draft';
    case InvoiceStatus.sent:
      return 'sent';
    case InvoiceStatus.paid:
      return 'paid';
  }
}

InvoiceStatus invoiceStatusFromString(String value) {
  switch (value) {
    case 'sent':
      return InvoiceStatus.sent;
    case 'paid':
      return InvoiceStatus.paid;
    case 'draft':
    default:
      return InvoiceStatus.draft;
  }
}

class InvoiceItem {
  final String id;
  final String description;
  final int quantity;
  final double unitPrice;

  const InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  InvoiceItem copyWith({
    String? id,
    String? description,
    int? quantity,
    double? unitPrice,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Invoice {
  final String id;
  final String number;
  final String clientName;
  final String? clientEmail;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final String? notes;
  final InvoiceStatus status;
  final String currencySymbol;

  Invoice({
    required this.id,
    required this.number,
    required this.clientName,
    required this.clientEmail,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.notes,
    required this.status,
    required this.currencySymbol,
  });

  double get total {
    return items.fold<double>(0.0, (sum, item) => sum + item.total);
  }

  bool get isOverdue {
    final now = DateTime.now();
    return status != InvoiceStatus.paid &&
        DateTime(dueDate.year, dueDate.month, dueDate.day)
            .isBefore(DateTime(now.year, now.month, now.day));
  }

  Invoice copyWith({
    String? id,
    String? number,
    String? clientName,
    String? clientEmail,
    DateTime? issueDate,
    DateTime? dueDate,
    List<InvoiceItem>? items,
    String? notes,
    InvoiceStatus? status,
    String? currencySymbol,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'notes': notes,
      'status': invoiceStatusToString(status),
      'currencySymbol': currencySymbol,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      number: json['number'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      clientEmail: json['clientEmail'] as String?,
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      status: invoiceStatusFromString(json['status'] as String? ?? 'draft'),
      currencySymbol: json['currencySymbol'] as String? ?? '\$',
    );
  }

  /// Simple "new draft invoice" factory.
  static Invoice newDraft({String currencySymbol = '\$'}) {
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final number =
        'INV-${now.year}${_two(now.month)}${_two(now.day)}-${_two(now.hour)}${_two(now.minute)}';

    return Invoice(
      id: id,
      number: number,
      clientName: '',
      clientEmail: null,
      issueDate: now,
      dueDate: now.add(const Duration(days: 14)),
      items: <InvoiceItem>[
        InvoiceItem(
          id: '${id}_1',
          description: '',
          quantity: 1,
          unitPrice: 0,
        ),
      ],
      notes: null,
      status: InvoiceStatus.draft,
      currencySymbol: currencySymbol,
    );
  }
}

String _two(int value) => value.toString().padLeft(2, '0');
