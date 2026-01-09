import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/glass_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../data/patients_providers.dart';
import '../models/patient_nav_data.dart';

class PatientsScreen extends ConsumerWidget {
  const PatientsScreen({
    super.key,
    required this.hospitalName,
    required this.unitName,
  });

  final String hospitalName;
  final String unitName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPatients = ref.watch(
      patientsForLocationProvider((
        hospitalName: hospitalName,
        unitName: unitName,
      )),
    );

    return AppScaffold(
      title: 'Patients',
      actions: [
        IconButton(
          onPressed: () async {
            final h = Uri.encodeComponent(hospitalName);
            final u = Uri.encodeComponent(unitName);
            await context.push('/patients/add?hospital=$h&room=$u');
          },
          icon: const Icon(LucideIcons.userPlus, size: 20),
          tooltip: 'Add patient',
        ),
      ],
      body: asyncPatients.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.users,
                    size: 48,
                    color: GlassTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No patients yet',
                    style: TextStyle(color: GlassTheme.textMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = list[i];

              return Container(
                decoration: BoxDecoration(
                  color: GlassTheme.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GlassTheme.glassBorder),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: GlassTheme.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      color: GlassTheme.neonCyan,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    p.name.isNotEmpty ? p.name : '—',
                    style: const TextStyle(
                      color: GlassTheme.textWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'MRN: ${p.mrn}',
                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
                  ),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    color: GlassTheme.textMuted,
                    size: 18,
                  ),
                  onTap: () {
                    context.push(
                      '/patient',
                      extra: PatientNavData(
                        patientName: p.name,
                        mrn: p.mrn,
                        hospitalName: p.hospitalName,
                        unitName: p.unitName,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: GlassTheme.neonCyan),
        ),
        error: (e, st) => Center(
          child: Text('Error: $e', style: TextStyle(color: GlassTheme.error)),
        ),
      ),
    );
  }
}
