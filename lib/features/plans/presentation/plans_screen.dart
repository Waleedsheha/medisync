import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../patients/models/patient_details_ui_models.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get all patients and extract their plans
    final allPatientsAsync = ref.watch(allPatientPlansProvider);

    return AppScaffold(
      title: 'Plans',
      actions: [
        IconButton(
          onPressed: () => ref.invalidate(allPatientPlansProvider),
          icon: const Icon(LucideIcons.refreshCcw),
          tooltip: 'Refresh',
        ),
      ],
      body: allPatientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.calendarX, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No plans scheduled', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          // Group plans by date
          final groupedPlans = <String, List<_PlanWithPatient>>{};
          for (final plan in plans) {
            final dateKey = DateFormat(
              'yyyy-MM-dd',
            ).format(plan.plan.scheduledAt);
            groupedPlans.putIfAbsent(dateKey, () => []).add(plan);
          }

          final sortedDates = groupedPlans.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, i) {
              final dateKey = sortedDates[i];
              final plansForDate = groupedPlans[dateKey]!;
              final date = DateTime.parse(dateKey);
              final isToday =
                  DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;
              final isTomorrow =
                  DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.now().add(const Duration(days: 1))) ==
                  dateKey;

              String dateLabel;
              if (isToday) {
                dateLabel = 'Today';
              } else if (isTomorrow) {
                dateLabel = 'Tomorrow';
              } else {
                dateLabel = DateFormat('EEEE, MMM d').format(date);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i > 0) const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...plansForDate.map(
                    (planWithPatient) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(
                            LucideIcons.clipboardCheck,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          planWithPatient.plan.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(planWithPatient.patientName),
                        trailing: Text(
                          DateFormat(
                            'HH:mm',
                          ).format(planWithPatient.plan.scheduledAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PlanWithPatient {
  final PlanUi plan;
  final String patientName;
  final String mrn;

  const _PlanWithPatient({
    required this.plan,
    required this.patientName,
    required this.mrn,
  });
}

// Simple provider to aggregate all plans
final allPatientPlansProvider = FutureProvider<List<_PlanWithPatient>>((
  ref,
) async {
  // This is a simplified version - in production you'd query from database
  // For now, return empty list as we don't have a global patient registry
  return [];
});
