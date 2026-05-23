import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  bool isLoading = true;
  bool isSaving = false;

  List<dynamic> assignedExercises = [];

  @override
  void initState() {
    super.initState();
    loadExercises();
  }

  Future<void> loadExercises() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('assigned_exercises')
        .select()
        .eq('patient_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      assignedExercises = response;
      isLoading = false;
    });
  }

  Future<void> completeExercise(String title) async {
    setState(() {
      isSaving = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('exercise_logs').insert({
        'patient_id': user.id,
        'exercise_name': title,
        'status': 'COMPLETED',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title registrado como realizado')),
      );

      await loadExercises();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void openExerciseDetail(dynamic exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final title =
            exercise['exercise_name'] ?? exercise['title'] ?? 'Ejercicio';

        final description =
            exercise['instructions'] ?? exercise['description'] ?? '';

        final duration = exercise['duration'] ?? '';
        final frequency = exercise['frequency'] ?? '';
        final videoUrl = exercise['video_url'] ?? '';

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
                const SizedBox(height: 14),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (duration.toString().isNotEmpty)
                      _ExerciseBadge(
                        icon: Icons.timer_outlined,
                        text: duration,
                      ),
                    if (duration.toString().isNotEmpty)
                      const SizedBox(width: 10),
                    if (frequency.toString().isNotEmpty)
                      _ExerciseBadge(
                        icon: Icons.repeat,
                        text: frequency,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await completeExercise(title);
                          },
                    icon: const Icon(Icons.task_alt),
                    label: Text(
                      isSaving ? 'Guardando...' : 'Marcar como realizado',
                    ),
                  ),
                ),
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
        title: const Text('Ejercicios'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadExercises,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Ejercicios asignados',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Realiza únicamente los ejercicios indicados por tu médico.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (assignedExercises.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tu médico aún no te ha asignado ejercicios.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  else
                    ...assignedExercises.map((exercise) {
                      final title =
                          exercise['exercise_name'] ?? exercise['title'] ?? '';

                      final description = exercise['instructions'] ??
                          exercise['description'] ??
                          '';

                      final duration = exercise['duration'] ?? '';
                      final frequency = exercise['frequency'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textMuted,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                if (duration.toString().isNotEmpty)
                                  _ExerciseBadge(
                                    icon: Icons.timer_outlined,
                                    text: duration,
                                  ),
                                if (duration.toString().isNotEmpty)
                                  const SizedBox(width: 10),
                                if (frequency.toString().isNotEmpty)
                                  _ExerciseBadge(
                                    icon: Icons.repeat,
                                    text: frequency,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 54,
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  openExerciseDetail(exercise);
                                },
                                child: const Text('Ver indicaciones'),
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
  }
}

class _ExerciseBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ExerciseBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
