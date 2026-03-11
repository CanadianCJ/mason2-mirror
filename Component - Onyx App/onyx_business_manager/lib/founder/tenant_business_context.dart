part of '../main.dart';

class TenantRecord {
  final String id;
  final String owner;
  final String createdAtUtc;
  final String status;
  final String planTier;
  final String lastUpdatedAtUtc;

  const TenantRecord({
    required this.id,
    required this.owner,
    required this.createdAtUtc,
    required this.status,
    required this.planTier,
    required this.lastUpdatedAtUtc,
  });

  factory TenantRecord.defaultTenant() {
    final now = DateTime.now().toUtc().toIso8601String();
    return TenantRecord(
      id: 'tenant_primary',
      owner: 'Owner',
      createdAtUtc: now,
      status: 'active',
      planTier: 'Starter',
      lastUpdatedAtUtc: now,
    );
  }

  TenantRecord copyWith({
    String? id,
    String? owner,
    String? createdAtUtc,
    String? status,
    String? planTier,
    String? lastUpdatedAtUtc,
  }) {
    return TenantRecord(
      id: id ?? this.id,
      owner: owner ?? this.owner,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      status: status ?? this.status,
      planTier: planTier ?? this.planTier,
      lastUpdatedAtUtc: lastUpdatedAtUtc ?? this.lastUpdatedAtUtc,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner': owner,
      'createdAtUtc': createdAtUtc,
      'status': status,
      'planTier': planTier,
      'lastUpdatedAtUtc': lastUpdatedAtUtc,
    };
  }

  static TenantRecord fromJson(Map<String, dynamic> json) {
    final fallback = TenantRecord.defaultTenant();
    return TenantRecord(
      id: json['id'] as String? ?? fallback.id,
      owner: json['owner'] as String? ?? fallback.owner,
      createdAtUtc: json['createdAtUtc'] as String? ?? fallback.createdAtUtc,
      status: json['status'] as String? ?? fallback.status,
      planTier: json['planTier'] as String? ?? fallback.planTier,
      lastUpdatedAtUtc:
          json['lastUpdatedAtUtc'] as String? ?? fallback.lastUpdatedAtUtc,
    );
  }
}

class OnboardingState {
  final int currentStepIndex;
  final List<String> completedStepIds;
  final bool isCompleted;
  final int completionPercent;
  final String lastUpdatedAtUtc;

  const OnboardingState({
    required this.currentStepIndex,
    required this.completedStepIds,
    required this.isCompleted,
    required this.completionPercent,
    required this.lastUpdatedAtUtc,
  });

  factory OnboardingState.defaultState() {
    return OnboardingState(
      currentStepIndex: 0,
      completedStepIds: const <String>[],
      isCompleted: false,
      completionPercent: 0,
      lastUpdatedAtUtc: DateTime.now().toUtc().toIso8601String(),
    );
  }

