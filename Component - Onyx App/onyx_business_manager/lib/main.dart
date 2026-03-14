import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'founder/business_context_bridge.dart';
import 'founder/tool_runtime_bridge.dart';

part 'founder/tenant_business_context.dart';
part 'founder/tenant_business_plan_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OnyxApp());
}

class OnyxApp extends StatelessWidget {
  const OnyxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onyx Business Manager · Founder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF111827),
        ),
        useMaterial3: true,
      ),
      home: const OnyxHomePage(),
    );
  }
}

class OnyxHomePage extends StatefulWidget {
  const OnyxHomePage({super.key});

  @override
  State<OnyxHomePage> createState() => _OnyxHomePageState();
}

class _OnyxHomePageState extends State<OnyxHomePage>
    with SingleTickerProviderStateMixin {
  final InvoiceStorage _invoiceStorage = InvoiceStorage();
  final TaskStorage _taskStorage = TaskStorage();
  final ClientStorage _clientStorage = ClientStorage();
  final BusinessProfileStorage _businessProfileStorage =
      BusinessProfileStorage();
  final PlanStateStorage _planStateStorage = PlanStateStorage();
  final TenantWorkspaceStorage _tenantWorkspaceStorage =
      TenantWorkspaceStorage();
  final BusinessContextBridge _businessContextBridge =
      createBusinessContextBridge();

  late TabController _tabController;

  List<Invoice> _invoices = <Invoice>[];
  List<Task> _tasks = <Task>[];
  List<Client> _clients = <Client>[];
  TenantWorkspace _tenantWorkspace = TenantWorkspace.defaultWorkspace();

  bool _loading = true;
  String _searchQuery = '';
  String _businessContextSyncMessage = 'Business context not synced yet.';
  String _businessContextSyncedAtUtc = '';
  bool _businessContextSyncOk = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final invoices = await _invoiceStorage.loadInvoices();
      final tasks = await _taskStorage.loadTasks();
      final clients = await _clientStorage.loadClients();
      final legacyProfile = await _businessProfileStorage.loadProfile();
      final legacyPlan = await _planStateStorage.loadPlan();
      final localWorkspace = await _tenantWorkspaceStorage.loadWorkspace(
        fallbackProfile: legacyProfile,
        fallbackPlan: legacyPlan,
      );
      final remoteWorkspaceJson = await _businessContextBridge.fetchWorkspace();
      final remoteWorkspace = remoteWorkspaceJson == null
          ? null
          : TenantWorkspace.fromJson(remoteWorkspaceJson);
      final hasRemoteWorkspace =
          remoteWorkspace != null && remoteWorkspace.contexts.isNotEmpty;
      final useRemote = hasRemoteWorkspace &&
          _isWorkspaceNewer(remoteWorkspace, localWorkspace);
      final workspace = useRemote ? remoteWorkspace : localWorkspace;
      if (useRemote) {
        await _tenantWorkspaceStorage.saveWorkspace(workspace);
      }

      setState(() {
        _invoices = invoices;
        _tasks = tasks;
        _clients = clients;
        _tenantWorkspace = workspace;
        _businessContextSyncOk = hasRemoteWorkspace;
        _businessContextSyncMessage = hasRemoteWorkspace
            ? 'Business context loaded from local control state.'
            : 'Business context loaded locally.';
        _businessContextSyncedAtUtc = workspace.lastUpdatedAtUtc;
        _loading = false;
      });
    } catch (_) {
      final fallbackWorkspace = TenantWorkspace.defaultWorkspace();
      setState(() {
        _invoices = <Invoice>[];
        _tasks = <Task>[];
        _clients = <Client>[];
        _tenantWorkspace = fallbackWorkspace;
        _businessContextSyncOk = false;
        _businessContextSyncMessage =
            'Business context unavailable. Using local defaults.';
        _businessContextSyncedAtUtc = fallbackWorkspace.lastUpdatedAtUtc;
        _loading = false;
      });
    }
  }

  Future<void> _saveInvoices() async {
    await _invoiceStorage.saveInvoices(_invoices);
  }

  Future<void> _saveTasks() async {
    await _taskStorage.saveTasks(_tasks);
  }

  Future<void> _saveClients() async {
    await _clientStorage.saveClients(_clients);
  }

  Future<void> _saveBusinessProfile() async {
    await _businessProfileStorage
        .saveProfile(_tenantWorkspace.activeContext.profile);
  }

  Future<void> _savePlanState() async {
    await _planStateStorage.savePlan(_tenantWorkspace.activeContext.plan);
  }

  bool _isWorkspaceNewer(TenantWorkspace candidate, TenantWorkspace baseline) {
    final candidateTime =
        DateTime.tryParse(candidate.lastUpdatedAtUtc)?.toUtc();
    final baselineTime = DateTime.tryParse(baseline.lastUpdatedAtUtc)?.toUtc();
    if (candidateTime == null) {
      return false;
    }
    if (baselineTime == null) {
      return true;
    }
    return candidateTime.isAfter(baselineTime);
  }

  Future<void> _saveTenantWorkspace({
    required String localMessage,
  }) async {
    await _tenantWorkspaceStorage.saveWorkspace(_tenantWorkspace);
    await _saveBusinessProfile();
    await _savePlanState();

    final syncStatus =
        await _businessContextBridge.saveWorkspace(_tenantWorkspace.toJson());
    if (!mounted) return;
    setState(() {
      _businessContextSyncOk = syncStatus.ok;
      _businessContextSyncMessage = syncStatus.ok
          ? syncStatus.message
          : '$localMessage ${syncStatus.message}'.trim();
      _businessContextSyncedAtUtc = syncStatus.syncedAtUtc.isNotEmpty
          ? syncStatus.syncedAtUtc
          : _tenantWorkspace.lastUpdatedAtUtc;
    });
  }

  String get _nextInvoiceNumber {
    if (_invoices.isEmpty) return 'INV-001';
    final numbers = _invoices
        .map((i) => i.number)
        .where((n) => n.startsWith('INV-'))
        .toList();
    if (numbers.isEmpty) return 'INV-001';
    numbers.sort();
    final last = numbers.last;
    final parts = last.split('-');
    if (parts.length != 2) return 'INV-001';
    final n = int.tryParse(parts[1]) ?? 0;
    final next = n + 1;
    return 'INV-${next.toString().padLeft(3, '0')}';
  }

  List<Invoice> get _filteredInvoices {
    final query = _searchQuery.trim().toLowerCase();
    final list = List<Invoice>.from(_invoices);
    list.sort((a, b) => b.issueDate.compareTo(a.issueDate));

    if (query.isEmpty) return list;

    return list.where((invoice) {
      final client = invoice.clientName.toLowerCase();
      final number = invoice.number.toLowerCase();
      return client.contains(query) || number.contains(query);
    }).toList();
  }

  _InvoiceSummary get _summary {
    final totalCount = _invoices.length;
    final paid =
        _invoices.where((i) => i.status == InvoiceStatus.paid).toList();
    final open =
        _invoices.where((i) => i.status != InvoiceStatus.paid).toList();

    final totalOpen = open.fold<double>(0.0, (sum, i) => sum + i.totalAmount);
    final totalPaid = paid.fold<double>(0.0, (sum, i) => sum + i.totalAmount);

    final symbol = _invoices.isNotEmpty ? _invoices.first.currencySymbol : '\$';

    return _InvoiceSummary(
      totalInvoices: totalCount,
      openInvoices: open.length,
      paidInvoices: paid.length,
      openAmount: totalOpen,
      paidAmount: totalPaid,
      currencySymbol: symbol,
    );
  }

  List<Task> get _sortedTasks {
    final list = List<Task>.from(_tasks);
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  List<Client> get _sortedClients {
    final list = List<Client>.from(_clients);
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  // ----------------- Invoice actions -----------------

  Future<void> _createInvoice() async {
    final result = await Navigator.of(context).push<Invoice>(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorPage(
          existing: null,
          nextNumber: _nextInvoiceNumber,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _invoices.add(result);
    });
    await _saveInvoices();
  }

  Future<void> _editInvoice(Invoice invoice) async {
    final result = await Navigator.of(context).push<Invoice>(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorPage(
          existing: invoice,
          nextNumber: invoice.number,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      final idx = _invoices.indexWhere((i) => i.id == invoice.id);
      if (idx != -1) {
        _invoices[idx] = result;
      }
    });
    await _saveInvoices();
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    setState(() {
      _invoices.removeWhere((i) => i.id == invoice.id);
    });
    await _saveInvoices();
  }

  Future<void> _markSent(Invoice invoice) async {
    setState(() {
      final idx = _invoices.indexWhere((i) => i.id == invoice.id);
      if (idx != -1) {
        _invoices[idx] = _invoices[idx].copyWith(status: InvoiceStatus.sent);
      }
    });
    await _saveInvoices();
  }

  Future<void> _markPaid(Invoice invoice) async {
    setState(() {
      final idx = _invoices.indexWhere((i) => i.id == invoice.id);
      if (idx != -1) {
        _invoices[idx] = _invoices[idx].copyWith(status: InvoiceStatus.paid);
      }
    });
    await _saveInvoices();
  }

  // ----------------- Task actions -----------------

  Future<void> _createTask() async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(
        builder: (_) => const TaskEditorPage(existing: null),
      ),
    );
    if (result == null) return;
    setState(() {
      _tasks.add(result);
    });
    await _saveTasks();
  }

  Future<void> _editTask(Task task) async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(
        builder: (_) => TaskEditorPage(existing: task),
      ),
    );
    if (result == null) return;
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = result;
      }
    });
    await _saveTasks();
  }

  Future<void> _toggleTaskDone(Task task) async {
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        final current = _tasks[idx];
        _tasks[idx] = current.copyWith(
          status: current.status == TaskStatus.done
              ? TaskStatus.open
              : TaskStatus.done,
        );
      }
    });
    await _saveTasks();
  }

  Future<void> _deleteTask(Task task) async {
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    await _saveTasks();
  }

  // ----------------- Client actions -----------------

  Future<void> _createClient() async {
    final result = await Navigator.of(context).push<Client>(
      MaterialPageRoute(
        builder: (_) => const ClientEditorPage(existing: null),
      ),
    );
    if (result == null) return;
    setState(() {
      _clients.add(result);
    });
    await _saveClients();
  }

  Future<void> _editClient(Client client) async {
    final result = await Navigator.of(context).push<Client>(
      MaterialPageRoute(
        builder: (_) => ClientEditorPage(existing: client),
      ),
    );
    if (result == null) return;
    setState(() {
      final idx = _clients.indexWhere((c) => c.id == client.id);
      if (idx != -1) {
        _clients[idx] = result;
      }
    });
    await _saveClients();
  }

  Future<void> _deleteClient(Client client) async {
    setState(() {
      _clients.removeWhere((c) => c.id == client.id);
    });
    await _saveClients();
  }

  // ----------------- Business / Plan actions -----------------

  Future<void> _updateTenantWorkspace(
    TenantWorkspace updated, {
    required String localMessage,
  }) async {
    setState(() {
      _tenantWorkspace = updated;
      _businessContextSyncOk = false;
      _businessContextSyncMessage = localMessage;
      _businessContextSyncedAtUtc = updated.lastUpdatedAtUtc;
    });
    await _saveTenantWorkspace(localMessage: localMessage);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final invoices = _filteredInvoices;
    final summary = _summary;
    final tasks = _sortedTasks;
    final clients = _sortedClients;

    final totalClients = clients.length;
    final totalTasks = tasks.length;
    final openTasks = tasks.where((t) => t.status == TaskStatus.open).length;
    final doneTasks = tasks.where((t) => t.status == TaskStatus.done).length;
    final overdueTasks = tasks.where((t) => t.isOverdue).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onyx · Founder'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_outlined),
              text: 'Dashboard',
            ),
            Tab(
              icon: Icon(Icons.receipt_long),
              text: 'Invoices',
            ),
            Tab(
              icon: Icon(Icons.people_alt_outlined),
              text: 'Clients',
            ),
            Tab(
              icon: Icon(Icons.checklist_outlined),
              text: 'Tasks',
            ),
            Tab(
              icon: Icon(Icons.business_center_outlined),
              text: 'Business & Plan',
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _createInvoice,
              icon: const Icon(Icons.add),
              label: const Text('New invoice'),
            )
          : _tabController.index == 2
              ? FloatingActionButton.extended(
                  onPressed: _createClient,
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('New client'),
                )
              : _tabController.index == 3
                  ? FloatingActionButton.extended(
                      onPressed: _createTask,
                      icon: const Icon(Icons.add_task),
                      label: const Text('New task'),
                    )
                  : null,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _DashboardTab(
                    summary: summary,
                    totalClients: totalClients,
                    totalTasks: totalTasks,
                    openTasks: openTasks,
                    overdueTasks: overdueTasks,
                    doneTasks: doneTasks,
                  ),
                  _InvoicesTab(
                    theme: theme,
                    scheme: scheme,
                    invoices: invoices,
                    summary: summary,
                    searchQuery: _searchQuery,
                    onSearchChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onEditInvoice: _editInvoice,
                    onDeleteInvoice: _deleteInvoice,
                    onMarkSent: _markSent,
                    onMarkPaid: _markPaid,
                  ),
                  _ClientsTab(
                    theme: theme,
                    scheme: scheme,
                    clients: clients,
                    onEditClient: _editClient,
                    onDeleteClient: _deleteClient,
                  ),
                  _TasksTab(
                    theme: theme,
                    scheme: scheme,
                    tasks: tasks,
                    onEditTask: _editTask,
                    onToggleDone: _toggleTaskDone,
                    onDeleteTask: _deleteTask,
                  ),
                  TenantBusinessPlanTab(
                    workspace: _tenantWorkspace,
                    allFeatures: OnyxFeatures.registry,
                    syncMessage: _businessContextSyncMessage,
                    syncedAtUtc: _businessContextSyncedAtUtc,
                    syncOk: _businessContextSyncOk,
                    onWorkspaceChanged: _updateTenantWorkspace,
                  ),
                ],
              ),
      ),
    );
  }
}

