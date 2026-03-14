part of '../main.dart';

typedef TenantWorkspaceChanged = Future<void> Function(
  TenantWorkspace updated, {
  required String localMessage,
});

class TenantBusinessPlanTab extends StatefulWidget {
  final TenantWorkspace workspace;
  final List<OnyxFeatureDefinition> allFeatures;
  final String syncMessage;
  final String syncedAtUtc;
  final bool syncOk;
  final TenantWorkspaceChanged onWorkspaceChanged;

  const TenantBusinessPlanTab({
    super.key,
    required this.workspace,
    required this.allFeatures,
    required this.syncMessage,
    required this.syncedAtUtc,
    required this.syncOk,
    required this.onWorkspaceChanged,
  });

  @override
  State<TenantBusinessPlanTab> createState() => _TenantBusinessPlanTabState();
}

class _TenantBusinessPlanTabState extends State<TenantBusinessPlanTab> {
  static const List<String> _stepIds = <String>[
    'tenant',
    'operations',
    'goals',
    'preferences',
  ];
  final ToolRuntimeBridge _toolRuntimeBridge = createToolRuntimeBridge();

  late final TextEditingController _businessNameController;
  late final TextEditingController _businessTypeController;
  late final TextEditingController _ownerController;
  late final TextEditingController _servicesController;
  late final TextEditingController _locationsController;
  late final TextEditingController _operatingAreaController;
  late final TextEditingController _currentToolsController;
  late final TextEditingController _mainGoalController;
  late final TextEditingController _goalsController;
  late final TextEditingController _painPointsController;
  late final TextEditingController _growthPrioritiesController;
  late final TextEditingController _notesController;
  late final TextEditingController _uploadReferencesController;

  int _currentStep = 0;
  String _size = 'Solo';
  String _currency = 'CAD';
  String _country = 'CA';
  String _tenantStatus = 'active';
  String _tenantPlanTier = 'Starter';
  String _riskTolerance = 'Balanced';
  String _automationTolerance = 'Assist only';
  String _budgetSensitivity = 'Balanced';
  bool _betaOptIn = true;
  bool _toolCatalogLoading = false;
  String _toolCatalogMessage = 'Tool catalog not loaded yet.';
  String _runningToolId = '';
  List<Map<String, dynamic>> _toolCatalog = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _latestToolRuns = const <Map<String, dynamic>>[];
  bool _billingLoading = false;
  String _billingMessage = 'Billing not loaded yet.';
  String _billingActionId = '';
  Map<String, dynamic> _billingSummary = const <String, dynamic>{};
  List<Map<String, dynamic>> _planCatalog = const <Map<String, dynamic>>[];
  bool _recommendationsLoading = false;
  String _recommendationsMessage = 'Recommendations not loaded yet.';
  String _recommendationActionId = '';
  List<Map<String, dynamic>> _recommendations = const <Map<String, dynamic>>[];

