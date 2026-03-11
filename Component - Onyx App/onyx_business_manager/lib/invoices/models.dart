// lib/invoices/models.dart
import 'package:flutter/foundation.dart';

enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
}

class InvoiceLine {
  final String description;
  final double quantity;
  final double unitPrice;

  const InvoiceLine({
    required this.description,
    this.quantity = 1.0,
    this.unitPrice = 0.0,
  });

  double get lineTotal => quantity * unitPrice;

  InvoiceLine copyWith({
    String? description,
    double? quantity,
    double? unitPrice,
  }) {
    return InvoiceLine(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      description: json['description'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final String? customerEmail;
  final DateTime issueDate;
  final DateTime dueDate;
  final InvoiceStatus status;
  final List<InvoiceLine> items;
  final String? notes;
  final String? paymentInstructions;
  final String currencyCode;
  final double? taxRatePercent; // e.g. 13 for 13%

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    this.customerEmail,
    required this.issueDate,
    required this.dueDate,
    this.status = InvoiceStatus.draft,
    required this.items,
    this.notes,
    this.paymentInstructions,
    this.currencyCode = 'CAD',
    this.taxRatePercent,
  });

  double get subtotal {
    return items.fold<double>(
      0.0,
      (sum, item) => sum + item.lineTotal,
    );
  }

  double get taxAmount {
    if (taxRatePercent == null || taxRatePercent == 0) return 0.0;
    return subtotal * (taxRatePercent! / 100.0);
  }

  double get total => subtotal + taxAmount;

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? customerName,
    String? customerEmail,
    DateTime? issueDate,
    DateTime? dueDate,
    InvoiceStatus? status,
    List<InvoiceLine>? items,
    String? notes,
    String? paymentInstructions,
    String? currencyCode,
    double? taxRatePercent,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      currencyCode: currencyCode ?? this.currencyCode,
      taxRatePercent: taxRatePercent ?? this.taxRatePercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': describeEnum(status),
      'items': items.map((e) => e.toJson()).toList(),
      'notes': notes,
      'paymentInstructions': paymentInstructions,
      'currencyCode': currencyCode,
      'taxRatePercent': taxRatePercent,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerEmail: json['customerEmail'] as String?,
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: _statusFromString(json['status'] as String?),
      items: ((json['items'] as List?) ?? [])
          .map((e) => InvoiceLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      paymentInstructions: json['paymentInstructions'] as String?,
      currencyCode: json['currencyCode'] as String? ?? 'CAD',
      taxRatePercent: (json['taxRatePercent'] as num?)?.toDouble(),
    );
  }

  static InvoiceStatus _statusFromString(String? value) {
    switch (value) {
      case 'sent':
        return InvoiceStatus.sent;
      case 'paid':
        return InvoiceStatus.paid;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'draft':
      default:
        return InvoiceStatus.draft;
    }
  }
}
