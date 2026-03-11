// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'business_context_bridge.dart';

class _WebBusinessContextBridge implements BusinessContextBridge {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  @override
  Future<Map<String, dynamic>?> fetchWorkspace() async {
    try {
      final response = await html.HttpRequest.request(
        '$_baseUrl/api/onyx/business_context',
        method: 'GET',
        requestHeaders: const {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));
      if (response.status != 200 || response.responseText == null) {
        return null;
      }
      final decoded = jsonDecode(response.responseText!);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final workspace = decoded['workspace'];
      if (workspace is! Map) {
        return null;
      }
      return Map<String, dynamic>.from(workspace);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<BusinessContextSyncStatus> saveWorkspace(
    Map<String, dynamic> workspace,
  ) async {
    try {
      final response = await html.HttpRequest.request(
        '$_baseUrl/api/onyx/business_context',
        method: 'POST',
        sendData: jsonEncode({
          'workspace': workspace,
        }),
        requestHeaders: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));
      final payload = _decodeResponse(response.responseText);
      return BusinessContextSyncStatus(
        ok: response.status == 200 && payload['ok'] == true,
        message: (payload['message'] as String?) ??
            (response.status == 200
                ? 'Business context synced to local control state.'
                : 'Business context sync failed.'),
        syncedAtUtc: (payload['synced_at_utc'] as String?) ?? '',
      );
    } on TimeoutException {
      return const BusinessContextSyncStatus(
        ok: false,
        message: 'Control sync timed out. Saved locally only.',
        syncedAtUtc: '',
      );
    } catch (_) {
      return const BusinessContextSyncStatus(
        ok: false,
        message: 'Control sync unavailable. Saved locally only.',
        syncedAtUtc: '',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(String? text) {
    if (text == null || text.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }
}

BusinessContextBridge createBusinessContextBridgeImpl() {
  return _WebBusinessContextBridge();
}
