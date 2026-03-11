import 'package:flutter/material.dart';
import 'package:onyx_business_manager/founder/tasks_screen.dart';
import 'package:onyx_business_manager/founder/deals_screen.dart';

/// "Founder Plan" panel for the Onyx home screen.
class FounderPanel extends StatelessWidget {
  const FounderPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Onyx Founder Plan',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Early access build powered by Mason.\n'
              'Today you get invoicing, tasks/reminders, and a simple deals pipeline. '
              'We\'ll keep auto-upgrading this over time.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeatureChip(
                  icon: Icons.receipt_long,
                  label: 'Invoices',
                  color: colorScheme.primaryContainer,
                ),
                _FeatureChip(
                  icon: Icons.check_circle_outline,
                  label: 'Tasks',
                  color: colorScheme.secondaryContainer,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TasksScreen(),
                      ),
                    );
                  },
                ),
                _FeatureChip(
                  icon: Icons.work_outline,
                  label: 'Deals / Jobs',
                  color: colorScheme.tertiaryContainer,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DealsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'In the background Mason watches errors, performance, and how you use Onyx, '
              'then proposes safe upgrades instead of breaking changes.',
              style: textTheme.bodySmall?.copyWith(
                color: textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(label),
      ],
    );

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: content,
        ),
      ),
    );
  }
}