// ============================= SUMMARY MODELS/WIDGETS =============================

class _InvoiceSummary {
  final int totalInvoices;
  final int openInvoices;
  final int paidInvoices;
  final double openAmount;
  final double paidAmount;
  final String currencySymbol;

  _InvoiceSummary({
    required this.totalInvoices,
    required this.openInvoices,
    required this.paidInvoices,
    required this.openAmount,
    required this.paidAmount,
    required this.currencySymbol,
  });
}

class _SummaryRow extends StatelessWidget {
  final _InvoiceSummary summary;

  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget buildCard({
      required IconData icon,
      required String label,
      required String primary,
      String? secondary,
    }) {
      return SizedBox(
        width: 260,
        child: Card(
          elevation: 0,
          color: scheme.surfaceVariant.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        primary,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (secondary != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          secondary,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          buildCard(
            icon: Icons.receipt_long,
            label: 'Total invoices',
            primary: '${summary.totalInvoices}',
            secondary: '',
          ),
          buildCard(
            icon: Icons.schedule,
            label: 'Open (unpaid)',
            primary:
                '${summary.currencySymbol}${summary.openAmount.toStringAsFixed(2)}',
            secondary: '${summary.openInvoices} open',
          ),
          buildCard(
            icon: Icons.check_circle,
            label: 'Paid',
            primary:
                '${summary.currencySymbol}${summary.paidAmount.toStringAsFixed(2)}',
            secondary: '${summary.paidInvoices} paid',
          ),
        ],
      ),
    );
  }
}