  OnboardingState copyWith({
    int? currentStepIndex,
    List<String>? completedStepIds,
    bool? isCompleted,
    int? completionPercent,
    String? lastUpdatedAtUtc,
  }) {
    return OnboardingState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      isCompleted: isCompleted ?? this.isCompleted,
      completionPercent: completionPercent ?? this.completionPercent,
      lastUpdatedAtUtc: lastUpdatedAtUtc ?? this.lastUpdatedAtUtc,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStepIndex': currentStepIndex,
      'completedStepIds': completedStepIds,
      'isCompleted': isCompleted,
      'completionPercent': completionPercent,
      'lastUpdatedAtUtc': lastUpdatedAtUtc,
    };
  }

  static OnboardingState fromJson(Map<String, dynamic> json) {
    final fallback = OnboardingState.defaultState();
    return OnboardingState(
      currentStepIndex: json['currentStepIndex'] as int? ?? 0,
      completedStepIds: (json['completedStepIds'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          fallback.completedStepIds,
      isCompleted: json['isCompleted'] as bool? ?? fallback.isCompleted,
      completionPercent:
          json['completionPercent'] as int? ?? fallback.completionPercent,
      lastUpdatedAtUtc:
          json['lastUpdatedAtUtc'] as String? ?? fallback.lastUpdatedAtUtc,
    );
  }
}

class TenantContext {
  final TenantRecord tenant;
  final BusinessProfile profile;
  final PlanState plan;
  final OnboardingState onboarding;
  final String lastUpdatedAtUtc;

  const TenantContext({
    required this.tenant,
    required this.profile,
    required this.plan,
    required this.onboarding,
    required this.lastUpdatedAtUtc,
  });

  factory TenantContext.defaultContext({
    BusinessProfile? profile,
    PlanState? plan,
  }) {
    final tenant = TenantRecord.defaultTenant();
    final now = DateTime.now().toUtc().toIso8601String();
    final basePlan = (plan ?? PlanState.defaultState()).copyWith(
      currentTier: tenant.planTier,
      lastUpdatedAtUtc: now,
    );
    final baseProfile = (profile ?? BusinessProfile.defaultProfile()).copyWith(
      tenantId: tenant.id,
      lastUpdatedAtUtc: now,
    );
    return TenantContext(
      tenant: tenant,
      profile: baseProfile,
      plan: basePlan,
      onboarding: OnboardingState.defaultState(),
      lastUpdatedAtUtc: now,
    );
  }

  TenantContext copyWith({
    TenantRecord? tenant,
    BusinessProfile? profile,
    PlanState? plan,
    OnboardingState? onboarding,
    String? lastUpdatedAtUtc,
  }) {
    return TenantContext(
      tenant: tenant ?? this.tenant,
      profile: profile ?? this.profile,
      plan: plan ?? this.plan,
      onboarding: onboarding ?? this.onboarding,
      lastUpdatedAtUtc: lastUpdatedAtUtc ?? this.lastUpdatedAtUtc,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant': tenant.toJson(),
      'profile': profile.toJson(),
      'plan': plan.toJson(),
      'onboarding': onboarding.toJson(),
      'lastUpdatedAtUtc': lastUpdatedAtUtc,
    };
  }

  static TenantContext fromJson(Map<String, dynamic> json) {
    return TenantContext(
      tenant: TenantRecord.fromJson(
        Map<String, dynamic>.from(json['tenant'] as Map? ?? const {}),
      ),
      profile: BusinessProfile.fromJson(
        Map<String, dynamic>.from(json['profile'] as Map? ?? const {}),
      ),
      plan: PlanState.fromJson(
        Map<String, dynamic>.from(json['plan'] as Map? ?? const {}),
      ),
      onboarding: OnboardingState.fromJson(
        Map<String, dynamic>.from(json['onboarding'] as Map? ?? const {}),
      ),
      lastUpdatedAtUtc: json['lastUpdatedAtUtc'] as String? ??
          DateTime.now().toUtc().toIso8601String(),
    );
  }
}

class TenantWorkspace {
  final int version;
  final String activeTenantId;
  final List<TenantContext> contexts;
  final String lastUpdatedAtUtc;

  const TenantWorkspace({
    required this.version,
    required this.activeTenantId,
    required this.contexts,
    required this.lastUpdatedAtUtc,
  });

  factory TenantWorkspace.defaultWorkspace({
    BusinessProfile? profile,
    PlanState? plan,
  }) {
    final context = TenantContext.defaultContext(
      profile: profile,
      plan: plan,
    );
    return TenantWorkspace(
      version: 1,
      activeTenantId: context.tenant.id,
      contexts: <TenantContext>[context],
      lastUpdatedAtUtc: context.lastUpdatedAtUtc,
    );
  }

  TenantContext get activeContext {
    for (final context in contexts) {
      if (context.tenant.id == activeTenantId) {
        return context;
      }
    }
    return contexts.isNotEmpty
        ? contexts.first
        : TenantContext.defaultContext();
  }

  TenantWorkspace copyWith({
    int? version,
    String? activeTenantId,
    List<TenantContext>? contexts,
    String? lastUpdatedAtUtc,
  }) {
    return TenantWorkspace(
      version: version ?? this.version,
      activeTenantId: activeTenantId ?? this.activeTenantId,
      contexts: contexts ?? this.contexts,
      lastUpdatedAtUtc: lastUpdatedAtUtc ?? this.lastUpdatedAtUtc,
    );
  }

  TenantWorkspace upsertContext(
    TenantContext updated, {
    String? activeTenantId,
    String? lastUpdatedAtUtc,
  }) {
    final nextContexts = List<TenantContext>.from(contexts);
    final index =
        nextContexts.indexWhere((item) => item.tenant.id == updated.tenant.id);
    if (index >= 0) {
      nextContexts[index] = updated;
    } else {
      nextContexts.add(updated);
    }
    return copyWith(
      activeTenantId: activeTenantId ?? this.activeTenantId,
      contexts: nextContexts,
      lastUpdatedAtUtc:
          lastUpdatedAtUtc ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'activeTenantId': activeTenantId,
      'contexts': contexts.map((context) => context.toJson()).toList(),
      'lastUpdatedAtUtc': lastUpdatedAtUtc,
    };
  }

  static TenantWorkspace fromJson(Map<String, dynamic> json) {
    final contexts = (json['contexts'] as List<dynamic>?)
            ?.map(
              (item) => TenantContext.fromJson(
                Map<String, dynamic>.from(item as Map? ?? const {}),
              ),
            )
            .toList() ??
        <TenantContext>[];
    if (contexts.isEmpty) {
      return TenantWorkspace(
        version: json['version'] as int? ?? 1,
        activeTenantId: json['activeTenantId'] as String? ?? '',
        contexts: const <TenantContext>[],
        lastUpdatedAtUtc: json['lastUpdatedAtUtc'] as String? ?? '',
      );
    }
    return TenantWorkspace(
      version: json['version'] as int? ?? 1,
      activeTenantId:
          json['activeTenantId'] as String? ?? contexts.first.tenant.id,
      contexts: contexts,
      lastUpdatedAtUtc: json['lastUpdatedAtUtc'] as String? ??
          contexts.first.lastUpdatedAtUtc,
    );
  }
}

class TenantWorkspaceStorage {
  static const String _storageKey = 'onyx_tenant_workspace_v1';

  Future<TenantWorkspace> loadWorkspace({
    required BusinessProfile fallbackProfile,
    required PlanState fallbackPlan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return TenantWorkspace.defaultWorkspace(
        profile: fallbackProfile,
        plan: fallbackPlan,
      );
    }
    try {
      final Map<String, dynamic> data =
          jsonDecode(jsonString) as Map<String, dynamic>;
      final workspace = TenantWorkspace.fromJson(data);
      if (workspace.contexts.isEmpty) {
        return TenantWorkspace.defaultWorkspace(
          profile: fallbackProfile,
          plan: fallbackPlan,
        );
      }
      return workspace;
    } catch (_) {
      return TenantWorkspace.defaultWorkspace(
        profile: fallbackProfile,
        plan: fallbackPlan,
      );
    }
  }

  Future<void> saveWorkspace(TenantWorkspace workspace) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(workspace.toJson());
    await prefs.setString(_storageKey, jsonString);
  }
}
