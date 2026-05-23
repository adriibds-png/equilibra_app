import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class AssignExerciseScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const AssignExerciseScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<AssignExerciseScreen> createState() => _AssignExerciseScreenState();
}

class _AssignExerciseScreenState extends State<AssignExerciseScreen> {
  bool isLoading = true;

  List<dynamic> exerciseLibrary = [];

  @override
  void initState() {
    super.initState();
    loadExerciseLibrary();
  }

  Future<void> loadExerciseLibrary() async {
    final response = await Supabase.instance.client
        .from('exercise_library')
        .select()
        .order('title');

    setState(() {
      exerciseLibrary = response;
      isLoading = false;
    });
  }

  Future<void> assignExercise(dynamic exercise) async {
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

    await showModalBottomSheet(
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
                  'Individualizar ejercicio',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
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
                  maxLines: 6,
                ),
                const SizedBox(height: 14),
                _InputCard(
                  controller: frequencyController,
                  label: 'Frecuencia',
                  icon: Icons.repeat_rounded,
                ),
                const SizedBox(height: 14),
                _InputCard(
                  controller: durationController,
                  label: 'Duración',
                  icon: Icons.timer_outlined,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Asignar al paciente'),
                    onPressed: () async {
                      await Supabase.instance.client
                          .from('assigned_exercises')
                          .insert({
                        'patient_id': widget.patientId,
                        'exercise_name': titleController.text.trim(),
                        'title': titleController.text.trim(),
                        'instructions': descriptionController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'frequency': frequencyController.text.trim(),
                        'duration': durationController.text.trim(),
                      });

                      if (mounted) {
                        Navigator.pop(context);
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
  }

  Future<void> createNewExercise() async {
    final titleController = TextEditingController();

    final descriptionController = TextEditingController();

    final frequencyController = TextEditingController();

    final durationController = TextEditingController();

    await showModalBottomSheet(
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
                  'Crear ejercicio nuevo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
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
                  maxLines: 6,
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
                    label: const Text('Guardar en biblioteca'),
                    onPressed: () async {
                      await Supabase.instance.client
                          .from('exercise_library')
                          .insert({
                        'title': titleController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'frequency': frequencyController.text.trim(),
                        'duration': durationController.text.trim(),
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        loadExerciseLibrary();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Asignar ejercicio'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createNewExercise,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadExerciseLibrary,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    widget.patientName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecciona un ejercicio de la biblioteca.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (exerciseLibrary.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Text(
                        'No hay ejercicios disponibles.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    )
                  else
                    ...exerciseLibrary.map((exercise) {
                      final title = exercise['title'] ?? '';

                      final description = exercise['description'] ?? '';

                      final frequency = exercise['frequency'] ?? '';

                      final duration = exercise['duration'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
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
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (frequency.toString().isNotEmpty)
                                  _Badge(
                                    icon: Icons.repeat_rounded,
                                    text: frequency,
                                  ),
                                if (duration.toString().isNotEmpty)
                                  _Badge(
                                    icon: Icons.timer_outlined,
                                    text: duration,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton.icon(
                                onPressed: () {
                                  assignExercise(exercise);
                                },
                                icon: const Icon(
                                  Icons.check,
                                ),
                                label: const Text(
                                  'Seleccionar',
                                ),
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
          icon: Icon(
            icon,
            color: AppTheme.primary,
          ),
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Badge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppTheme.softBlue,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