// ============================= TABS =============================

class _DashboardTab extends StatelessWidget {
  final _InvoiceSummary summary;
  final int totalClients;
  final int totalTasks;
  final int openTasks;
  final int overdueTasks;
  final int doneTasks;

  const _DashboardTab({
    required this.summary,
    required this.totalClients,
    required this.totalTasks,
    required this.openTasks,
    required this.overdueTasks,
    required this.doneTasks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'High-level view of your business for today. '
            'Invoices, clients, and tasks will keep expanding as Onyx grows.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Invoices summary row
          _SummaryRow(summary: summary),

          const SizedBox(height: 24),
          Text(
            'Clients & tasks',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: Card(
                  elevation: 0,
                  color: scheme.surfaceVariant.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people_alt_outlined,
                            size: 18,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clients',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$totalClients',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Active client records in Onyx',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: Card(
                  elevation: 0,
                  color: scheme.surfaceVariant.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.checklist_outlined,
                            size: 18,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tasks',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$openTasks open',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$overdueTasks overdue · $doneTasks done',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text(
            'Later, this dashboard will surface suggestions, alerts, and automation status for you.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicesTab extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme scheme;
  final List<Invoice> invoices;
  final _InvoiceSummary summary;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final void Function(Invoice) onEditInvoice;
  final void Function(Invoice) onDeleteInvoice;
  final void Function(Invoice) onMarkSent;
  final void Function(Invoice) onMarkPaid;

  const _InvoicesTab({
    required this.theme,
    required this.scheme,
    required this.invoices,
    required this.summary,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onEditInvoice,
    required this.onDeleteInvoice,
    required this.onMarkSent,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.science_outlined,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Founder preview: this tab focuses on invoices. '
                    'Use it with a small group while Onyx stays in guided rollout mode.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by client or invoice number',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(height: 8),
        _SummaryRow(summary: summary),
        const SizedBox(height: 8),
        Expanded(
          child: invoices.isEmpty
              ? Center(
                  child: Text(
                    'No invoices yet.\nTap "New invoice" to create your first one.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    final isOverdue = invoice.isOverdue;

                    Color statusColor;
                    String statusLabel;
                    switch (invoice.status) {
                      case InvoiceStatus.draft:
                        statusColor = scheme.onSurfaceVariant;
                        statusLabel = isOverdue ? 'Draft (overdue)' : 'Draft';
                        break;
                      case InvoiceStatus.sent:
                        if (isOverdue) {
                          statusColor = Colors.red;
                          statusLabel = 'Sent (overdue)';
                        } else {
                          statusColor = scheme.primary;
                          statusLabel = 'Sent';
                        }
                        break;
                      case InvoiceStatus.paid:
                        statusColor = Colors.green;
                        statusLabel = 'Paid';
                        break;
                    }

                    return ListTile(
                      onTap: () => onEditInvoice(invoice),
                      title: Text(invoice.clientName),
                      subtitle: Text(
                        '${invoice.number} · Issued ${formatDate(invoice.issueDate)} · Due ${formatDate(invoice.dueDate)}',
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formatCurrency(invoice.totalAmount),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      leading: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEditInvoice(invoice);
                              break;
                            case 'mark_sent':
                              onMarkSent(invoice);
                              break;
                            case 'mark_paid':
                              onMarkPaid(invoice);
                              break;
                            case 'delete':
                              onDeleteInvoice(invoice);
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'mark_sent',
                            child: Text('Mark as sent'),
                          ),
                          PopupMenuItem(
                            value: 'mark_paid',
                            child: Text('Mark as paid'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        child: const Icon(Icons.more_vert),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ClientsTab extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme scheme;
  final List<Client> clients;
  final void Function(Client) onEditClient;
  final void Function(Client) onDeleteClient;

  const _ClientsTab({
    required this.theme,
    required this.scheme,
    required this.clients,
    required this.onEditClient,
    required this.onDeleteClient,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Client list for your business. Later, invoices and tasks will link directly to clients.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: clients.isEmpty
              ? Center(
                  child: Text(
                    'No clients yet.\nUse "New client" to add someone you work with.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: clients.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final title =
                        client.name.isNotEmpty ? client.name : '(No name)';
                    final subtitleParts = <String>[];
                    if (client.businessName != null &&
                        client.businessName!.trim().isNotEmpty) {
                      subtitleParts.add(client.businessName!.trim());
                    }
                    if (client.email != null &&
                        client.email!.trim().isNotEmpty) {
                      subtitleParts.add(client.email!.trim());
                    }
                    final subtitle =
                        subtitleParts.isEmpty ? '' : subtitleParts.join(' · ');

                    return ListTile(
                      onTap: () => onEditClient(client),
                      title: Text(title),
                      subtitle: subtitle.isEmpty ? null : Text(subtitle),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEditClient(client);
                              break;
                            case 'delete':
                              onDeleteClient(client);
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        child: const Icon(Icons.more_vert),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TasksTab extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme scheme;
  final List<Task> tasks;
  final void Function(Task) onEditTask;
  final void Function(Task) onToggleDone;
  final void Function(Task) onDeleteTask;

  const _TasksTab({
    required this.theme,
    required this.scheme,
    required this.tasks,
    required this.onEditTask,
    required this.onToggleDone,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.checklist_outlined,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tasks and follow-ups. Use this to track what needs doing. '
                    'Later, Onyx will suggest and automate some of these.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    'No tasks yet.\nUse "New task" to create your first reminder.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isDone = task.status == TaskStatus.done;
                    final isOverdue = task.isOverdue;

                    String statusLabel;
                    if (isDone) {
                      statusLabel = 'Done';
                    } else if (isOverdue) {
                      statusLabel = 'Overdue';
                    } else {
                      statusLabel = 'Open';
                    }

                    return ListTile(
                      leading: Checkbox(
                        value: isDone,
                        onChanged: (_) => onToggleDone(task),
                      ),
                      title: Text(
                        task.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text(
                        'Due ${formatDate(task.dueDate)} · $statusLabel',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEditTask(task);
                              break;
                            case 'toggle':
                              onToggleDone(task);
                              break;
                            case 'delete':
                              onDeleteTask(task);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text('Mark as ${isDone ? 'open' : 'done'}'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        child: const Icon(Icons.more_vert),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BusinessPlanTab extends StatefulWidget {
  final BusinessProfile profile;
  final PlanState plan;
  final List<OnyxFeatureDefinition> allFeatures;
  final ValueChanged<BusinessProfile> onProfileChanged;
  final ValueChanged<PlanState> onPlanChanged;

  const _BusinessPlanTab({
    required this.profile,
    required this.plan,
    required this.allFeatures,
    required this.onProfileChanged,
    required this.onPlanChanged,
  });

  @override
  State<_BusinessPlanTab> createState() => _BusinessPlanTabState();
}

class _BusinessPlanTabState extends State<_BusinessPlanTab> {
  late TextEditingController _businessNameController;
  late TextEditingController _businessTypeController;
  late TextEditingController _mainGoalController;
  String _size = 'Solo';
  String _currency = 'CAD';
  String _country = 'CA';
  bool _betaOptIn = true;

  @override
  void initState() {
    super.initState();
    _businessNameController =
        TextEditingController(text: widget.profile.businessName);
    _businessTypeController =
        TextEditingController(text: widget.profile.businessType);
    _mainGoalController = TextEditingController(text: widget.profile.mainGoal);
    _size = widget.profile.size;
    _currency = widget.profile.currency;
    _country = widget.profile.countryRegion;
    _betaOptIn = widget.plan.betaOptIn;
  }

  @override
  void didUpdateWidget(covariant _BusinessPlanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _businessNameController.text = widget.profile.businessName;
      _businessTypeController.text = widget.profile.businessType;
      _mainGoalController.text = widget.profile.mainGoal;
      _size = widget.profile.size;
      _currency = widget.profile.currency;
      _country = widget.profile.countryRegion;
    }
    if (oldWidget.plan.betaOptIn != widget.plan.betaOptIn) {
      _betaOptIn = widget.plan.betaOptIn;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _mainGoalController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final now = DateTime.now().toUtc().toIso8601String();
    final updated = BusinessProfile(
      tenantId: widget.profile.tenantId,
      businessName: _businessNameController.text.trim().isEmpty
          ? 'Your business'
          : _businessNameController.text.trim(),
      businessType: _businessTypeController.text.trim().isEmpty
          ? 'General'
          : _businessTypeController.text.trim(),
      size: _size,
      currency: _currency,
      countryRegion: _country,
      mainGoal: _mainGoalController.text.trim().isEmpty
          ? 'Get organized and get paid'
          : _mainGoalController.text.trim(),
      servicesProducts: widget.profile.servicesProducts,
      locations: widget.profile.locations,
      operatingArea: widget.profile.operatingArea,
      currentTools: widget.profile.currentTools,
      goals: widget.profile.goals,
      painPoints: widget.profile.painPoints,
      growthPriorities: widget.profile.growthPriorities,
      riskTolerance: widget.profile.riskTolerance,
      automationTolerance: widget.profile.automationTolerance,
      budgetSensitivity: widget.profile.budgetSensitivity,
      notes: widget.profile.notes,
      uploadReferences: widget.profile.uploadReferences,
      lastUpdatedAtUtc: now,
    );
    widget.onProfileChanged(updated);

    final updatedPlan = widget.plan.copyWith(betaOptIn: _betaOptIn);
    widget.onPlanChanged(updatedPlan);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Business profile saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final activeFeatureIds = <String>{
      ...widget.plan.enabledFeatures,
      ...widget.plan.addonFeatures,
    };

    final activeFeatures = widget.allFeatures
        .where((f) => activeFeatureIds.contains(f.id))
        .toList();
    final otherFeatures = widget.allFeatures
        .where((f) => !activeFeatureIds.contains(f.id))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
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
                'This is what Onyx knows about your business, '
                'and which tools are currently active on your plan.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Business profile card
              Card(
                elevation: 0,
                color: scheme.surfaceVariant.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business profile',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabeledField(
                              label: 'Business type',
                              child: TextField(
                                controller: _businessTypeController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'e.g. Hairdresser, Freelancer',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'Business size',
                              child: DropdownButtonFormField<String>(
                                value: _size,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Solo',
                                    child: Text('Solo'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Small',
                                    child: Text('Small team'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Medium',
                                    child: Text('Medium'),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabeledField(
                              label: 'Currency',
                              child: DropdownButtonFormField<String>(
                                value: _currency,
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabeledField(
                              label: 'Country / region',
                              child: DropdownButtonFormField<String>(
                                value: _country,
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: 'Main goal right now',
                        child: TextField(
                          controller: _mainGoalController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText:
                                'e.g. Get more clients, stay organized, understand finances',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Opt into early feature testing'),
                        subtitle: Text(
                          'If enabled, you can receive new Onyx features first once they are safe.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        value: _betaOptIn,
                        onChanged: (value) {
                          setState(() {
                            _betaOptIn = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _saveProfile,
                          icon: const Icon(Icons.save),
                          label: const Text('Save profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Plan summary + features
              Card(
                elevation: 0,
                color: scheme.surfaceVariant.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your plan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current tier: ${widget.plan.currentTier}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Features marked as "Included" are currently active in your plan. '
                        'This structure is what Onyx will eventually manage automatically '
                        '(tiers, add-ons, and upgrades).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Included features',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (activeFeatures.isEmpty)
                        Text(
                          'No active features. (This should not happen in normal use.)',
                          style: theme.textTheme.bodySmall,
                        )
                      else
                        Column(
                          children: activeFeatures
                              .map(
                                (f) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.check_circle),
                                  title: Text(f.label),
                                  subtitle: Text(
                                    f.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    f.status.toUpperCase(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      if (otherFeatures.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Other defined features (coming later)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: otherFeatures
                              .map(
                                (f) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.hourglass_empty),
                                  title: Text(f.label),
                                  subtitle: Text(
                                    f.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    f.status.toUpperCase(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================= MODELS =============================

enum InvoiceStatus { draft, sent, paid }

class Invoice {
  final String id;
  final String number;
  final String clientName;
  final String? clientEmail;
  final String? notes;
  final DateTime issueDate;
  final DateTime dueDate;
  final double taxRatePercent;
  final InvoiceStatus status;
  final List<InvoiceItem> items;
  final String currencySymbol;

  Invoice({
    required this.id,
    required this.number,
    required this.clientName,
    this.clientEmail,
    this.notes,
    required this.issueDate,
    required this.dueDate,
    required this.taxRatePercent,
    required this.status,
    required this.items,
    this.currencySymbol = '\$',
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);

  double get taxAmount => subtotal * (taxRatePercent / 100.0);

  double get totalAmount => subtotal + taxAmount;

  bool get isOverdue =>
      DateTime.now().isAfter(dueDate) && status != InvoiceStatus.paid;

  Invoice copyWith({
    String? id,
    String? number,
    String? clientName,
    String? clientEmail,
    String? notes,
    DateTime? issueDate,
    DateTime? dueDate,
    double? taxRatePercent,
    InvoiceStatus? status,
    List<InvoiceItem>? items,
    String? currencySymbol,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      notes: notes ?? this.notes,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      taxRatePercent: taxRatePercent ?? this.taxRatePercent,
      status: status ?? this.status,
      items: items ?? this.items,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'notes': notes,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'taxRatePercent': taxRatePercent,
      'status': _statusToString(status),
      'currencySymbol': currencySymbol,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  static Invoice fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      number: json['number'] as String,
      clientName: json['clientName'] as String,
      clientEmail: json['clientEmail'] as String?,
      notes: json['notes'] as String?,
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      taxRatePercent: (json['taxRatePercent'] as num).toDouble(),
      status: _statusFromString(json['status'] as String),
      currencySymbol: json['currencySymbol'] as String? ?? '\$',
      items: (json['items'] as List<dynamic>)
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static String _statusToString(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return 'draft';
      case InvoiceStatus.sent:
        return 'sent';
      case InvoiceStatus.paid:
        return 'paid';
    }
  }

  static InvoiceStatus _statusFromString(String value) {
    switch (value) {
      case 'draft':
        return InvoiceStatus.draft;
      case 'sent':
        return InvoiceStatus.sent;
      case 'paid':
        return InvoiceStatus.paid;
      default:
        return InvoiceStatus.draft;
    }
  }
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double price;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'price': price,
    };
  }

  static InvoiceItem fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
}

// Tasks

enum TaskStatus { open, done }

class Task {
  final String id;
  final String title;
  final DateTime dueDate;
  final TaskStatus status;

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.status,
  });

  bool get isOverdue =>
      status != TaskStatus.done && DateTime.now().isAfter(dueDate);

  Task copyWith({
    String? id,
    String? title,
    DateTime? dueDate,
    TaskStatus? status,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'status:': _taskStatusToString(status),
    };
  }

  static Task fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: _taskStatusFromString(json['status'] as String),
    );
  }

  static String _taskStatusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return 'open';
      case TaskStatus.done:
        return 'done';
    }
  }

  static TaskStatus _taskStatusFromString(String value) {
    switch (value) {
      case 'open':
        return TaskStatus.open;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.open;
    }
  }
}

// Clients

class Client {
  final String id;
  final String name;
  final String? businessName;
  final String? email;
  final String? phone;
  final String? notes;

  Client({
    required this.id,
    required this.name,
    this.businessName,
    this.email,
    this.phone,
    this.notes,
  });

  Client copyWith({
    String? id,
    String? name,
    String? businessName,
    String? email,
    String? phone,
    String? notes,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'businessName': businessName,
      'email': email,
      'phone': phone,
      'notes': notes,
    };
  }

  static Client fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      name: json['name'] as String,
      businessName: json['businessName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

// Business profile

class BusinessProfile {
  final String tenantId;
  final String businessName;
  final String businessType;
  final String size; // Solo / Small / Medium...
  final String currency; // CAD / USD / ...
  final String countryRegion; // CA / US / Other
  final String mainGoal;
  final List<String> servicesProducts;
  final List<String> locations;
  final String operatingArea;
  final List<String> currentTools;
  final List<String> goals;
  final List<String> painPoints;
  final List<String> growthPriorities;
  final String riskTolerance;
  final String automationTolerance;
  final String budgetSensitivity;
  final String notes;
  final List<String> uploadReferences;
  final String lastUpdatedAtUtc;

  BusinessProfile({
    required this.tenantId,
    required this.businessName,
    required this.businessType,
    required this.size,
    required this.currency,
    required this.countryRegion,
    required this.mainGoal,
    required this.servicesProducts,
    required this.locations,
    required this.operatingArea,
    required this.currentTools,
    required this.goals,
    required this.painPoints,
    required this.growthPriorities,
    required this.riskTolerance,
    required this.automationTolerance,
    required this.budgetSensitivity,
    required this.notes,
    required this.uploadReferences,
    required this.lastUpdatedAtUtc,
  });

  static BusinessProfile defaultProfile({
    String tenantId = 'tenant_primary',
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return BusinessProfile(
      tenantId: tenantId,
      businessName: 'Your business',
      businessType: 'General',
      size: 'Solo',
      currency: 'CAD',
      countryRegion: 'CA',
      mainGoal: 'Get organized and get paid',
      servicesProducts: const <String>[],
      locations: const <String>[],
      operatingArea: '',
      currentTools: const <String>[],
      goals: const <String>[],
      painPoints: const <String>[],
      growthPriorities: const <String>[],
      riskTolerance: 'Balanced',
      automationTolerance: 'Assist only',
      budgetSensitivity: 'Balanced',
      notes: '',
      uploadReferences: const <String>[],
      lastUpdatedAtUtc: now,
    );
  }

  BusinessProfile copyWith({
    String? tenantId,
    String? businessName,
    String? businessType,
    String? size,
    String? currency,
    String? countryRegion,
    String? mainGoal,
    List<String>? servicesProducts,
    List<String>? locations,
    String? operatingArea,
    List<String>? currentTools,
    List<String>? goals,
    List<String>? painPoints,
    List<String>? growthPriorities,
    String? riskTolerance,
    String? automationTolerance,
    String? budgetSensitivity,
    String? notes,
    List<String>? uploadReferences,
    String? lastUpdatedAtUtc,
  }) {
    return BusinessProfile(
      tenantId: tenantId ?? this.tenantId,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      size: size ?? this.size,
      currency: currency ?? this.currency,
      countryRegion: countryRegion ?? this.countryRegion,
      mainGoal: mainGoal ?? this.mainGoal,
      servicesProducts: servicesProducts ?? this.servicesProducts,
      locations: locations ?? this.locations,
      operatingArea: operatingArea ?? this.operatingArea,
      currentTools: currentTools ?? this.currentTools,
      goals: goals ?? this.goals,
      painPoints: painPoints ?? this.painPoints,
      growthPriorities: growthPriorities ?? this.growthPriorities,
      riskTolerance: riskTolerance ?? this.riskTolerance,
      automationTolerance: automationTolerance ?? this.automationTolerance,
      budgetSensitivity: budgetSensitivity ?? this.budgetSensitivity,
      notes: notes ?? this.notes,
      uploadReferences: uploadReferences ?? this.uploadReferences,
      lastUpdatedAtUtc: lastUpdatedAtUtc ?? this.lastUpdatedAtUtc,
    );
  }

  static List<String> _stringListFromDynamic(dynamic value) {
    if (value is List<dynamic>) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'businessName': businessName,
      'businessType': businessType,
      'size': size,
      'currency': currency,
      'countryRegion': countryRegion,
      'mainGoal': mainGoal,
      'servicesProducts': servicesProducts,
      'locations': locations,
      'operatingArea': operatingArea,
      'currentTools': currentTools,
      'goals': goals,
      'painPoints': painPoints,
      'growthPriorities': growthPriorities,
      'riskTolerance': riskTolerance,
      'automationTolerance': automationTolerance,
      'budgetSensitivity': budgetSensitivity,
      'notes': notes,
      'uploadReferences': uploadReferences,
      'lastUpdatedAtUtc': lastUpdatedAtUtc,
    };
  }

  static BusinessProfile fromJson(Map<String, dynamic> json) {
    final fallback = BusinessProfile.defaultProfile(
      tenantId: json['tenantId'] as String? ?? 'tenant_primary',
    );
    return BusinessProfile(
      tenantId: json['tenantId'] as String? ?? fallback.tenantId,
      businessName: json['businessName'] as String? ?? fallback.businessName,
      businessType: json['businessType'] as String? ?? fallback.businessType,
      size: json['size'] as String? ?? fallback.size,
      currency: json['currency'] as String? ?? fallback.currency,
      countryRegion: (json['countryRegion'] ?? json['region']) as String? ??
          fallback.countryRegion,
      mainGoal:
          (json['mainGoal'] ?? json['goal']) as String? ?? fallback.mainGoal,
      servicesProducts: _stringListFromDynamic(
        json['servicesProducts'] ?? json['services'] ?? json['products'],
      ),
      locations: _stringListFromDynamic(json['locations']),
      operatingArea: json['operatingArea'] as String? ?? fallback.operatingArea,
      currentTools: _stringListFromDynamic(
        json['currentTools'] ?? json['software'],
      ),
      goals: _stringListFromDynamic(json['goals']),
      painPoints: _stringListFromDynamic(json['painPoints']),
      growthPriorities: _stringListFromDynamic(json['growthPriorities']),
      riskTolerance: json['riskTolerance'] as String? ?? fallback.riskTolerance,
      automationTolerance: json['automationTolerance'] as String? ??
          fallback.automationTolerance,
      budgetSensitivity:
          json['budgetSensitivity'] as String? ?? fallback.budgetSensitivity,
      notes: json['notes'] as String? ?? fallback.notes,
      uploadReferences: _stringListFromDynamic(json['uploadReferences']),
      lastUpdatedAtUtc:
          json['lastUpdatedAtUtc'] as String? ?? fallback.lastUpdatedAtUtc,
    );
  }
}

// Plan state

class PlanState {
  final String currentTier;
  final List<String> enabledFeatures;
  final List<String> addonFeatures;
  final bool betaOptIn;
  final String lastUpdatedAtUtc;

  PlanState({
    required this.currentTier,
    required this.enabledFeatures,
    required this.addonFeatures,
    required this.betaOptIn,
    required this.lastUpdatedAtUtc,
  });

  static PlanState defaultState() {
    final now = DateTime.now().toUtc().toIso8601String();
    return PlanState(
      currentTier: 'Starter',
      enabledFeatures: const ['invoices', 'clients', 'tasks'],
      addonFeatures: const <String>[],
      betaOptIn: true,
      lastUpdatedAtUtc: now,
    );
  }

  PlanState copyWith({
    String? currentTier,
    List<String>? enabledFeatures,
    List<String>? addonFeatures,
    bool? betaOptIn,
    String? lastUpdatedAtUtc,
  }) {
    return PlanState(
      currentTier: currentTier ?? this.currentTier,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      addonFeatures: addonFeatures ?? this.addonFeatures,
      betaOptIn: betaOptIn ?? this.betaOptIn,
      lastUpdatedAtUtc: lastUpdatedAtUtc ?? this.lastUpdatedAtUtc,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentTier': currentTier,
      'enabledFeatures': enabledFeatures,
      'addonFeatures': addonFeatures,
      'betaOptIn': betaOptIn,
      'lastUpdatedAtUtc': lastUpdatedAtUtc,
    };
  }

  static PlanState fromJson(Map<String, dynamic> json) {
    final fallback = PlanState.defaultState();
    return PlanState(
      currentTier: json['currentTier'] as String? ?? fallback.currentTier,
      enabledFeatures: (json['enabledFeatures'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          fallback.enabledFeatures,
      addonFeatures: (json['addonFeatures'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          fallback.addonFeatures,
      betaOptIn: json['betaOptIn'] as bool? ?? fallback.betaOptIn,
      lastUpdatedAtUtc:
          json['lastUpdatedAtUtc'] as String? ?? fallback.lastUpdatedAtUtc,
    );
  }
}

// Feature registry

class OnyxFeatureDefinition {
  final String id;
  final String label;
  final String category;
  final String description;
  final String status; // basic / advanced / expert
  final bool visibleByDefault;
  final List<String> defaultTiers;
  final double? addonPrice; // monthly, future use

  const OnyxFeatureDefinition({
    required this.id,
    required this.label,
    required this.category,
    required this.description,
    required this.status,
    required this.visibleByDefault,
    required this.defaultTiers,
    this.addonPrice,
  });
}

class OnyxFeatures {
  static const List<OnyxFeatureDefinition> registry = [
    OnyxFeatureDefinition(
      id: 'invoices',
      label: 'Invoices',
      category: 'Money',
      description:
          'Create, send, and track invoices with tax, totals, and status (draft, sent, paid).',
      status: 'basic',
      visibleByDefault: true,
      defaultTiers: ['Starter', 'Growth', 'Founder'],
      addonPrice: null,
    ),
    OnyxFeatureDefinition(
      id: 'clients',
      label: 'Clients',
      category: 'Relationships',
      description: 'Keep a simple list of people and businesses you work with.',
      status: 'basic',
      visibleByDefault: true,
      defaultTiers: ['Starter', 'Growth', 'Founder'],
      addonPrice: null,
    ),
    OnyxFeatureDefinition(
      id: 'tasks',
      label: 'Tasks',
      category: 'Operations',
      description:
          'Track what needs doing, with due dates and completion status.',
      status: 'basic',
      visibleByDefault: true,
      defaultTiers: ['Starter', 'Growth', 'Founder'],
      addonPrice: null,
    ),
    OnyxFeatureDefinition(
      id: 'deals',
      label: 'Deals / Jobs (future)',
      category: 'Pipeline',
      description:
          'Simple pipeline of deals or jobs from lead to won/lost. Not active yet in this build.',
      status: 'basic',
      visibleByDefault: false,
      defaultTiers: ['Growth', 'Founder'],
      addonPrice: null,
    ),
  ];
}

// ============================= SMALL UI HELPERS =============================

class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final String currencySymbol;
  final bool isEmphasized;

  const _AmountRow({
    required this.label,
    required this.amount,
    required this.currencySymbol,
    this.isEmphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(width: 16),
        Text(
          '$currencySymbol${amount.toStringAsFixed(2)}',
          style: (isEmphasized
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.bodyMedium)
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

// ============================= STORAGE =============================

class InvoiceStorage {
  static const String _storageKey = 'onyx_invoices_v1';

  Future<List<Invoice>> loadInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return <Invoice>[];
    }
    try {
      final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
      return data
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Invoice>[];
    }
  }

  Future<void> saveInvoices(List<Invoice> invoices) async {
    final prefs = await SharedPreferences.getInstance();
    final data = invoices.map((i) => i.toJson()).toList();
    final jsonString = jsonEncode(data);
    await prefs.setString(_storageKey, jsonString);
  }
}

class TaskStorage {
  static const String _storageKey = 'onyx_tasks_v1';

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return <Task>[];
    }
    try {
      final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
      return data.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return <Task>[];
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final data = tasks.map((t) => t.toJson()).toList();
    final jsonString = jsonEncode(data);
    await prefs.setString(_storageKey, jsonString);
  }
}

class ClientStorage {
  static const String _storageKey = 'onyx_clients_v1';

  Future<List<Client>> loadClients() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return <Client>[];
    }
    try {
      final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
      return data
          .map((e) => Client.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Client>[];
    }
  }

  Future<void> saveClients(List<Client> clients) async {
    final prefs = await SharedPreferences.getInstance();
    final data = clients.map((c) => c.toJson()).toList();
    final jsonString = jsonEncode(data);
    await prefs.setString(_storageKey, jsonString);
  }
}

class BusinessProfileStorage {
  static const String _storageKey = 'onyx_business_profile_v1';

  Future<BusinessProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return BusinessProfile.defaultProfile();
    }
    try {
      final Map<String, dynamic> data =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return BusinessProfile.fromJson(data);
    } catch (_) {
      return BusinessProfile.defaultProfile();
    }
  }

  Future<void> saveProfile(BusinessProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(profile.toJson());
    await prefs.setString(_storageKey, jsonString);
  }
}

class PlanStateStorage {
  static const String _storageKey = 'onyx_plan_state_v1';

  Future<PlanState> loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return PlanState.defaultState();
    }
    try {
      final Map<String, dynamic> data =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return PlanState.fromJson(data);
    } catch (_) {
      return PlanState.defaultState();
    }
  }

  Future<void> savePlan(PlanState plan) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(plan.toJson());
    await prefs.setString(_storageKey, jsonString);
  }
}

// ============================= HELPERS =============================

String formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String formatCurrency(double amount) {
  return '\$${amount.toStringAsFixed(2)}';
}

// ============================= EDITOR SCREENS =============================
class InvoiceEditorPage extends StatefulWidget {
  final Invoice? existing;
  final String nextNumber;

  const InvoiceEditorPage({
    super.key,
    required this.existing,
    required this.nextNumber,
  });

  @override
  State<InvoiceEditorPage> createState() => _InvoiceEditorPageState();
}

class _InvoiceEditorPageState extends State<InvoiceEditorPage> {
  late TextEditingController _clientNameController;
  late TextEditingController _clientEmailController;
  late TextEditingController _notesController;
  late TextEditingController _taxRateController;

  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  String _currencySymbol = '\$';
  InvoiceStatus _status = InvoiceStatus.draft;

  List<_InvoiceItemRowData> _rows = [];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _clientNameController =
        TextEditingController(text: existing?.clientName ?? '');
    _clientEmailController =
        TextEditingController(text: existing?.clientEmail ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _taxRateController = TextEditingController(
      text: (existing?.taxRatePercent ?? 0).toStringAsFixed(1),
    );

    if (existing != null) {
      _issueDate = existing.issueDate;
      _dueDate = existing.dueDate;
      _currencySymbol = existing.currencySymbol;
      _status = existing.status;
      _rows =
          existing.items.map((i) => _InvoiceItemRowData.fromItem(i)).toList();
    } else {
      _rows = [
        _InvoiceItemRowData.empty(),
      ];
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _notesController.dispose();
    _taxRateController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _issueDate = picked;
        if (_dueDate.isBefore(_issueDate)) {
          _dueDate = _issueDate.add(const Duration(days: 14));
        }
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: _issueDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _addRowBelow(int index) {
    setState(() {
      _rows.insert(index + 1, _InvoiceItemRowData.empty());
    });
  }

  void _removeRow(int index) {
    if (_rows.length == 1) return;
    setState(() {
      final row = _rows.removeAt(index);
      row.dispose();
    });
  }

  void _save() {
    final clientName = _clientNameController.text.trim();
    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client name is required.')),
      );
      return;
    }

    final taxRate =
        double.tryParse(_taxRateController.text.trim().replaceAll(',', '.')) ??
            0.0;

    final items = <InvoiceItem>[];
    for (final row in _rows) {
      final desc = row.descriptionController.text.trim();
      final qtyText = row.quantityController.text.trim();
      final priceText = row.priceController.text.trim();

      if (desc.isEmpty && qtyText.isEmpty && priceText.isEmpty) {
        continue;
      }

      final qty = int.tryParse(qtyText) ?? 0;
      final price = double.tryParse(priceText.replaceAll(',', '.')) ?? 0.0;
      if (qty <= 0 && price <= 0) {
        continue;
      }

      items.add(InvoiceItem(
        description: desc.isEmpty ? 'Item' : desc,
        quantity: qty <= 0 ? 1 : qty,
        price: price < 0 ? 0.0 : price,
      ));
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one line item before saving.'),
        ),
      );
      return;
    }

    final id =
        widget.existing?.id ?? 'inv_${DateTime.now().microsecondsSinceEpoch}';
    final invoice = Invoice(
      id: id,
      number: widget.existing?.number ?? widget.nextNumber,
      clientName: clientName,
      clientEmail: _clientEmailController.text.trim().isEmpty
          ? null
          : _clientEmailController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      issueDate: _issueDate,
      dueDate: _dueDate,
      taxRatePercent: taxRate,
      status: _status,
      items: items,
      currencySymbol: _currencySymbol,
    );

    Navigator.of(context).pop(invoice);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isEditing = widget.existing != null;

    double subtotal = 0;
    for (final row in _rows) {
      final qty = int.tryParse(row.quantityController.text.trim()) ?? 0;
      final price = double.tryParse(
              row.priceController.text.trim().replaceAll(',', '.')) ??
          0.0;
      subtotal += (qty * price);
    }
    final taxRate =
        double.tryParse(_taxRateController.text.trim().replaceAll(',', '.')) ??
            0.0;
    final tax = subtotal * (taxRate / 100.0);
    final total = subtotal + tax;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit invoice' : 'New invoice'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Card(
                elevation: 0,
                color: scheme.surfaceVariant.withOpacity(0.6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'Client name',
                              child: TextField(
                                controller: _clientNameController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Who is this invoice for?',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabeledField(
                              label: 'Client email (optional)',
                              child: TextField(
                                controller: _clientEmailController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'For sending the invoice later',
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'Issue date',
                              child: InkWell(
                                onTap: _pickIssueDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(formatDate(_issueDate)),
                                      const Icon(Icons.calendar_month),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabeledField(
                              label: 'Due date',
                              child: InkWell(
                                onTap: _pickDueDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(formatDate(_dueDate)),
                                      const Icon(Icons.calendar_month),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'Tax rate (%)',
                              child: TextField(
                                controller: _taxRateController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'e.g. 13',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabeledField(
                              label: 'Status',
                              child: DropdownButtonFormField<InvoiceStatus>(
                                value: _status,
                                items: const [
                                  DropdownMenuItem(
                                    value: InvoiceStatus.draft,
                                    child: Text('Draft'),
                                  ),
                                  DropdownMenuItem(
                                    value: InvoiceStatus.sent,
                                    child: Text('Sent'),
                                  ),
                                  DropdownMenuItem(
                                    value: InvoiceStatus.paid,
                                    child: Text('Paid'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _status = value;
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
                        label: 'Notes on invoice (optional)',
                        child: TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText:
                                'Any extra info to appear on the invoice.',
                          ),
                          minLines: 2,
                          maxLines: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: scheme.surfaceVariant.withOpacity(0.6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Line items',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _rows.add(_InvoiceItemRowData.empty());
                              });
                            },
                            icon: const Icon(Icons.add),
                            tooltip: 'Add line',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final row = _rows[index];
                          return _InvoiceItemRow(
                            data: row,
                            currencySymbol: _currencySymbol,
                            onAddBelow: () => _addRowBelow(index),
                            onRemove: () => _removeRow(index),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _AmountRow(
                            label: 'Subtotal',
                            amount: subtotal,
                            currencySymbol: _currencySymbol,
                          ),
                          const SizedBox(width: 24),
                          _AmountRow(
                            label: 'Tax',
                            amount: tax,
                            currencySymbol: _currencySymbol,
                          ),
                          const SizedBox(width: 24),
                          _AmountRow(
                            label: 'Total',
                            amount: total,
                            currencySymbol: _currencySymbol,
                            isEmphasized: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save invoice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceItemRowData {
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController priceController;

  _InvoiceItemRowData({
    required this.descriptionController,
    required this.quantityController,
    required this.priceController,
  });

  factory _InvoiceItemRowData.empty() {
    return _InvoiceItemRowData(
      descriptionController: TextEditingController(),
      quantityController: TextEditingController(text: '1'),
      priceController: TextEditingController(),
    );
  }

  factory _InvoiceItemRowData.fromItem(InvoiceItem item) {
    return _InvoiceItemRowData(
      descriptionController: TextEditingController(text: item.description),
      quantityController: TextEditingController(text: item.quantity.toString()),
      priceController:
          TextEditingController(text: item.price.toStringAsFixed(2)),
    );
  }

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}

class _InvoiceItemRow extends StatelessWidget {
  final _InvoiceItemRowData data;
  final String currencySymbol;
  final VoidCallback onAddBelow;
  final VoidCallback onRemove;

  const _InvoiceItemRow({
    required this.data,
    required this.currencySymbol,
    required this.onAddBelow,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: TextField(
            controller: data.descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: data.quantityController,
            decoration: const InputDecoration(
              labelText: 'Qty',
              border: OutlineInputBorder(),
            ),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: data.priceController,
            decoration: InputDecoration(
              labelText: 'Price',
              border: const OutlineInputBorder(),
              prefixText: currencySymbol,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9.,]'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            IconButton(
              onPressed: onAddBelow,
              icon: const Icon(Icons.add),
              tooltip: 'Add line below',
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: 'Remove line',
            ),
          ],
        ),
      ],
    );
  }
}

class TaskEditorPage extends StatefulWidget {
  final Task? existing;

  const TaskEditorPage({super.key, required this.existing});

  @override
  State<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends State<TaskEditorPage> {
  late TextEditingController _titleController;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TaskStatus _status = TaskStatus.open;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    if (existing != null) {
      _dueDate = existing.dueDate;
      _status = existing.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title is required.')),
      );
      return;
    }

    final id =
        widget.existing?.id ?? 'task_${DateTime.now().microsecondsSinceEpoch}';
    final task = Task(
      id: id,
      title: title,
      dueDate: _dueDate,
      status: _status,
    );
    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit task' : 'New task'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            elevation: 0,
            color: scheme.surfaceVariant.withOpacity(0.6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _LabeledField(
                    label: 'Task title',
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'What needs to be done?',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'Due date',
                          child: InkWell(
                            onTap: _pickDueDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(formatDate(_dueDate)),
                                  const Icon(Icons.calendar_month),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LabeledField(
                          label: 'Status',
                          child: DropdownButtonFormField<TaskStatus>(
                            value: _status,
                            items: const [
                              DropdownMenuItem(
                                value: TaskStatus.open,
                                child: Text('Open'),
                              ),
                              DropdownMenuItem(
                                value: TaskStatus.done,
                                child: Text('Done'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _status = value;
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
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save task'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClientEditorPage extends StatefulWidget {
  final Client? existing;

  const ClientEditorPage({super.key, required this.existing});

  @override
  State<ClientEditorPage> createState() => _ClientEditorPageState();
}

class _ClientEditorPageState extends State<ClientEditorPage> {
  late TextEditingController _nameController;
  late TextEditingController _businessNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _businessNameController =
        TextEditingController(text: existing?.businessName ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client name is required.')),
      );
      return;
    }

    final id = widget.existing?.id ??
        'client_${DateTime.now().microsecondsSinceEpoch}';
    final client = Client(
      id: id,
      name: name,
      businessName: _businessNameController.text.trim().isEmpty
          ? null
          : _businessNameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    Navigator.of(context).pop(client);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit client' : 'New client'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            elevation: 0,
            color: scheme.surfaceVariant.withOpacity(0.6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _LabeledField(
                      label: 'Name',
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Client name',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'Business name (optional)',
                      child: TextField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'If they have a company name',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'Email (optional)',
                            child: TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'name@example.com',
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledField(
                            label: 'Phone (optional)',
                            child: TextField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '+1...',
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'Notes (optional)',
                      child: TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              'Anything you want to remember about this client.',
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text('Save client'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
