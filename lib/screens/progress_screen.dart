import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool isLoading = true;

  List<dynamic> exerciseLogs = [];
  List<dynamic> assignedExercises = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final userId = user.id;

    final logs = await Supabase.instance.client
        .from('exercise_logs')
        .select()
        .eq('patient_id', userId)
        .order('created_at', ascending: false);

    final assigned = await Supabase.instance.client
        .from('assigned_exercises')
        .select()
        .eq('patient_id', userId)
        .order('created_at', ascending: false);

    setState(() {
      exerciseLogs = logs;
      assignedExercises = assigned;
      isLoading = false;
    });
  }

  int get completedExercises {
    return exerciseLogs.where((log) => log['status'] == 'COMPLETED').length;
  }

  int get assignedCount {
    return assignedExercises.length;
  }

  double get completionPercent {
    if (assignedCount == 0) return 0;
    final percent = completedExercises / assignedCount;
    if (percent > 1) return 1;
    return percent;
  }

  int get completionPercentNumber {
    return (completionPercent * 100).round();
  }

  int get completedThisWeek {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return exerciseLogs.where((log) {
      if (log['status'] != 'COMPLETED') return false;

      final dateText = log['created_at'];
      if (dateText == null) return false;

      final date = DateTime.tryParse(dateText.toString());
      if (date == null) return false;

      return date.isAfter(sevenDaysAgo);
    }).length;
  }

  String get lastSessionText {
    if (exerciseLogs.isEmpty) return 'Sin sesiones';

    final dateText = exerciseLogs.first['created_at'];
    if (dateText == null) return 'Sin fecha';

    final date = DateTime.tryParse(dateText.toString());
    if (date == null) return 'Sin fecha';

    return '${date.day}/${date.month}/${date.year}';
  }

  String get motivationalMessage {
    if (assignedCount == 0) {
      return 'Cuando tu médico te asigne ejercicios, podrás ver aquí tu avance.';
    }

    if (completionPercentNumber >= 80) {
      return 'Excelente constancia. Tu avance va muy bien.';
    }

    if (completionPercentNumber >= 50) {
      return 'Vas a la mitad o más. Sigue así, cada sesión cuenta.';
    }

    if (completedExercises > 0) {
      return 'Ya empezaste. Lo importante es mantener el ritmo poco a poco.';
    }

    return 'Aún no has registrado ejercicios realizados. Puedes empezar hoy.';
  }

  String readableStatus(String? status) {
    switch (status) {
      case 'COMPLETED':
        return 'Realizado';
      case 'PENDING':
        return 'Pendiente';
      case 'SKIPPED':
        return 'No realizado';
      default:
        return 'Registrado';
    }
  }

  String readableDate(dynamic dateText) {
    if (dateText == null) return '';

    final date = DateTime.tryParse(dateText.toString());
    if (date == null) return '';

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mi progreso'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Mi constancia',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Visualiza tu avance y apego a los ejercicios indicados.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ProgressHeroCard(
                    percent: completionPercent,
                    percentNumber: completionPercentNumber,
                    completed: completedExercises,
                    assigned: assignedCount,
                    message: motivationalMessage,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Esta semana',
                          value: '$completedThisWeek',
                          icon: Icons.calendar_month_outlined,
                          background: AppTheme.softGreen,
                          iconColor: AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Última sesión',
                          value: lastSessionText,
                          icon: Icons.access_time,
                          background: AppTheme.softOrange,
                          iconColor: AppTheme.accent,
                          smallValue: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Historial de ejercicios',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (exerciseLogs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Aún no hay ejercicios registrados.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  else
                    ...exerciseLogs.map((log) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppTheme.softBlue,
                              child: Icon(
                                Icons.directions_walk,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log['exercise_name'] ?? 'Ejercicio',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    readableStatus(log['status']),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    readableDate(log['created_at']),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
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

class _ProgressHeroCard extends StatelessWidget {
  final double percent;
  final int percentNumber;
  final int completed;
  final int assigned;
  final String message;

  const _ProgressHeroCard({
    required this.percent,
    required this.percentNumber,
    required this.completed,
    required this.assigned,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Avance general',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 145,
                width: 145,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 14,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.accent,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$percentNumber%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'completado',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '$completed de $assigned ejercicios realizados',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color background;
  final Color iconColor;
  final bool smallValue;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.background,
    required this.iconColor,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: background,
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: smallValue ? 15 : 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
