// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'tool_runtime_bridge.dart';

class _WebToolRuntimeBridge implements ToolRuntimeBridge {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  @override
  Future<Map<String, dynamic>> fetchCatalog({
    required String tenantId,
  }) async {
    final encodedTenantId = Uri.encodeQueryComponent(tenantId);
    return _requestJson(
      '$_baseUrl/api/tools/catalog?tenant_id=$encodedTenantId',
      method: 'GET',
    );
  }

  @override
  Future<Map<String, dynamic>> fetchLatestRuns({
    required String tenantId,
    int limit = 5,
  }) async {
    final encodedTenantId = Uri.encodeQueryComponent(tenantId);
    return _requestJson(
      '$_baseUrl/api/tools/runs/latest?tenant_id=$encodedTenantId&limit=$limit',
      method: 'GET',
    );
  }

  @override
  Future<Map<String, dynamic>> fetchRecommendations({
    required String tenantId,
    bool refresh = false,
  }) async {
    final encodedTenantId = Uri.encodeQueryComponent(tenantId);
    final refreshValue = refresh ? 'true' : 'false';
    return _requestJson(
      '$_baseUrl/api/onyx/recommendations?tenant_id=$encodedTenantId&refresh=$refreshValue',
      method: 'GET',
    );
  }

  @override
  Future<Map<String, dynamic>> fetchBillingSummary({
    required String tenantId,
  }) async {
    final encodedTenantId = Uri.encodeQueryComponent(tenantId);
    return _requestJson(
      '$_baseUrl/api/billing/summary?tenant_id=$encodedTenantId',
      method: 'GET',
    );
  }

  @override
  Future<Map<String, dynamic>> createCheckoutSession({
    required String tenantId,
    required String planId,
  }) async {
    final payload = await _requestJson(
      '$_baseUrl/api/billing/checkout_session',
      method: 'POST',
      sendData: jsonEncode({
        'tenant_id': tenantId,
        'plan_id': planId,
      }),
      requestHeaders: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    _openUrlIfPresent(payload['checkout_url']);
    return payload;
  }

  @override
  Future<Map<String, dynamic>> openBillingPortal({
    required String tenantId,
  }) async {
    final payload = await _requestJson(
      '$_baseUrl/api/billing/portal',
      method: 'POST',
      sendData: jsonEncode({
        'tenant_id': tenantId,
      }),
      requestHeaders: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    _openUrlIfPresent(payload['portal_url']);
    return payload;
  }

  @override
  Future<Map<String, dynamic>> refreshRecommendations({
    required String tenantId,
  }) async {
    return _requestJson(
      '$_baseUrl/api/onyx/recommendations/refresh',
      method: 'POST',
      sendData: jsonEncode({
        'tenant_id': tenantId,
      }),
      requestHeaders: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updateRecommendationStatus({
    required String tenantId,
    required String recommendationId,
    required String status,
  }) async {
    return _requestJson(
      '$_baseUrl/api/onyx/recommendations/status',
      method: 'POST',
      sendData: jsonEncode({
        'tenant_id': tenantId,
        'recommendation_id': recommendationId,
        'status': status,
      }),
      requestHeaders: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
  }

  @override
  Future<Map<String, dynamic>> runTool({
    required String tenantId,
    required String toolId,
    required String clientName,
    required Map<String, dynamic> input,
  }) async {
    return _requestJson(
      '$_baseUrl/api/tools/run',
      method: 'POST',
      sendData: jsonEncode({
        'tool_id': toolId,
        'tenant_id': tenantId,
        'client_name': clientName,
        'input': input,
      }),
      requestHeaders: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<Map<String, dynamic>> _requestJson(
    String url, {
    required String method,
    String? sendData,
    Map<String, String>? requestHeaders,
  }) async {
    try {
      final response = await html.HttpRequest.request(
        url,
        method: method,
        sendData: sendData,
        requestHeaders: requestHeaders ??
            const {
              'Accept': 'application/json',
            },
      ).timeout(const Duration(seconds: 8));
      final payload = _decodeResponse(response.responseText);
      if (payload['ok'] == null) {
        payload['ok'] = response.status == 200;
      }
      if (response.status != 200 && (payload['message'] as String?) == null) {
        payload['message'] = payload['error'] ?? 'Tool request failed.';
      }
      return payload;
    } on TimeoutException {
      return <String, dynamic>{
        'ok': false,
        'message': 'Tool request timed out.',
      };
    } catch (_) {
      return <String, dynamic>{
        'ok': false,
        'message': 'Tool runtime unavailable.',
      };
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

  void _openUrlIfPresent(dynamic value) {
    final url = (value as String?)?.trim() ?? '';
    if (url.isEmpty) {
      return;
    }
    try {
      html.window.open(url, '_blank');
    } catch (_) {
      // Ignore popup/open failures and still return the API payload.
    }
  }
}

ToolRuntimeBridge createToolRuntimeBridgeImpl() {
  return _WebToolRuntimeBridge();
}
