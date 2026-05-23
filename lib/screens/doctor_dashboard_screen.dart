import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import 'patient_detail_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  bool isLoading = true;

  List<dynamic> patients = [];
  List<dynamic> exerciseLibrary = [];

  final List<Map<String, String>> questionnaires = const [
    {'code': 'DHI', 'name': 'Dizziness Handicap Inventory'},
    {'code': 'ABC', 'name': 'Activities-specific Balance Confidence Scale'},
    {'code': 'HADS', 'name': 'Hospital Anxiety and Depression Scale'},
    {'code': 'EVA', 'name': 'Escala Visual Analógica'},
    {'code': 'VRBQ', 'name': 'Vestibular Rehabilitation Benefit Questionnaire'},
  ];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final patientsResponse = await Supabase.instance.client
        .from('user_profiles')
        .select()
        .eq('role', 'Paciente')
        .eq('doctor_id', currentUser.id)
        .order('full_name');

    final exercisesResponse = await Supabase.instance.client
        .from('exercise_library')
        .select()
        .order('title');

    setState(() {
      patients = patientsResponse;
      exerciseLibrary = exercisesResponse;
      isLoading = false;
    });
  }

  int get patientCount => patients.length;

  int get diagnosisCount {
    return patients.where((patient) {
      final diagnosis = patient['diagnosis'];
      return diagnosis != null && diagnosis.toString().trim().isNotEmpty;
    }).length;
  }

  void openPatient(dynamic patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailScreen(
          patientId: patient['id'],
          patientName: patient['full_name'] ?? patient['email'] ?? 'Paciente',
          patientEmail: patient['email'] ?? '',
        ),
      ),
    );
  }

  Future<void> editExercise(dynamic exercise) async {
    final titleController = TextEditingController(
      text: exercise['title'] ?? '',
    );

    final descriptionController = TextEditingController(
      text: exercise['description'] ?? '',
    );

    final frequencyController = TextEditingController(
      text: exercise['frequency'] ?? '',
    );

    final durationController = TextEditingController(
      text: exercise['duration'] ?? '',
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Editar ejercicio',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Modifica la información base de este ejercicio. Los cambios aplicarán para futuras asignaciones.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
                _InputCard(
                  controller: titleController,
                  label: 'Nombre del ejercicio',
                  icon: Icons.fitness_center_outlined,
                ),
                const SizedBox(height: 14),
                _InputCard(
                  controller: descriptionController,
                  label: 'Indicaciones',
                  icon: Icons.description_outlined,
                  maxLines: 7,
                ),
                const SizedBox(height: 14),
                _InputCard(
                  controller: frequencyController,
                  label: 'Frecuencia sugerida',
                  icon: Icons.repeat_rounded,
                ),
                const SizedBox(height: 14),
                _InputCard(
                  controller: durationController,
                  label: 'Duración sugerida',
                  icon: Icons.timer_outlined,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar cambios'),
                    onPressed: () async {
                      await Supabase.instance.client
                          .from('exercise_library')
                          .update({
                        'title': titleController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'frequency': frequencyController.text.trim(),
                        'duration': durationController.text.trim(),
                      }).eq('id', exercise['id']);

                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    frequencyController.dispose();
    durationController.dispose();

    if (result == true) {
      await loadDashboard();
    }
  }

  void showExercisesLibrary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _LibrarySheet(
          title: 'Biblioteca de ejercicios',
          subtitle: 'Toca un ejercicio para editarlo.',
          items: exerciseLibrary.map((exercise) {
            return _LibraryItem(
              title: exercise['title'] ?? 'Ejercicio',
              subtitle: exercise['description'] ?? '',
              footer:
                  '${exercise['frequency'] ?? 'Sin frecuencia'} · ${exercise['duration'] ?? 'Sin duración'}',
              icon: Icons.fitness_center_outlined,
              onTap: () {
                Navigator.pop(context);
                editExercise(exercise);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void showQuestionnairesLibrary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _LibrarySheet(
          title: 'Biblioteca de cuestionarios',
          subtitle: 'Instrumentos disponibles para asignar al paciente.',
          items: questionnaires.map((questionnaire) {
            return _LibraryItem(
              title: questionnaire['code'] ?? '',
              subtitle: questionnaire['name'] ?? '',
              footer: 'Asignación controlada por médico',
              icon: Icons.assignment_outlined,
              onTap: () {},
            );
          }).toList(),
        );
      },
    );
  }

  void showPatientsByDiagnosis() {
    final Map<String, int> grouped = {};

    for (final patient in patients) {
      final diagnosis = patient['diagnosis']?.toString().trim();
      final key = diagnosis == null || diagnosis.isEmpty
          ? 'Sin diagnóstico'
          : diagnosis;

      grouped[key] = (grouped[key] ?? 0) + 1;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Pacientes por diagnóstico',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 18),
                if (grouped.isEmpty)
                  const Text(
                    'Aún no hay pacientes asignados.',
                    style: TextStyle(color: AppTheme.textMuted),
                  )
                else
                  ...grouped.entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppTheme.softBlue,
                            child: Icon(
                              Icons.medical_information_outlined,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard clínico'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Resumen general',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rehabilitación vestibular y seguimiento clínico',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Pacientes',
                          value: patientCount.toString(),
                          icon: Icons.people_outline,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          title: 'Diagnósticos',
                          value: diagnosisCount.toString(),
                          icon: Icons.medical_information_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Centro clínico',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ActionCard(
                    title: 'Biblioteca de ejercicios',
                    subtitle:
                        '${exerciseLibrary.length} ejercicios disponibles para asignar',
                    icon: Icons.fitness_center_outlined,
                    onTap: showExercisesLibrary,
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Cuestionarios y escalas',
                    subtitle:
                        '${questionnaires.length} instrumentos disponibles: DHI, ABC, HADS, EVA y VRBQ',
                    icon: Icons.assignment_outlined,
                    onTap: showQuestionnairesLibrary,
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Pacientes por diagnóstico',
                    subtitle: 'Ver tu base organizada por diagnóstico clínico',
                    icon: Icons.folder_copy_outlined,
                    onTap: showPatientsByDiagnosis,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Mis pacientes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (patients.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'No tienes pacientes asignados.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    )
                  else
                    ...patients.map((patient) {
                      final name = patient['full_name'] ??
                          patient['email'] ??
                          'Paciente';

                      final diagnosis =
                          patient['diagnosis'] ?? 'Sin diagnóstico registrado';

                      return GestureDetector(
                        onTap: () => openPatient(patient),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.softBlue,
                                child: Text(
                                  name.toString().isNotEmpty
                                      ? name.toString()[0].toUpperCase()
                                      : 'P',
                                  style: const TextStyle(
                                    color: AppTheme.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      diagnosis,
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppTheme.textMuted,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _InputCard({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppTheme.primary),
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.softBlue,
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _LibrarySheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_LibraryItem> items;

  const _LibrarySheet({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'No hay elementos registrados.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              )
            else
              ...items,
          ],
        ),
      ),
    );
  }
}

class _LibraryItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String footer;
  final IconData icon;
  final VoidCallback onTap;

  const _LibraryItem({
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.softBlue,
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    footer,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_outlined,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
