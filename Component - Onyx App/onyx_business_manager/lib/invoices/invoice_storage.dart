// lib/invoices/invoice_storage.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'invoice.dart';

class InvoiceStorage {
  static const String _storageKey = 'onyx_invoices_v1';

  Future<List<Invoice>> loadInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return <Invoice>[];
    }

    try {
      final data = jsonDecode(jsonString) as List<dynamic>;
      return data
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // If something is corrupt, just start fresh.
      return <Invoice>[];
    }
  }

  Future<void> saveInvoices(List<Invoice> invoices) async {
    final prefs = await SharedPreferences.getInstance();
    final data =
        invoices.map<Map<String, dynamic>>((i) => i.toJson()).toList();
    final jsonString = jsonEncode(data);
    await prefs.setString(_storageKey, jsonString);
  }
}
