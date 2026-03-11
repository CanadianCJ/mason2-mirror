import 'tool_runtime_bridge_stub.dart'
    if (dart.library.html) 'tool_runtime_bridge_web.dart';

abstract class ToolRuntimeBridge {
  Future<Map<String, dynamic>> fetchCatalog({
    required String tenantId,
  });

  Future<Map<String, dynamic>> fetchLatestRuns({
    required String tenantId,
    int limit = 5,
  });

  Future<Map<String, dynamic>> fetchRecommendations({
    required String tenantId,
    bool refresh = false,
  });

  Future<Map<String, dynamic>> refreshRecommendations({
    required String tenantId,
  });

  Future<Map<String, dynamic>> fetchBillingSummary({
    required String tenantId,
  });

  Future<Map<String, dynamic>> createCheckoutSession({
    required String tenantId,
    required String planId,
  });

  Future<Map<String, dynamic>> openBillingPortal({
    required String tenantId,
  });

  Future<Map<String, dynamic>> updateRecommendationStatus({
    required String tenantId,
    required String recommendationId,
    required String status,
  });

  Future<Map<String, dynamic>> runTool({
    required String tenantId,
    required String toolId,
    required String clientName,
    required Map<String, dynamic> input,
  });
}

ToolRuntimeBridge createToolRuntimeBridge() => createToolRuntimeBridgeImpl();
