import 'business_context_bridge.dart';

class _StubBusinessContextBridge implements BusinessContextBridge {
  @override
  Future<Map<String, dynamic>?> fetchWorkspace() async {
    return null;
  }

  @override
  Future<BusinessContextSyncStatus> saveWorkspace(
    Map<String, dynamic> workspace,
  ) async {
    return const BusinessContextSyncStatus(
      ok: false,
      message: 'Control-plane sync unavailable on this platform.',
      syncedAtUtc: '',
    );
  }
}

BusinessContextBridge createBusinessContextBridgeImpl() {
  return _StubBusinessContextBridge();
}
