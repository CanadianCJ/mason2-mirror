import 'tool_runtime_bridge.dart';

class _StubToolRuntimeBridge implements ToolRuntimeBridge {
  const _StubToolRuntimeBridge();

  @override
  Future<Map<String, dynamic>> fetchCatalog({
    required String tenantId,
  }) async {
    return <String, dynamic>{
      'ok': false,
      'tenant_id': tenantId,
      'tools': const <Map<String, dynamic>>[],
      'message': 'Tool runtime unavailable on this platform.',
    };
  }

  @override
  Future<Map<String, dynamic>> fetchLatestRuns({
    required String tenantId,
    int limit = 5,
  }) async {
    return <String, dynamic>{
      'ok': false,
      'tenant_id': tenantId,
      'runs': const <Map<String, dynamic>>[],
      'message': 'Tool runtime unavailable on this platform.',
    };
  }

  @override
  Future<Map<String, dynamic>> fetchRecommendations({
    required String tenantId,
    bool refresh = false,
  }) async {
    return <String, dynamic>{
      'ok': false,
      'tenant_id': tenantId,
      'recommendations': const <Map<String, dynamic>>[],
      'message': 'Recommendation runtime unavailable on this platform.',
    };
  }

  @override
  Future<Map<String, dynamic>> fetchBillingSummary({
    required String tenantId,
  }) async {
    return <String, dynamic>{
      'ok': false,
      'tenant_id': tenantId,
      'message': 'Billing runtime unavailable on this platform.',
    };
  }

  @override
  Future<Map<String, dynamic>> createCheckoutSession({
    required String tenantId,
    required String planId,
  }) async {
    return <String, dynamic>{
      'ok': false,
      'tenant_id': tenantId,
      'plan_id': planId,
      'message': 'Billing runtime unavailable on this platform.',
    };
  }

  @override
  Future<Map<String, dynamic>> openBillingPortal({
    required String tenantId,
  }) async {
    return <String, dynamic>{
      'ok': false,
      'tenant_id': tenantId,
      'message': 'Billing runtime unavailable on this platform.',
    };
  }

  @override
  Future<Map<String, dynamic>> refreshRecommendations({
    required String tenantId,
  }) async {
    return <String, dynamic>{
      'ok': false,
      'tenant_id': tenantId,
      'recommendations': const <Map<String, dynamic>>[],
      'message': 'Recommendation runtime unavailable on this platform.',
    };
  }

  @override
  Future<Map<String, dynamic>> updateRecommendationStatus({
    required String tenantId,
    required String recommendationId,
    required String status,
  }) async {
    return <String, dynamic>{
      'ok': false,
      'tenant_id': tenantId,
      'recommendation_id': recommendationId,
      'message': 'Recommendation runtime unavailable on this platform.',
    };
  }

  @override
  Future<Map<String, dynamic>> runTool({
    required String tenantId,
    required String toolId,
    required String clientName,
    required Map<String, dynamic> input,
  }) async {
    return <String, dynamic>{
      'ok': false,
      'tenant_id': tenantId,
      'tool_id': toolId,
      'message': 'Tool runtime unavailable on this platform.',
    };
  }
}

ToolRuntimeBridge createToolRuntimeBridgeImpl() {
  return const _StubToolRuntimeBridge();
}
