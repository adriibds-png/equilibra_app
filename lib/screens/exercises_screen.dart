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
  List<dynamic> exerciseLogs = [];

  final Set<String> completedTodayIds = {};

  @override
  void initState() {
    super.initState();
    loadExercises();
  }

  String exerciseId(dynamic exercise) {
    return exercise['id']?.toString() ?? '';
  }

  String exerciseTitle(dynamic exercise) {
    return exercise['exercise_name'] ??
        exercise['title'] ??
        exercise['name'] ??
        'Ejercicio';
  }

  String exerciseDescription(dynamic exercise) {
    return exercise['instructions'] ?? exercise['description'] ?? '';
  }

  String exerciseDuration(dynamic exercise) {
    return exercise['duration'] ?? '';
  }

  String exerciseFrequency(dynamic exercise) {
    return exercise['frequency'] ?? '';
  }

  String exerciseVideoUrl(dynamic exercise) {
    return exercise['video_url'] ?? '';
  }

  String exerciseThumbnailUrl(dynamic exercise) {
    return exercise['thumbnail_url'] ?? '';
  }

  DateTime? logDate(dynamic log) {
    final rawStartedAt = log['started_at'];
    final rawCreatedAt = log['created_at'];

    if (rawStartedAt != null) {
      final parsed = DateTime.tryParse(rawStartedAt.toString());
      if (parsed != null) return parsed.toLocal();
    }

    if (rawCreatedAt != null) {
      final parsed = DateTime.tryParse(rawCreatedAt.toString());
      if (parsed != null) return parsed.toLocal();
    }

    return null;
  }

  bool isSameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> loadExercises() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final assigned = await Supabase.instance.client
        .from('assigned_exercises')
        .select()
        .eq('patient_id', user.id)
        .order('created_at', ascending: false);

    final logs = await Supabase.instance.client
        .from('exercise_logs')
        .select()
        .eq('patient_id', user.id)
        .order('created_at', ascending: false);

    final now = DateTime.now();
    final Map<String, dynamic> latestLogByExerciseId = {};

    for (final log in logs) {
      final assignedId = log['assigned_exercise_id']?.toString() ?? '';
      if (assignedId.isEmpty) continue;

      final date = logDate(log);
      if (date == null) continue;
      if (!isSameLocalDay(date, now)) continue;

      if (!latestLogByExerciseId.containsKey(assignedId)) {
        latestLogByExerciseId[assignedId] = log;
      }
    }

    final completed = <String>{};

    latestLogByExerciseId.forEach((assignedId, log) {
      final status = log['status']?.toString() ?? '';

      if (status == 'COMPLETED') {
        completed.add(assignedId);
      }
    });

    setState(() {
      assignedExercises = assigned;
      exerciseLogs = logs;
      completedTodayIds
        ..clear()
        ..addAll(completed);
      isLoading = false;
    });
  }

  bool wasCompletedToday(dynamic exercise) {
    final id = exerciseId(exercise);
    if (id.isEmpty) return false;

    return completedTodayIds.contains(id);
  }

  Future<void> completeExercise(dynamic exercise) async {
    if (isSaving) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final id = exerciseId(exercise);
    final title = exerciseTitle(exercise);

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar este ejercicio.')),
      );
      return;
    }

    setState(() {
      isSaving = true;
      completedTodayIds.add(id);
    });

    try {
      await Supabase.instance.client.from('exercise_logs').insert({
        'patient_id': user.id,
        'assigned_exercise_id': id,
        'exercise_name': title,
        'started_at': DateTime.now().toIso8601String(),
        'status': 'COMPLETED',
      });

      await loadExercises();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title marcado como realizado')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        completedTodayIds.remove(id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> uncompleteExercise(dynamic exercise) async {
    if (isSaving) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final id = exerciseId(exercise);
    final title = exerciseTitle(exercise);

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar este ejercicio.')),
      );
      return;
    }

    setState(() {
      isSaving = true;
      completedTodayIds.remove(id);
    });

    try {
      await Supabase.instance.client.from('exercise_logs').insert({
        'patient_id': user.id,
        'assigned_exercise_id': id,
        'exercise_name': title,
        'started_at': DateTime.now().toIso8601String(),
        'status': 'PENDING',
      });

      await loadExercises();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title regresó a pendientes')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        completedTodayIds.add(id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al desmarcar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void openExerciseDetail(dynamic exercise) {
    final title = exerciseTitle(exercise);
    final description = exerciseDescription(exercise);
    final duration = exerciseDuration(exercise);
    final frequency = exerciseFrequency(exercise);
    final videoUrl = exerciseVideoUrl(exercise);
    final thumbnailUrl = exerciseThumbnailUrl(exercise);
    final completed = wasCompletedToday(exercise);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                _VideoPreview(
                  thumbnailUrl: thumbnailUrl,
                  videoUrl: videoUrl,
                  large: true,
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (duration.isNotEmpty)
                      _ExerciseBadge(
                        icon: Icons.timer_outlined,
                        text: duration,
                      ),
                    if (duration.isNotEmpty && frequency.isNotEmpty)
                      const SizedBox(width: 10),
                    if (frequency.isNotEmpty)
                      _ExerciseBadge(
                        icon: Icons.repeat_rounded,
                        text: frequency,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    description.isEmpty
                        ? 'Sin indicaciones registradas.'
                        : description,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            Navigator.pop(context);

                            if (completed) {
                              await uncompleteExercise(exercise);
                            } else {
                              await completeExercise(exercise);
                            }
                          },
                    icon: Icon(completed ? Icons.undo : Icons.task_alt),
                    label: Text(
                      completed
                          ? 'Regresar a pendientes'
                          : 'Marcar como realizado',
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
    final pendingExercises = assignedExercises
        .where((exercise) => !wasCompletedToday(exercise))
        .toList();

    final completedExercises = assignedExercises
        .where((exercise) => wasCompletedToday(exercise))
        .toList();

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
                    'Rutina vestibular',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pendingExercises.isEmpty
                        ? 'No tienes ejercicios pendientes por hoy.'
                        : 'Completa los ejercicios indicados por tu médico.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (assignedExercises.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Tu médico aún no te ha asignado ejercicios.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  else ...[
                    const _SectionLabel(text: 'Pendientes'),
                    const SizedBox(height: 12),
                    if (pendingExercises.isEmpty)
                      const _EmptyMiniCard(
                        text: 'Todos los ejercicios de hoy están realizados.',
                      )
                    else
                      ...pendingExercises.map((exercise) {
                        return _ExerciseChecklistCard(
                          completed: false,
                          title: exerciseTitle(exercise),
                          duration: exerciseDuration(exercise),
                          frequency: exerciseFrequency(exercise),
                          thumbnailUrl: exerciseThumbnailUrl(exercise),
                          videoUrl: exerciseVideoUrl(exercise),
                          onTap: () => openExerciseDetail(exercise),
                          onCheck: () => completeExercise(exercise),
                        );
                      }),
                    const SizedBox(height: 28),
                    const _SectionLabel(text: 'Realizados hoy'),
                    const SizedBox(height: 12),
                    if (completedExercises.isEmpty)
                      const _EmptyMiniCard(
                        text: 'Aún no has marcado ejercicios como realizados.',
                      )
                    else
                      ...completedExercises.map((exercise) {
                        return _ExerciseChecklistCard(
                          completed: true,
                          title: exerciseTitle(exercise),
                          duration: exerciseDuration(exercise),
                          frequency: exerciseFrequency(exercise),
                          thumbnailUrl: exerciseThumbnailUrl(exercise),
                          videoUrl: exerciseVideoUrl(exercise),
                          onTap: () => openExerciseDetail(exercise),
                          onCheck: () => uncompleteExercise(exercise),
                        );
                      }),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ExerciseChecklistCard extends StatelessWidget {
  final bool completed;
  final String title;
  final String duration;
  final String frequency;
  final String thumbnailUrl;
  final String videoUrl;
  final VoidCallback onTap;
  final VoidCallback onCheck;

  const _ExerciseChecklistCard({
    required this.completed,
    required this.title,
    required this.duration,
    required this.frequency,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.onTap,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: completed ? 0.62 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color:
                completed ? AppTheme.success.withOpacity(0.35) : Colors.white,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCheck,
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: completed ? AppTheme.success : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            completed ? AppTheme.success : AppTheme.lightText,
                        width: 2,
                      ),
                    ),
                    child: completed
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 22,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        _VideoPreview(
                          thumbnailUrl: thumbnailUrl,
                          videoUrl: videoUrl,
                          large: false,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: completed
                                      ? AppTheme.textMuted
                                      : AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                frequency.isNotEmpty
                                    ? frequency
                                    : 'Sin frecuencia registrada',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              if (duration.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  duration,
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          completed ? Icons.undo : Icons.chevron_right,
                          color:
                              completed ? AppTheme.success : AppTheme.primary,
                        ),
                      ],
                    ),
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

class _VideoPreview extends StatelessWidget {
  final String thumbnailUrl;
  final String videoUrl;
  final bool large;

  const _VideoPreview({
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.large,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: large ? double.infinity : 78,
      height: large ? 170 : 78,
      decoration: BoxDecoration(
        color: AppTheme.softBlue,
        borderRadius: BorderRadius.circular(18),
        image: thumbnailUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(thumbnailUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (thumbnailUrl.isEmpty)
            Icon(
              Icons.play_circle_fill,
              color: AppTheme.primary.withOpacity(0.8),
              size: large ? 64 : 38,
            ),
          if (thumbnailUrl.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          if (thumbnailUrl.isNotEmpty)
            Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: large ? 64 : 38,
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textDark,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _EmptyMiniCard extends StatelessWidget {
  final String text;

  const _EmptyMiniCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.textMuted),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.softBlue,
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
