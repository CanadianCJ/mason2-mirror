import 'package:flutter/material.dart';

enum DealStage { prospect, discovery, proposal, won, lost }

class Deal {
  Deal({
    required this.id,
    required this.title,
    required this.value,
    this.client,
    this.stage = DealStage.prospect,
  });

  final String id;
  final String title;
  final double value;
  final String? client;
  DealStage stage;
}

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  final List<Deal> _deals = [];

  void _addDeal() async {
    final deal = await showDialog<Deal>(
      context: context,
      builder: (context) => const _EditDealDialog(),
    );

    if (deal != null) {
      setState(() {
        _deals.add(deal);
      });
    }
  }

  void _editDeal(Deal deal) async {
    final updated = await showDialog<Deal>(
      context: context,
      builder: (context) => _EditDealDialog(existing: deal),
    );

    if (updated != null) {
      setState(() {
        final index = _deals.indexWhere((d) => d.id == deal.id);
        if (index != -1) {
          _deals[index] = updated;
        }
      });
    }
  }

  void _deleteDeal(Deal deal) {
    setState(() {
      _deals.removeWhere((d) => d.id == deal.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totals = _computeTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deals & Jobs'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDeal,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _MetricChip(
                  label: 'Open',
                  value:
                      '${totals["openCount"]} • \$${totals["openValue"]?.toStringAsFixed(0) ?? "0"}',
                ),
                const SizedBox(width: 8),
                _MetricChip(
                  label: 'Won',
                  value:
                      '${totals["wonCount"]} • \$${totals["wonValue"]?.toStringAsFixed(0) ?? "0"}',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _deals.isEmpty
                ? const Center(
                    child: Text(
                      'No deals yet.\nUse the + button to add your first opportunity.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _deals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final deal = _deals[index];
                      return Dismissible(
                        key: ValueKey(deal.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteDeal(deal),
                        child: InkWell(
                          onTap: () => _editDeal(deal),
                          child: _DealCard(deal: deal),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Map<String, num> _computeTotals() {
    double openValue = 0;
    double wonValue = 0;
    int openCount = 0;
    int wonCount = 0;

    for (final d in _deals) {
      if (d.stage == DealStage.won) {
        wonValue += d.value;
        wonCount++;
      } else if (d.stage != DealStage.lost) {
        openValue += d.value;
        openCount++;
      }
    }

    return {
      'openValue': openValue,
      'wonValue': wonValue,
      'openCount': openCount,
      'wonCount': wonCount,
    };
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal});

  final Deal deal;

  String _stageLabel(DealStage stage) {
    switch (stage) {
      case DealStage.prospect:
        return 'Prospect';
      case DealStage.discovery:
        return 'Discovery';
      case DealStage.proposal:
        return 'Proposal';
      case DealStage.won:
        return 'Won';
      case DealStage.lost:
        return 'Lost';
    }
  }

  Color _stageColor(BuildContext context, DealStage stage) {
    final scheme = Theme.of(context).colorScheme;
    switch (stage) {
      case DealStage.prospect:
        return scheme.primaryContainer;
      case DealStage.discovery:
        return scheme.secondaryContainer;
      case DealStage.proposal:
        return scheme.tertiaryContainer;
      case DealStage.won:
        return Colors.green.shade200;
      case DealStage.lost:
        return Colors.red.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.title,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (deal.client != null && deal.client!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      deal.client!,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  '\$${deal.value.toStringAsFixed(2)}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Chip(
            label: Text(_stageLabel(deal.stage)),
            backgroundColor: _stageColor(context, deal.stage),
          ),
        ],
      ),
    );
  }
}

class _EditDealDialog extends StatefulWidget {
  const _EditDealDialog({this.existing});

  final Deal? existing;

  @override
  State<_EditDealDialog> createState() => _EditDealDialogState();
}

class _EditDealDialogState extends State<_EditDealDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _clientController;
  late final TextEditingController _valueController;
  late DealStage _stage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _clientController = TextEditingController(text: existing?.client ?? '');
    _valueController =
        TextEditingController(text: existing?.value.toStringAsFixed(2) ?? '');
    _stage = existing?.stage ?? DealStage.prospect;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _clientController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final value = double.tryParse(_valueController.text.trim()) ?? 0;
    final existing = widget.existing;

    final deal = Deal(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      client: _clientController.text.trim().isEmpty
          ? null
          : _clientController.text.trim(),
      value: value,
      stage: _stage,
    );

    Navigator.of(context).pop(deal);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit deal' : 'New deal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _clientController,
              decoration: const InputDecoration(
                labelText: 'Client (optional)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _valueController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Value',
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<DealStage>(
              value: _stage,
              decoration: const InputDecoration(
                labelText: 'Stage',
              ),
              items: const [
                DropdownMenuItem(
                  value: DealStage.prospect,
                  child: Text('Prospect'),
                ),
                DropdownMenuItem(
                  value: DealStage.discovery,
                  child: Text('Discovery'),
                ),
                DropdownMenuItem(
                  value: DealStage.proposal,
                  child: Text('Proposal'),
                ),
                DropdownMenuItem(
                  value: DealStage.won,
                  child: Text('Won'),
                ),
                DropdownMenuItem(
                  value: DealStage.lost,
                  child: Text('Lost'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _stage = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