  TenantContext get _activeContext => widget.workspace.activeContext;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _businessTypeController = TextEditingController();
    _ownerController = TextEditingController();
    _servicesController = TextEditingController();
    _locationsController = TextEditingController();
    _operatingAreaController = TextEditingController();
    _currentToolsController = TextEditingController();
    _mainGoalController = TextEditingController();
    _goalsController = TextEditingController();
    _painPointsController = TextEditingController();
    _growthPrioritiesController = TextEditingController();
    _notesController = TextEditingController();
    _uploadReferencesController = TextEditingController();
    _hydrateFromContext(_activeContext);
    _refreshToolCatalog();
  }

  @override
  void didUpdateWidget(covariant TenantBusinessPlanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspace != widget.workspace) {
      _hydrateFromContext(_activeContext);
    }
    if (oldWidget.workspace.activeTenantId != widget.workspace.activeTenantId) {
      _refreshToolCatalog();
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _ownerController.dispose();
    _servicesController.dispose();
    _locationsController.dispose();
    _operatingAreaController.dispose();
    _currentToolsController.dispose();
    _mainGoalController.dispose();
    _goalsController.dispose();
    _painPointsController.dispose();
    _growthPrioritiesController.dispose();
    _notesController.dispose();
    _uploadReferencesController.dispose();
    super.dispose();
  }

  void _hydrateFromContext(TenantContext context) {
    _businessNameController.text = context.profile.businessName;
    _businessTypeController.text = context.profile.businessType;
    _ownerController.text = context.tenant.owner;
    _servicesController.text = _joinList(context.profile.servicesProducts);
    _locationsController.text = _joinList(context.profile.locations);
    _operatingAreaController.text = context.profile.operatingArea;
    _currentToolsController.text = _joinList(context.profile.currentTools);
    _mainGoalController.text = context.profile.mainGoal;
    _goalsController.text = _joinList(context.profile.goals);
    _painPointsController.text = _joinList(context.profile.painPoints);
    _growthPrioritiesController.text =
        _joinList(context.profile.growthPriorities);
    _notesController.text = context.profile.notes;
    _uploadReferencesController.text =
        _joinList(context.profile.uploadReferences);
    _size = context.profile.size;
    _currency = context.profile.currency;
    _country = context.profile.countryRegion;
    _tenantStatus = context.tenant.status;
    _tenantPlanTier = context.tenant.planTier;
    _riskTolerance = context.profile.riskTolerance;
    _automationTolerance = context.profile.automationTolerance;
    _budgetSensitivity = context.profile.budgetSensitivity;
    _betaOptIn = context.plan.betaOptIn;
    _currentStep = _normalizeStepIndex(context.onboarding.currentStepIndex);
  }

  int _normalizeStepIndex(int value) {
    if (value < 0) return 0;
    if (value >= _stepIds.length) return _stepIds.length - 1;
    return value;
  }

  String _nowIso() {
    return DateTime.now().toUtc().toIso8601String();
  }

  String _joinList(List<String> values) {
    return values.where((value) => value.trim().isNotEmpty).join(', ');
  }

  List<String> _splitList(String value) {
    final seen = <String>{};
    final output = <String>[];
    for (final part in value.split(',')) {
      final normalized = part.trim();
      if (normalized.isEmpty) continue;
      final key = normalized.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      output.add(normalized);
    }
    return output;
  }

  bool _isMeaningfulValue(
    String value, {
    List<String> placeholders = const [],
  }) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return !placeholders.contains(normalized);
  }

  List<String> _computeCompletedSteps(
    TenantRecord tenant,
    BusinessProfile profile,
  ) {
    final completed = <String>[];
    if (_isMeaningfulValue(
          profile.businessName,
          placeholders: const ['your business', 'untitled business'],
        ) &&
        _isMeaningfulValue(
          tenant.owner,
          placeholders: const ['owner'],
        ) &&
        _isMeaningfulValue(
          profile.businessType,
          placeholders: const ['general'],
        )) {
      completed.add('tenant');
    }
    if (_splitList(_servicesController.text).isNotEmpty &&
        (_splitList(_locationsController.text).isNotEmpty ||
            _isMeaningfulValue(profile.operatingArea))) {
      completed.add('operations');
    }
    if ((_isMeaningfulValue(
              profile.mainGoal,
              placeholders: const ['get organized and get paid'],
            ) ||
            _splitList(_goalsController.text).isNotEmpty) &&
        (_splitList(_painPointsController.text).isNotEmpty ||
            _splitList(_growthPrioritiesController.text).isNotEmpty)) {
      completed.add('goals');
    }
    if (_isMeaningfulValue(profile.riskTolerance) &&
        _isMeaningfulValue(profile.automationTolerance) &&
        _isMeaningfulValue(profile.budgetSensitivity)) {
      completed.add('preferences');
    }
    return completed;
  }

  BusinessProfile _buildProfile({
    required String tenantId,
    required String lastUpdatedAtUtc,
  }) {
    final previous = _activeContext.profile;
    final businessName = _businessNameController.text.trim().isEmpty
        ? previous.businessName
        : _businessNameController.text.trim();
    final businessType = _businessTypeController.text.trim().isEmpty
        ? previous.businessType
        : _businessTypeController.text.trim();
    final mainGoal = _mainGoalController.text.trim().isEmpty
        ? previous.mainGoal
        : _mainGoalController.text.trim();
    return previous.copyWith(
      tenantId: tenantId,
      businessName: businessName.isEmpty ? 'Untitled business' : businessName,
      businessType: businessType.isEmpty ? 'General' : businessType,
      size: _size,
      currency: _currency,
      countryRegion: _country,
      mainGoal: mainGoal,
      servicesProducts: _splitList(_servicesController.text),
      locations: _splitList(_locationsController.text),
      operatingArea: _operatingAreaController.text.trim(),
      currentTools: _splitList(_currentToolsController.text),
      goals: _splitList(_goalsController.text),
      painPoints: _splitList(_painPointsController.text),
      growthPriorities: _splitList(_growthPrioritiesController.text),
      riskTolerance: _riskTolerance,
      automationTolerance: _automationTolerance,
      budgetSensitivity: _budgetSensitivity,
      notes: _notesController.text.trim(),
      uploadReferences: _splitList(_uploadReferencesController.text),
      lastUpdatedAtUtc: lastUpdatedAtUtc,
    );
  }

  OnboardingState _buildOnboardingState({
    required TenantRecord tenant,
    required BusinessProfile profile,
    required int currentStepIndex,
    required String lastUpdatedAtUtc,
    required bool forceComplete,
  }) {
    final completed = forceComplete
        ? List<String>.from(_stepIds)
        : _computeCompletedSteps(tenant, profile);
    final completionPercent =
        ((completed.length / _stepIds.length) * 100).round();
    return _activeContext.onboarding.copyWith(
      currentStepIndex: _normalizeStepIndex(currentStepIndex),
      completedStepIds: completed,
      completionPercent: forceComplete ? 100 : completionPercent,
      isCompleted: forceComplete || completed.length == _stepIds.length,
      lastUpdatedAtUtc: lastUpdatedAtUtc,
    );
  }

  List<String> _missingCompletionFields() {
    final missing = <String>[];
    if (!_isMeaningfulValue(
      _businessNameController.text,
      placeholders: const ['your business', 'untitled business'],
    )) {
      missing.add('business name');
    }
    if (!_isMeaningfulValue(
      _ownerController.text,
      placeholders: const ['owner'],
    )) {
      missing.add('owner');
    }
    if (_splitList(_servicesController.text).isEmpty) {
      missing.add('services/products');
    }
    final hasGoal = _isMeaningfulValue(
          _mainGoalController.text,
          placeholders: const ['get organized and get paid'],
        ) ||
        _splitList(_goalsController.text).isNotEmpty;
    if (!hasGoal) {
      missing.add('goal');
    }
    return missing;
  }

  Future<bool> _persistCurrentTenant({
    required String localMessage,
    required int nextStepIndex,
    bool completeOnboarding = false,
    bool showSavedSnack = false,
  }) async {
    if (completeOnboarding) {
      final missing = _missingCompletionFields();
      if (missing.isNotEmpty) {
        _showSnack(
          'Add ${missing.join(', ')} before completing onboarding.',
        );
        return false;
      }
    }

    final now = _nowIso();
    final updatedTenant = _activeContext.tenant.copyWith(
      owner: _ownerController.text.trim().isEmpty
          ? _activeContext.tenant.owner
          : _ownerController.text.trim(),
      status: _tenantStatus,
      planTier: _tenantPlanTier,
      lastUpdatedAtUtc: now,
    );
    final updatedProfile = _buildProfile(
      tenantId: updatedTenant.id,
      lastUpdatedAtUtc: now,
    );
    final updatedPlan = _activeContext.plan.copyWith(
      currentTier: _tenantPlanTier,
      betaOptIn: _betaOptIn,
      lastUpdatedAtUtc: now,
    );
    final onboarding = _buildOnboardingState(
      tenant: updatedTenant,
      profile: updatedProfile,
      currentStepIndex: nextStepIndex,
      lastUpdatedAtUtc: now,
      forceComplete: completeOnboarding,
    );
    final updatedContext = _activeContext.copyWith(
      tenant: updatedTenant,
      profile: updatedProfile,
      plan: updatedPlan,
      onboarding: onboarding,
      lastUpdatedAtUtc: now,
    );
    final updatedWorkspace = widget.workspace.upsertContext(
      updatedContext,
      activeTenantId: updatedContext.tenant.id,
      lastUpdatedAtUtc: now,
    );
    await widget.onWorkspaceChanged(
      updatedWorkspace,
      localMessage: localMessage,
    );
    if (!mounted) return false;
    if (showSavedSnack) {
      _showSnack(completeOnboarding
          ? 'Business onboarding completed.'
          : 'Business context saved.');
    }
    return true;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value.map((item) => item.toString()).toList();
  }

  Map<String, dynamic> _mapObject(dynamic value) {
    if (value is! Map) {
      return const <String, dynamic>{};
    }
    return Map<String, dynamic>.from(value);
  }

  Map<String, dynamic> _buildToolInput() {
    final profile = _buildProfile(
      tenantId: _activeContext.tenant.id,
      lastUpdatedAtUtc: _nowIso(),
    );
    final businessName = _businessNameController.text.trim().isEmpty
        ? profile.businessName
        : _businessNameController.text.trim();
    final businessType = _businessTypeController.text.trim().isEmpty
        ? profile.businessType
        : _businessTypeController.text.trim();
    final goal = _mainGoalController.text.trim().isEmpty
        ? profile.mainGoal
        : _mainGoalController.text.trim();
    final locations = _splitList(_locationsController.text);
    final issues = _splitList(_painPointsController.text);
    final operatingArea = _operatingAreaController.text.trim();
    return <String, dynamic>{
      'tenant_id': _activeContext.tenant.id,
      'business_name': businessName,
      'business_type': businessType,
      'goal': goal,
      'current_issues': issues,
      'budget': _budgetSensitivity,
      'staff_size': _size,
      'marketing_status': _currentToolsController.text.trim(),
      'audience': operatingArea.isEmpty ? _joinList(locations) : operatingArea,
      'offers': _splitList(_servicesController.text),
      'sales_pipeline_status': _activeContext.onboarding.isCompleted
          ? 'Business onboarding complete'
          : 'Needs onboarding details',
      'lead_sources': locations,
      'objections': issues,
      'risk_tolerance': _riskTolerance,
      'automation_tolerance': _automationTolerance,
      'budget_sensitivity': _budgetSensitivity,
      'growth_priorities': _splitList(_growthPrioritiesController.text),
      'goals': _splitList(_goalsController.text),
      'notes': _notesController.text.trim(),
    };
  }

  Map<String, dynamic> _activeBillingTenant() {
    return _mapObject(_billingSummary['tenant']);
  }

  List<Map<String, dynamic>> _currentPlanCatalog() {
    final plansFromSummary = _mapList(_billingSummary['plans']);
    return plansFromSummary.isNotEmpty ? plansFromSummary : _planCatalog;
  }

  String _formatUsd(dynamic value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null) {
      return '\$0';
    }
    if (number == number.roundToDouble()) {
      return '\$${number.toStringAsFixed(0)}';
    }
    return '\$${number.toStringAsFixed(2)}';
  }

  String _toolLabel(String toolId) {
    switch (toolId) {
      case 'rescue_plan_v1':
        return 'Rescue Plan';
      case 'sales_followup_v1':
        return 'Sales Follow-Up';
      case 'marketing_pack_v1':
        return 'Marketing Pack';
      default:
        return toolId.replaceAll('_', ' ').trim();
    }
  }

  Future<void> _refreshToolCatalog() async {
    final tenantId = _activeContext.tenant.id;
    final businessName = _activeContext.profile.businessName;
    setState(() {
      _toolCatalogLoading = true;
      _billingLoading = true;
      _recommendationsLoading = true;
      _toolCatalogMessage = 'Loading available actions for $businessName...';
      _billingMessage = 'Loading billing and plan access for $businessName...';
      _recommendationsMessage = 'Refreshing next-step suggestions for $businessName...';
    });
    final catalog = await _toolRuntimeBridge.fetchCatalog(
      tenantId: tenantId,
    );
    final billing = await _toolRuntimeBridge.fetchBillingSummary(
      tenantId: tenantId,
    );
    final latestRuns = await _toolRuntimeBridge.fetchLatestRuns(
      tenantId: tenantId,
      limit: 5,
    );
    final recommendations = await _toolRuntimeBridge.fetchRecommendations(
      tenantId: tenantId,
      refresh: true,
    );
    if (!mounted) return;
    final tools = _mapList(catalog['tools']);
    final billingSummary = _mapObject(billing);
    final billingTenant = _mapObject(billingSummary['tenant']);
    final plans = _mapList(billingSummary['plans']);
    final runs = _mapList(latestRuns['runs']);
    final recommendationItems = _mapList(recommendations['recommendations']);
    String message;
    if (catalog['ok'] != true) {
      message = (catalog['message'] as String?) ??
          (catalog['error'] as String?) ??
          'Tool catalog unavailable.';
    } else if (tools.isEmpty) {
      message = 'No runnable tools are currently available for this business.';
    } else if (latestRuns['ok'] != true) {
      message = 'Tools loaded. Recent run history is temporarily unavailable.';
    } else {
      message = 'Only actions that are ready for this business are shown here.';
    }
    String billingMessage;
    if (billing['ok'] != true) {
      billingMessage = (billing['message'] as String?) ??
          (billing['error'] as String?) ??
          'Billing summary unavailable.';
    } else if (billingTenant.isEmpty) {
      billingMessage =
          'Billing summary loaded. Choose a business to review plan access.';
    } else if (billingTenant['checkout_required'] == true) {
      billingMessage =
          'Select a plan and start checkout to unlock plan access.';
    } else {
      final planName =
          (billingTenant['plan_name'] as String?)?.trim().isNotEmpty == true
              ? (billingTenant['plan_name'] as String).trim()
              : (billingTenant['selected_plan_name'] as String?)?.trim() ?? '';
      final status =
          ((billingTenant['status'] as String?) ?? 'inactive').toUpperCase();
      billingMessage = planName.isEmpty
          ? 'Billing summary loaded.'
          : '$planName is currently $status for this business.';
    }
    String recommendationsMessage;
    if (recommendations['ok'] != true) {
      recommendationsMessage = (recommendations['message'] as String?) ??
          (recommendations['error'] as String?) ??
          'Recommendations unavailable.';
    } else if (recommendationItems.isEmpty) {
      recommendationsMessage =
          'No next-step suggestions are active for this business right now.';
    } else {
      recommendationsMessage =
          'Suggestions are based on this business and the latest results.';
    }
    setState(() {
      _toolCatalogLoading = false;
      _billingLoading = false;
      _recommendationsLoading = false;
      _toolCatalog = tools;
      _latestToolRuns = runs;
      _toolCatalogMessage = message;
      _billingSummary = billingSummary;
      _planCatalog = plans;
      _billingMessage = billingMessage;
      _recommendations = recommendationItems;
      _recommendationsMessage = recommendationsMessage;
    });
  }

  Future<void> _handleRunTool(Map<String, dynamic> tool) async {
    final toolId = (tool['tool_id'] as String?)?.trim() ?? '';
    if (toolId.isEmpty || _runningToolId.isNotEmpty) {
      return;
    }
    final saved = await _persistCurrentTenant(
      localMessage: 'Business context saved locally.',
      nextStepIndex: _currentStep,
    );
    if (!mounted || !saved) return;

    final toolName = (tool['name'] as String?)?.trim().isNotEmpty == true
        ? (tool['name'] as String).trim()
        : toolId;
    final clientName = _businessNameController.text.trim().isEmpty
        ? _activeContext.profile.businessName
        : _businessNameController.text.trim();
    setState(() {
      _runningToolId = toolId;
      _toolCatalogMessage = 'Running $toolName for $clientName...';
    });
    final result = await _toolRuntimeBridge.runTool(
      tenantId: _activeContext.tenant.id,
      toolId: toolId,
      clientName: clientName,
      input: _buildToolInput(),
    );
    if (!mounted) return;
    final ok = result['ok'] == true;
    final message = (result['message'] as String?) ??
        (result['summary'] as String?) ??
        (ok
            ? '$toolName finished.'
            : (result['error'] as String?) ?? '$toolName failed.');
    setState(() {
      _runningToolId = '';
      _toolCatalogMessage = message;
    });
    _showSnack(message);
    await _refreshToolCatalog();
  }

  Future<void> _handleStartCheckout(Map<String, dynamic> plan) async {
    final planId = (plan['plan_id'] as String?)?.trim() ?? '';
    if (planId.isEmpty || _billingActionId.isNotEmpty) {
      return;
    }
    final planName = (plan['name'] as String?)?.trim().isNotEmpty == true
        ? (plan['name'] as String).trim()
        : planId;
    setState(() {
      _billingActionId = planId;
      _billingMessage = 'Creating checkout session for $planName...';
    });
    final result = await _toolRuntimeBridge.createCheckoutSession(
      tenantId: _activeContext.tenant.id,
      planId: planId,
    );
    if (!mounted) return;
    final ok = result['ok'] == true;
    final message = (result['message'] as String?) ??
        (ok
            ? 'Checkout session created.'
            : (result['error'] as String?) ?? 'Checkout session failed.');
    setState(() {
      _billingActionId = '';
      _billingMessage = message;
    });
    _showSnack(message);
    await _refreshToolCatalog();
  }

  Future<void> _handleOpenBillingPortal() async {
    if (_billingActionId.isNotEmpty) {
      return;
    }
    setState(() {
      _billingActionId = 'portal';
      _billingMessage = 'Opening billing portal...';
    });
    final result = await _toolRuntimeBridge.openBillingPortal(
      tenantId: _activeContext.tenant.id,
    );
    if (!mounted) return;
    final ok = result['ok'] == true;
    final message = (result['message'] as String?) ??
        (ok
            ? 'Billing portal opened.'
            : (result['error'] as String?) ?? 'Billing portal unavailable.');
    setState(() {
      _billingActionId = '';
      _billingMessage = message;
    });
    _showSnack(message);
  }

  List<Map<String, dynamic>> _currentRecommendations() {
    final current = _recommendations
        .where((item) => item['is_current'] != false)
        .toList();
    return current.isNotEmpty ? current : _recommendations;
  }

  Map<String, dynamic>? _findLinkedTool(Map<String, dynamic> recommendation) {
    final linkedToolId = (recommendation['linked_tool_id'] as String?)?.trim();
    if (linkedToolId == null || linkedToolId.isEmpty) {
      return null;
    }
    for (final tool in _toolCatalog) {
      if ((tool['tool_id'] as String?)?.trim() == linkedToolId) {
        return tool;
      }
    }
    return null;
  }

  Future<void> _handleRefreshRecommendations() async {
    final tenantId = _activeContext.tenant.id;
    final businessName = _activeContext.profile.businessName;
    setState(() {
      _recommendationsLoading = true;
      _recommendationsMessage = 'Refreshing next-step suggestions for $businessName...';
    });
    final result = await _toolRuntimeBridge.refreshRecommendations(
      tenantId: tenantId,
    );
    if (!mounted) return;
    final ok = result['ok'] == true;
    setState(() {
      _recommendationsLoading = false;
      _recommendations = _mapList(result['recommendations']);
      _recommendationsMessage = (result['message'] as String?) ??
          (ok
              ? 'Suggestions refreshed from this business and the latest results.'
              : (result['error'] as String?) ?? 'Recommendation refresh failed.');
    });
    _showSnack(_recommendationsMessage);
  }

  Future<void> _handleRecommendationStatus(
    Map<String, dynamic> recommendation,
    String status,
  ) async {
    final recommendationId =
        (recommendation['recommendation_id'] as String?)?.trim() ?? '';
    if (recommendationId.isEmpty || _recommendationActionId.isNotEmpty) {
      return;
    }
    setState(() {
      _recommendationActionId = recommendationId;
      _recommendationsMessage = 'Updating recommendation...';
    });
    final result = await _toolRuntimeBridge.updateRecommendationStatus(
      tenantId: _activeContext.tenant.id,
      recommendationId: recommendationId,
      status: status,
    );
    if (!mounted) return;
    final ok = result['ok'] == true;
    final message = (result['message'] as String?) ??
        (ok
            ? 'Recommendation updated.'
            : (result['error'] as String?) ?? 'Recommendation update failed.');
    setState(() {
      _recommendationActionId = '';
      _recommendations = _mapList(result['recommendations']);
      _recommendationsMessage = message;
    });
    _showSnack(message);
  }

  Future<void> _handleContinue() async {
    final isLastStep = _currentStep == _stepIds.length - 1;
    final nextStep = isLastStep ? _currentStep : _currentStep + 1;
    final saved = await _persistCurrentTenant(
      localMessage: isLastStep
          ? 'Business profile saved locally.'
          : 'Onboarding progress saved locally.',
      nextStepIndex: nextStep,
      completeOnboarding: isLastStep,
      showSavedSnack: isLastStep,
    );
    if (!mounted || !saved) return;
    if (isLastStep) {
      await _refreshToolCatalog();
      return;
    }
    setState(() {
      _currentStep = nextStep;
    });
  }

  Future<void> _handleBack() async {
    if (_currentStep == 0) return;
    final nextStep = _currentStep - 1;
    final saved = await _persistCurrentTenant(
      localMessage: 'Onboarding progress saved locally.',
      nextStepIndex: nextStep,
    );
    if (!mounted || !saved) return;
    setState(() {
      _currentStep = nextStep;
    });
  }

  Future<void> _handleSaveDraft() async {
    await _persistCurrentTenant(
      localMessage: 'Business context saved locally.',
      nextStepIndex: _currentStep,
      showSavedSnack: true,
    );
  }

  Future<void> _handleStepTapped(int nextStep) async {
    final saved = await _persistCurrentTenant(
      localMessage: 'Onboarding progress saved locally.',
      nextStepIndex: nextStep,
    );
    if (!mounted || !saved) return;
    setState(() {
      _currentStep = nextStep;
    });
  }

  Future<void> _handleTenantChanged(String? tenantId) async {
    if (tenantId == null || tenantId == widget.workspace.activeTenantId) {
      return;
    }
    final now = _nowIso();
    final currentTenant = _activeContext.tenant.copyWith(
      owner: _ownerController.text.trim().isEmpty
          ? _activeContext.tenant.owner
          : _ownerController.text.trim(),
      status: _tenantStatus,
      planTier: _tenantPlanTier,
      lastUpdatedAtUtc: now,
    );
    final currentProfile = _buildProfile(
      tenantId: currentTenant.id,
      lastUpdatedAtUtc: now,
    );
    final currentPlan = _activeContext.plan.copyWith(
      currentTier: _tenantPlanTier,
      betaOptIn: _betaOptIn,
      lastUpdatedAtUtc: now,
    );
    final currentOnboarding = _buildOnboardingState(
      tenant: currentTenant,
      profile: currentProfile,
      currentStepIndex: _currentStep,
      lastUpdatedAtUtc: now,
      forceComplete: false,
    );
    final currentContext = _activeContext.copyWith(
      tenant: currentTenant,
      profile: currentProfile,
      plan: currentPlan,
      onboarding: currentOnboarding,
      lastUpdatedAtUtc: now,
    );
    final switchedWorkspace = widget.workspace.upsertContext(
      currentContext,
      activeTenantId: tenantId,
      lastUpdatedAtUtc: now,
    );
    await widget.onWorkspaceChanged(
      switchedWorkspace,
      localMessage: 'Switched business and saved local progress.',
    );
  }

  Future<void> _handleCreateTenant() async {
    final nameController = TextEditingController();
    final ownerController = TextEditingController(text: _ownerController.text);
    final created = await showDialog<_TenantSeed>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add business'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Business name',
                    hintText: 'e.g. Northshore Studio',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Owner',
                    hintText: 'Owner or lead contact',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  _TenantSeed(
                    businessName: nameController.text.trim(),
                    owner: ownerController.text.trim(),
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    nameController.dispose();
    ownerController.dispose();
    if (created == null) return;

    final now = _nowIso();
    final tenantId =
        'tenant_${const Uuid().v4().replaceAll('-', '').substring(0, 12)}';
    final businessName = created.businessName.isEmpty
        ? 'Untitled business'
        : created.businessName;
    final owner = created.owner.isEmpty ? 'Owner' : created.owner;
    final newTenant = TenantRecord(
      id: tenantId,
      owner: owner,
      createdAtUtc: now,
      status: 'active',
      planTier: 'Starter',
      lastUpdatedAtUtc: now,
    );
    final newProfile = BusinessProfile.defaultProfile(
      tenantId: tenantId,
    ).copyWith(
      businessName: businessName,
      tenantId: tenantId,
      lastUpdatedAtUtc: now,
    );
    final newPlan = PlanState.defaultState().copyWith(
      currentTier: 'Starter',
      lastUpdatedAtUtc: now,
    );
    final newOnboarding = OnboardingState.defaultState().copyWith(
      currentStepIndex: 0,
      lastUpdatedAtUtc: now,
    );
    final newContext = TenantContext(
      tenant: newTenant,
      profile: newProfile,
      plan: newPlan,
      onboarding: newOnboarding,
      lastUpdatedAtUtc: now,
    );
    final savedCurrent = _activeContext.copyWith(
      tenant: _activeContext.tenant.copyWith(
        owner: _ownerController.text.trim().isEmpty
            ? _activeContext.tenant.owner
            : _ownerController.text.trim(),
        status: _tenantStatus,
        planTier: _tenantPlanTier,
        lastUpdatedAtUtc: now,
      ),
      profile: _buildProfile(
        tenantId: _activeContext.tenant.id,
        lastUpdatedAtUtc: now,
      ),
      plan: _activeContext.plan.copyWith(
        currentTier: _tenantPlanTier,
        betaOptIn: _betaOptIn,
        lastUpdatedAtUtc: now,
      ),
      onboarding: _buildOnboardingState(
        tenant: _activeContext.tenant.copyWith(
          owner: _ownerController.text.trim().isEmpty
              ? _activeContext.tenant.owner
              : _ownerController.text.trim(),
          status: _tenantStatus,
          planTier: _tenantPlanTier,
          lastUpdatedAtUtc: now,
        ),
        profile: _buildProfile(
          tenantId: _activeContext.tenant.id,
          lastUpdatedAtUtc: now,
        ),
        currentStepIndex: _currentStep,
        lastUpdatedAtUtc: now,
        forceComplete: false,
      ),
      lastUpdatedAtUtc: now,
    );
    final createdWorkspace = widget.workspace
        .upsertContext(
          savedCurrent,
          lastUpdatedAtUtc: now,
        )
        .upsertContext(
          newContext,
          activeTenantId: tenantId,
          lastUpdatedAtUtc: now,
        );
    await widget.onWorkspaceChanged(
      createdWorkspace,
      localMessage: 'Business workspace created and saved locally.',
    );
    if (!mounted) return;
    _showSnack('Business added.');
  }

  Widget _buildHeaderCard(ThemeData theme, ColorScheme scheme) {
    final onboarding = _activeContext.onboarding;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Active business',
                    child: DropdownButtonFormField<String>(
                      initialValue: widget.workspace.activeTenantId,
                      items: widget.workspace.contexts
                          .map(
                            (context) => DropdownMenuItem(
                              value: context.tenant.id,
                              child: Text(
                                '${context.profile.businessName} - ${context.tenant.owner}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _handleTenantChanged,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _handleCreateTenant,
                  icon: const Icon(Icons.add_business),
                  label: const Text('Add business'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    widget.syncOk ? Icons.sync : Icons.save_outlined,
                    size: 18,
                  ),
                  label: Text(widget.syncMessage),
                ),
                Chip(
                  label: Text(
                    onboarding.isCompleted
                        ? 'Onboarding complete'
                        : 'Progress ${onboarding.completionPercent}%',
                  ),
                ),
                Chip(
                  label: Text('Tier ${_activeContext.tenant.planTier}'),
                ),
                Chip(
                  label: Text(_activeContext.tenant.status.toUpperCase()),
                ),
              ],
            ),
            if (widget.syncedAtUtc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Last saved: ${widget.syncedAtUtc}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Step _buildTenantStep(ThemeData theme) {
    return Step(
      title: const Text('Business'),
      subtitle: const Text('Business identity, owner, and tier'),
      isActive: _currentStep >= 0,
      state: _activeContext.onboarding.completedStepIds.contains('tenant')
          ? StepState.complete
          : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: _LabeledField(
                  label: 'Business name',
                  child: TextField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Your business name',
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: _LabeledField(
                  label: 'Owner',
                  child: TextField(
                    controller: _ownerController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Owner or lead contact',
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: _LabeledField(
                  label: 'Business type',
                  child: TextField(
                    controller: _businessTypeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Studio, Agency, Contractor',
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: _LabeledField(
                  label: 'Business status',
                  child: DropdownButtonFormField<String>(
                    initialValue: _tenantStatus,
                    items: const [
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: 'pilot',
                        child: Text('Pilot'),
                      ),
                      DropdownMenuItem(
                        value: 'paused',
                        child: Text('Paused'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _tenantStatus = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: _LabeledField(
                  label: 'Plan / tier',
                  child: DropdownButtonFormField<String>(
                    initialValue: _tenantPlanTier,
                    items: const [
                      DropdownMenuItem(
                        value: 'Starter',
                        child: Text('Starter'),
                      ),
                      DropdownMenuItem(
                        value: 'Growth',
                        child: Text('Growth'),
                      ),
                      DropdownMenuItem(
                        value: 'Founder',
                        child: Text('Founder'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _tenantPlanTier = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Create one business workspace per client or company so context stays scoped and editable.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Step _buildOperationsStep() {
    return Step(
      title: const Text('Operations'),
      subtitle: const Text('How the business runs day to day'),
      isActive: _currentStep >= 1,
      state: _activeContext.onboarding.completedStepIds.contains('operations')
          ? StepState.complete
          : StepState.indexed,
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 220,
            child: _LabeledField(
              label: 'Team size',
              child: DropdownButtonFormField<String>(
                initialValue: _size,
                items: const [
                  DropdownMenuItem(
                    value: 'Solo',
                    child: Text('Solo'),
                  ),
                  DropdownMenuItem(
                    value: '2-5',
                    child: Text('2-5'),
                  ),
                  DropdownMenuItem(
                    value: '6-15',
                    child: Text('6-15'),
                  ),
                  DropdownMenuItem(
                    value: '16+',
                    child: Text('16+'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _size = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: _LabeledField(
              label: 'Currency',
              child: DropdownButtonFormField<String>(
                initialValue: _currency,
                items: const [
                  DropdownMenuItem(
                    value: 'CAD',
                    child: Text('CAD'),
                  ),
                  DropdownMenuItem(
                    value: 'USD',
                    child: Text('USD'),
                  ),
                  DropdownMenuItem(
                    value: 'EUR',
                    child: Text('EUR'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _currency = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 220,
            child: _LabeledField(
              label: 'Country / region',
              child: DropdownButtonFormField<String>(
                initialValue: _country,
                items: const [
                  DropdownMenuItem(
                    value: 'CA',
                    child: Text('Canada'),
                  ),
                  DropdownMenuItem(
                    value: 'US',
                    child: Text('United States'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _country = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 360,
            child: _LabeledField(
              label: 'Services / products',
              child: TextField(
                controller: _servicesController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Comma separated',
                ),
              ),
            ),
          ),
          SizedBox(
            width: 320,
            child: _LabeledField(
              label: 'Locations',
              child: TextField(
                controller: _locationsController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Comma separated',
                ),
              ),
            ),
          ),
          SizedBox(
            width: 320,
            child: _LabeledField(
              label: 'Operating area',
              child: TextField(
                controller: _operatingAreaController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Local, regional, nationwide, remote-first',
                ),
              ),
            ),
          ),
          SizedBox(
            width: 360,
            child: _LabeledField(
              label: 'Current tools / software',
              child: TextField(
                controller: _currentToolsController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Comma separated',
                ),
              ),
            ),
          ),
          SizedBox(
            width: 360,
            child: _LabeledField(
              label: 'Upload references',
              child: TextField(
                controller: _uploadReferencesController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'File names or internal refs, comma separated',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildGoalsStep() {
    return Step(
      title: const Text('Goals'),
      subtitle: const Text('Targets, pain points, and growth priorities'),
      isActive: _currentStep >= 2,
      state: _activeContext.onboarding.completedStepIds.contains('goals')
          ? StepState.complete
          : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledField(
            label: 'Main goal right now',
            child: TextField(
              controller: _mainGoalController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    'e.g. Fill schedule, reduce admin load, improve margins',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 360,
                child: _LabeledField(
                  label: 'Goals',
                  child: TextField(
                    controller: _goalsController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Comma separated',
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 360,
                child: _LabeledField(
                  label: 'Pain points',
                  child: TextField(
                    controller: _painPointsController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Comma separated',
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 360,
                child: _LabeledField(
                  label: 'Growth priorities',
                  child: TextField(
                    controller: _growthPrioritiesController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Comma separated',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Step _buildPreferencesStep() {
    return Step(
      title: const Text('Preferences'),
      subtitle: const Text('Risk, automation, budget, and notes'),
      isActive: _currentStep >= 3,
      state: _activeContext.onboarding.completedStepIds.contains('preferences')
          ? StepState.complete
          : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 240,
                child: _LabeledField(
                  label: 'Risk tolerance',
                  child: DropdownButtonFormField<String>(
                    initialValue: _riskTolerance,
                    items: const [
                      DropdownMenuItem(
                        value: 'Conservative',
                        child: Text('Conservative'),
                      ),
                      DropdownMenuItem(
                        value: 'Balanced',
                        child: Text('Balanced'),
                      ),
                      DropdownMenuItem(
                        value: 'Aggressive',
                        child: Text('Aggressive'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _riskTolerance = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: _LabeledField(
                  label: 'Automation tolerance',
                  child: DropdownButtonFormField<String>(
                    initialValue: _automationTolerance,
                    items: const [
                      DropdownMenuItem(
                        value: 'Assist only',
                        child: Text('Assist only'),
                      ),
                      DropdownMenuItem(
                        value: 'Supervised automation',
                        child: Text('Supervised automation'),
                      ),
                      DropdownMenuItem(
                        value: 'High automation',
                        child: Text('High automation'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _automationTolerance = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: _LabeledField(
                  label: 'Budget sensitivity',
                  child: DropdownButtonFormField<String>(
                    initialValue: _budgetSensitivity,
                    items: const [
                      DropdownMenuItem(
                        value: 'Tight',
                        child: Text('Tight'),
                      ),
                      DropdownMenuItem(
                        value: 'Balanced',
                        child: Text('Balanced'),
                      ),
                      DropdownMenuItem(
                        value: 'Flexible',
                        child: Text('Flexible'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _budgetSensitivity = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Notes',
            child: TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    'Anything operational, compliance, staffing, or partner related',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Opt into early feature testing'),
            subtitle: const Text(
              'Useful for pilot businesses that want new tools sooner.',
            ),
            value: _betaOptIn,
            onChanged: (value) {
              setState(() {
                _betaOptIn = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(ThemeData theme, ColorScheme scheme) {
    final billingTenant = _activeBillingTenant();
    final plans = _currentPlanCatalog();
    final enabledFeatureIds = _stringList(
      billingTenant['enabled_features'],
    );
    final checkoutRequired = billingTenant['checkout_required'] == true;
    final featureIds = enabledFeatureIds.isNotEmpty
        ? enabledFeatureIds
        : (checkoutRequired
            ? const <String>[]
            : _activeContext.plan.enabledFeatures);
    final activeFeatureIds = <String>{
      ...featureIds,
      ..._activeContext.plan.addonFeatures,
    };
    final activeFeatures = widget.allFeatures
        .where((feature) => activeFeatureIds.contains(feature.id))
        .toList();
    final activeTools = _stringList(billingTenant['enabled_tools']);
    final availableAddons = _mapList(billingTenant['available_addons']);
    final currentPlanId = (billingTenant['plan_id'] as String?)?.trim() ?? '';
    final selectedPlanId =
        (billingTenant['selected_plan_id'] as String?)?.trim().isNotEmpty ==
                true
            ? (billingTenant['selected_plan_id'] as String).trim()
            : currentPlanId;
    final currentPlanName =
        (billingTenant['plan_name'] as String?)?.trim().isNotEmpty == true
            ? (billingTenant['plan_name'] as String).trim()
            : ((billingTenant['selected_plan_name'] as String?)?.trim() ?? '');
    final billingStatus =
        ((billingTenant['status'] as String?) ?? 'inactive').toUpperCase();
    final renewalDate =
        ((billingTenant['renewal_date'] as String?) ?? '').trim();
    final provider = ((billingTenant['provider'] as String?) ?? '').trim();
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Billing and plan access',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    currentPlanName.isEmpty
                        ? 'No active subscription yet.'
                        : 'Current plan: $currentPlanName',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _billingLoading || _billingActionId.isNotEmpty
                      ? null
                      : _refreshToolCatalog,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _billingLoading || _billingActionId.isNotEmpty
                      ? null
                      : _handleOpenBillingPortal,
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Portal'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    _billingLoading
                        ? Icons.sync
                        : checkoutRequired
                            ? Icons.lock_outline
                            : Icons.credit_score_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _billingMessage,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            if (_billingLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Status $billingStatus')),
                if (provider.isNotEmpty) Chip(label: Text(provider)),
                if (renewalDate.isNotEmpty) Chip(label: Text('Renews $renewalDate')),
                if (checkoutRequired) const Chip(label: Text('Checkout required')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Entitled tools',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (activeTools.isEmpty)
              Text(
                checkoutRequired
                    ? 'No tools are unlocked yet. Start checkout on one of the plans below to activate the catalog.'
                    : 'No entitled tools are currently active for this business.',
                style: theme.textTheme.bodySmall,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeTools
                    .map(
                      (toolId) => Chip(
                        avatar: const Icon(Icons.build_circle_outlined, size: 18),
                        label: Text(_toolLabel(toolId)),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            Text(
              'Enabled features',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (activeFeatures.isEmpty)
              Text(
                'No active features are currently attached to this business.',
                style: theme.textTheme.bodySmall,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeFeatures
                    .map(
                      (feature) => Chip(
                        avatar: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(feature.label),
                      ),
                    )
                    .toList(),
              ),
            if (availableAddons.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Available add-ons',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableAddons
                    .map(
                      (addon) => Chip(
                        avatar: const Icon(Icons.add_circle_outline, size: 18),
                        label: Text(
                          '${(addon['name'] as String?) ?? 'Add-on'} - ${_formatUsd(addon['price_usd'])}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Plans',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (plans.isEmpty)
              Text(
                'No launchable plans are configured yet.',
                style: theme.textTheme.bodySmall,
              )
            else
              Column(
                children: plans.map((plan) {
                  final planId = (plan['plan_id'] as String?)?.trim() ?? '';
                  final planName = (plan['name'] as String?)?.trim() ?? planId;
                  final tools = _stringList(plan['enabled_tools']);
                  final interval =
                      ((plan['billing_interval'] as String?) ?? 'monthly')
                          .trim();
                  final isCurrent = currentPlanId == planId && !checkoutRequired;
                  final isSelected = selectedPlanId == planId;
                  final buttonLabel = isCurrent
                      ? 'Active plan'
                      : isSelected && checkoutRequired
                          ? 'Continue checkout'
                          : 'Choose plan';
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? scheme.primary
                            : scheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$planName - ${_formatUsd(plan['price_usd'])} / $interval',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (plan['launch_wedge'] == true)
                              Chip(
                                label: const Text('Launch wedge'),
                                backgroundColor:
                                    scheme.primaryContainer.withValues(alpha: 0.7),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (plan['description'] as String?) ?? '',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (tools.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tools
                                .map(
                                  (toolId) => Chip(
                                    label: Text(_toolLabel(toolId)),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: _billingLoading ||
                                    _billingActionId.isNotEmpty ||
                                    isCurrent
                                ? null
                                : () => _handleStartCheckout(plan),
                            child: Text(buttonLabel),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(ThemeData theme, ColorScheme scheme) {
    final recommendations = _currentRecommendations();
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended next steps',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'These suggestions are based on your business details and the latest results.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _recommendationsLoading || _recommendationActionId.isNotEmpty
                      ? null
                      : _handleRefreshRecommendations,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    _recommendationsLoading
                        ? Icons.sync
                        : recommendations.isEmpty
                            ? Icons.info_outline
                            : Icons.tips_and_updates_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _recommendationsMessage,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            if (_recommendationsLoading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ] else if (recommendations.isEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'No suggestions are active right now.',
                style: theme.textTheme.bodyMedium,
              ),
            ] else ...[
              const SizedBox(height: 16),
              Column(
                children: recommendations.map((recommendation) {
                  final recommendationId =
                      (recommendation['recommendation_id'] as String?) ?? '';
                  final status =
                      ((recommendation['status'] as String?) ?? 'new')
                          .toUpperCase();
                  final type =
                      ((recommendation['type'] as String?) ?? 'action')
                          .toUpperCase();
                  final title = (recommendation['title'] as String?) ??
                      'Recommendation';
                  final description =
                      (recommendation['description'] as String?) ?? '';
                  final reason =
                      (recommendation['reason'] as String?) ?? '';
                  final impact = (recommendation['estimated_roi_impact']
                          as String?) ??
                      '';
                  final riskLevel =
                      (recommendation['risk_level'] as String?) ?? '';
                  final evidence = _mapList(recommendation['evidence']);
                  final linkedTool = _findLinkedTool(recommendation);
                  final runningAction =
                      _recommendationActionId == recommendationId;
                  final normalizedStatus =
                      ((recommendation['status'] as String?) ?? 'new')
                          .toLowerCase();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (description.isNotEmpty)
                          Text(
                            description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        if (reason.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Reason: $reason',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (impact.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Impact: $impact',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text(type)),
                            Chip(label: Text(status)),
                            if (riskLevel.isNotEmpty)
                              Chip(label: Text('Risk $riskLevel')),
                            if (recommendation['priority'] != null)
                              Chip(
                                label: Text(
                                  'Priority ${recommendation['priority']}',
                                ),
                              ),
                            if (linkedTool != null)
                              Chip(
                                label: Text(
                                  'Linked ${(linkedTool['name'] as String?) ?? (linkedTool['tool_id'] as String?) ?? 'tool'}',
                                ),
                              ),
                          ],
                        ),
                        if (evidence.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: evidence.take(2).map((item) {
                              final label =
                                  (item['label'] as String?) ?? 'Evidence';
                              final value = (item['value'] as String?) ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '$label: $value',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (normalizedStatus == 'new')
                              OutlinedButton(
                                onPressed: runningAction
                                    ? null
                                    : () => _handleRecommendationStatus(
                                          recommendation,
                                          'seen',
                                        ),
                                child: const Text('Mark seen'),
                              ),
                            if (normalizedStatus == 'new' ||
                                normalizedStatus == 'seen')
                              FilledButton(
                                onPressed: runningAction
                                    ? null
                                    : () => _handleRecommendationStatus(
                                          recommendation,
                                          'accepted',
                                        ),
                                child: const Text('Accept'),
                              ),
                            if (normalizedStatus == 'new' ||
                                normalizedStatus == 'seen' ||
                                normalizedStatus == 'accepted')
                              TextButton(
                                onPressed: runningAction
                                    ? null
                                    : () => _handleRecommendationStatus(
                                          recommendation,
                                          'dismissed',
                                        ),
                                child: const Text('Dismiss'),
                              ),
                            if (normalizedStatus == 'accepted' &&
                                linkedTool != null)
                              FilledButton.icon(
                                onPressed: _runningToolId.isNotEmpty
                                    ? null
                                    : () => _handleRunTool(linkedTool),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Run linked tool'),
                              ),
                            if (normalizedStatus == 'accepted')
                              OutlinedButton(
                                onPressed: runningAction
                                    ? null
                                    : () => _handleRecommendationStatus(
                                          recommendation,
                                          'completed',
                                        ),
                                child: const Text('Mark complete'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolCatalogCard(ThemeData theme, ColorScheme scheme) {
    final businessName = _activeContext.profile.businessName;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Only actions that are ready for $businessName appear here. Each run saves a result to your history.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    _toolCatalogLoading
                        ? Icons.sync
                        : _toolCatalog.isEmpty
                            ? Icons.info_outline
                            : Icons.handyman_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _toolCatalogMessage,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            if (_toolCatalogLoading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ] else if (_toolCatalog.isEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'No actions are ready for this business yet.',
                style: theme.textTheme.bodyMedium,
              ),
            ] else ...[
              const SizedBox(height: 16),
              Column(
                children: _toolCatalog.map((tool) {
                  final toolId = (tool['tool_id'] as String?) ?? '';
                  final toolName = (tool['name'] as String?) ?? toolId;
                  final description = (tool['description'] as String?) ?? '';
                  final category = (tool['category'] as String?) ?? '';
                  final version = (tool['version'] as String?) ?? '';
                  final riskLevel = (tool['risk_level'] as String?) ?? '';
                  final requiredIntegrations =
                      _stringList(tool['required_integrations']);
                  final running = _runningToolId == toolId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    toolName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      description,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: running || _runningToolId.isNotEmpty
                                  ? null
                                  : () => _handleRunTool(tool),
                              icon: running
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.play_arrow),
                              label: Text(running ? 'Running' : 'Run tool'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (category.isNotEmpty) Chip(label: Text(category)),
                            if (riskLevel.isNotEmpty)
                              Chip(label: Text('Risk $riskLevel')),
                            if (version.isNotEmpty) Chip(label: Text(version)),
                          ],
                        ),
                        if (requiredIntegrations.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Required integrations: ${requiredIntegrations.join(', ')}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            if (_latestToolRuns.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Latest outputs',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: _latestToolRuns.map((run) {
                  final toolName = (run['tool_name'] as String?) ??
                      (run['tool_id'] as String?) ??
                      'Tool run';
                  final summary = (run['summary'] as String?) ?? '';
                  final generatedAt = (run['generated_at_utc'] as String?) ?? '';
                  final artifactPath = (run['artifact_path'] as String?) ?? '';
                  final recommendations = _stringList(run['recommendations']);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(toolName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (summary.isNotEmpty) Text(summary),
                        if (recommendations.isNotEmpty)
                          Text(
                            'Next: ${recommendations.first}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        if (artifactPath.isNotEmpty)
                          Text(
                            artifactPath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    trailing: generatedAt.isEmpty
                        ? null
                        : Text(
                            generatedAt,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business & Plan',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Capture each business profile so onboarding stays editable, personal, and useful across future work.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _buildHeaderCard(theme, scheme),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Stepper(
                    currentStep: _currentStep,
                    onStepTapped: _handleStepTapped,
                    onStepContinue: _handleContinue,
                    onStepCancel: _handleBack,
                    physics: const ClampingScrollPhysics(),
                    controlsBuilder: (context, details) {
                      final isLastStep = _currentStep == _stepIds.length - 1;
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton(
                              onPressed: details.onStepContinue,
                              child: Text(
                                isLastStep
                                    ? 'Complete onboarding'
                                    : 'Save and continue',
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _handleSaveDraft,
                              child: const Text('Save draft'),
                            ),
                            if (_currentStep > 0)
                              TextButton(
                                onPressed: details.onStepCancel,
                                child: const Text('Back'),
                              ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      _buildTenantStep(theme),
                      _buildOperationsStep(),
                      _buildGoalsStep(),
                      _buildPreferencesStep(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPlanCard(theme, scheme),
              const SizedBox(height: 16),
              _buildRecommendationsCard(theme, scheme),
              const SizedBox(height: 16),
              _buildToolCatalogCard(theme, scheme),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantSeed {
  final String businessName;
  final String owner;

  const _TenantSeed({
    required this.businessName,
    required this.owner,
  });
}
