import 'business_context_bridge_stub.dart'
    if (dart.library.html) 'business_context_bridge_web.dart';

class BusinessContextSyncStatus {
  final bool ok;
  final String message;
  final String syncedAtUtc;

  const BusinessContextSyncStatus({
    required this.ok,
    required this.message,
    required this.syncedAtUtc,
  });
}

abstract class BusinessContextBridge {
  Future<Map<String, dynamic>?> fetchWorkspace();

  Future<BusinessContextSyncStatus> saveWorkspace(
    Map<String, dynamic> workspace,
  );
}

BusinessContextBridge createBusinessContextBridge() =>
    createBusinessContextBridgeImpl();
