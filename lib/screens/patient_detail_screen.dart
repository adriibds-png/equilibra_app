import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import 'assign_exercise_screen.dart';
import 'assign_questionnaire_screen.dart';
import 'edit_patient_screen.dart';

enum SymptomViewMode { daily, weekly, monthly }

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String patientEmail;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientEmail,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  bool isLoading = true;

  Map<String, dynamic>? patientProfile;
  List<dynamic> symptomEntries = [];
  List<dynamic> exerciseLogs = [];
  List<dynamic> assignedExercises = [];
  List<dynamic> questionnaireResponses = [];

  SymptomViewMode symptomViewMode = SymptomViewMode.daily;

  @override
  void initState() {
    super.initState();
    loadPatientData();
  }

  Future<void> loadPatientData() async {
    final profile = await Supabase.instance.client
        .from('user_profiles')
        .select()
        .eq('id', widget.patientId)
        .maybeSingle();

    final symptoms = await Supabase.instance.client
        .from('symptom_diary_entries')
        .select()
        .eq('patient_id', widget.patientId)
        .order('created_at', ascending: false);

    final exercises = await Supabase.instance.client
        .from('exercise_logs')
        .select()
        .eq('patient_id', widget.patientId)
        .order('created_at', ascending: false);

    final assigned = await Supabase.instance.client
        .from('assigned_exercises')
        .select()
        .eq('patient_id', widget.patientId)
        .order('created_at', ascending: false);

    final questionnaires = await Supabase.instance.client
        .from('questionnaire_responses')
        .select()
        .eq('patient_id', widget.patientId)
        .order('created_at', ascending: true);

    setState(() {
      patientProfile = profile;
      symptomEntries = symptoms;
      exerciseLogs = exercises;
      assignedExercises = assigned;
      questionnaireResponses = questionnaires;
      isLoading = false;
    });
  }

  String get patientName {
    return patientProfile?['full_name'] ?? widget.patientName;
  }

  String get diagnosis {
    return patientProfile?['diagnosis'] ?? 'Sin diagnóstico registrado';
  }

  String get treatingDoctor {
    return patientProfile?['doctor_name'] ?? 'Médico tratante';
  }

  int get completedExercises {
    return exerciseLogs.where((log) => log['status'] == 'COMPLETED').length;
  }

  int get assignedCount {
    return assignedExercises.length;
  }

  double get adherence {
    if (assignedCount == 0) return 0;
    final value = completedExercises / assignedCount;
    return value > 1 ? 1 : value;
  }

  int get adherencePercent => (adherence * 100).round();

  String readableDate(dynamic dateText) {
    if (dateText == null) return '';

    final date = DateTime.tryParse(dateText.toString());
    if (date == null) return '';

    return '${date.day}/${date.month}/${date.year}';
  }

  Map<String, List<dynamic>> get exercisesByName {
    final Map<String, List<dynamic>> grouped = {};

    for (final log in exerciseLogs) {
      final name =
          log['exercise_name'] ?? log['title'] ?? log['name'] ?? 'Ejercicio';

      grouped.putIfAbsent(name, () => []);
      grouped[name]!.add(log);
    }

    return grouped;
  }

  Map<String, List<dynamic>> get questionnairesByName {
    final Map<String, List<dynamic>> grouped = {};

    for (final response in questionnaireResponses) {
      final name = response['questionnaire_name'] ??
          response['scale_name'] ??
          response['type'] ??
          'Escala';

      grouped.putIfAbsent(name, () => []);
      grouped[name]!.add(response);
    }

    return grouped;
  }

  int questionnaireScore(dynamic response) {
    final value = response['score'] ??
        response['total_score'] ??
        response['result'] ??
        response['total'];

    if (value == null) return 0;
    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }

  List<String> symptomsFromEntry(dynamic entry) {
    final raw = entry['symptoms'];

    if (raw is List) {
      return raw.map((item) => item.toString()).toList();
    }

    return [];
  }

  Future<void> openEditPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPatientScreen(
          patientId: widget.patientId,
          currentName: patientName,
          currentEmail: widget.patientEmail,
          currentDiagnosis: diagnosis,
        ),
      ),
    );

    if (result == true) {
      loadPatientData();
    }
  }

  Future<void> openAssignExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignExerciseScreen(
          patientId: widget.patientId,
          patientName: patientName,
        ),
      ),
    );

    if (result == true) {
      loadPatientData();
    }
  }

  Future<void> openAssignScale() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignQuestionnaireScreen(
          patientId: widget.patientId,
          patientName: patientName,
        ),
      ),
    );

    if (result == true) {
      loadPatientData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Expediente del paciente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: openEditPatient,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadPatientData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _PatientHeader(
                    name: patientName,
                    email: widget.patientEmail,
                    diagnosis: diagnosis,
                    doctor: treatingDoctor,
                    adherencePercent: adherencePercent,
                    adherence: adherence,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: openAssignExercise,
                          icon: const Icon(Icons.fitness_center_outlined),
                          label: const Text('Asignar ejercicio'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: openAssignScale,
                          icon: const Icon(Icons.assignment_outlined),
                          label: const Text('Asignar escala'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle(
                    title: 'Evolución de síntomas',
                    subtitle: 'Visualización temporal de síntomas registrados.',
                  ),
                  const SizedBox(height: 12),
                  _SymptomModeSelector(
                    value: symptomViewMode,
                    onChanged: (value) {
                      setState(() {
                        symptomViewMode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (symptomEntries.isEmpty)
                    const _EmptyCard(
                      text: 'Aún no hay registros de síntomas.',
                    )
                  else
                    Container(
                      height: 280,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: _SymptomBubbleChart(
                        entries: symptomEntries,
                        mode: symptomViewMode,
                      ),
                    ),
                  const SizedBox(height: 18),
                  const _LegendRow(),
                  const SizedBox(height: 32),
                  const _SectionTitle(
                    title: 'Ejercicios indicados',
                    subtitle:
                        'Ejercicios asignados y número de sesiones registradas.',
                  ),
                  const SizedBox(height: 12),
                  if (assignedExercises.isEmpty && exerciseLogs.isEmpty)
                    const _EmptyCard(
                      text: 'Aún no hay ejercicios registrados.',
                    )
                  else
                    ..._buildExerciseCards(),
                  const SizedBox(height: 32),
                  const _SectionTitle(
                    title: 'Evolución de escalas',
                    subtitle:
                        'Puntajes registrados desde la valoración inicial.',
                  ),
                  const SizedBox(height: 12),
                  if (questionnaireResponses.isEmpty)
                    const _EmptyCard(
                      text: 'Aún no hay cuestionarios respondidos.',
                    )
                  else
                    ...questionnairesByName.entries.map((entry) {
                      return _QuestionnaireEvolutionCard(
                        title: entry.key,
                        responses: entry.value,
                        scoreBuilder: questionnaireScore,
                        dateBuilder: readableDate,
                      );
                    }),
                  const SizedBox(height: 32),
                  const _SectionTitle(
                    title: 'Bitácora reciente',
                    subtitle: 'Últimos síntomas reportados por el paciente.',
                  ),
                  const SizedBox(height: 12),
                  if (symptomEntries.isEmpty)
                    const _EmptyCard(
                      text: 'Aún no hay bitácora registrada.',
                    )
                  else
                    ...symptomEntries.take(8).map((entry) {
                      return _SymptomCard(
                        date: readableDate(entry['created_at']),
                        symptoms: symptomsFromEntry(entry),
                        otherText: entry['other_text'] ?? '',
                        notes: entry['notes'] ?? '',
                      );
                    }),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildExerciseCards() {
    final assignedNames = assignedExercises
        .map(
            (e) => e['exercise_name'] ?? e['title'] ?? e['name'] ?? 'Ejercicio')
        .toSet()
        .toList();

    final logNames = exercisesByName.keys.toList();

    final allNames = {
      ...assignedNames,
      ...logNames,
    }.toList();

    return allNames.map((name) {
      final logs = exercisesByName[name] ?? [];

      final completed =
          logs.where((log) => log['status'] == 'COMPLETED').length;

      final assigned = assignedExercises.where((exercise) {
        final exerciseName =
            exercise['exercise_name'] ?? exercise['title'] ?? exercise['name'];

        return exerciseName == name;
      }).toList();

      final frequency = assigned.isNotEmpty
          ? assigned.first['frequency'] ??
              assigned.first['dosage'] ??
              assigned.first['indications'] ??
              'Frecuencia no especificada'
          : 'Sin indicación registrada';

      return _ExerciseTrackingCard(
        name: name.toString(),
        frequency: frequency.toString(),
        completed: completed,
        totalLogs: logs.length,
      );
    }).toList();
  }
}

class SymptomStyle {
  final Color color;
  final int lane;

  const SymptomStyle({
    required this.color,
    required this.lane,
  });
}

SymptomStyle symptomStyle(String symptom) {
  switch (symptom) {
    case 'Vértigo':
      return const SymptomStyle(color: Color(0xFF2F6F8F), lane: 0);
    case 'Mareo':
      return const SymptomStyle(color: Color(0xFFF2A65A), lane: 1);
    case 'Inestabilidad al caminar':
      return const SymptomStyle(color: Color(0xFF4CAF88), lane: 2);
    case 'Cambios en la audición':
      return const SymptomStyle(color: Color(0xFF5D8AA8), lane: 3);
    case 'Zumbidos':
      return const SymptomStyle(color: Color(0xFF9575CD), lane: 4);
    case 'Presión ótica':
      return const SymptomStyle(color: Color(0xFF8D6E63), lane: 5);
    case 'Dolor de cabeza':
      return const SymptomStyle(color: Color(0xFFE57373), lane: 6);
    case 'Otro':
      return const SymptomStyle(color: Color(0xFF78909C), lane: 7);
    default:
      return const SymptomStyle(color: AppTheme.primary, lane: 7);
  }
}

class _PatientHeader extends StatelessWidget {
  final String name;
  final String email;
  final String diagnosis;
  final String doctor;
  final int adherencePercent;
  final double adherence;

  const _PatientHeader({
    required this.name,
    required this.email,
    required this.diagnosis,
    required this.doctor,
    required this.adherencePercent,
    required this.adherence,
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
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 42,
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
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeaderChip(
                  icon: Icons.medical_information_outlined,
                  label: diagnosis,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderChip(
                  icon: Icons.badge_outlined,
                  label: doctor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: adherence,
                      strokeWidth: 9,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.accent,
                      ),
                    ),
                    Text(
                      '$adherencePercent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Text(
                  'Adherencia global según ejercicios realizados.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SymptomModeSelector extends StatelessWidget {
  final SymptomViewMode value;
  final ValueChanged<SymptomViewMode> onChanged;

  const _SymptomModeSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SymptomViewMode>(
      selected: {value},
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
      segments: const [
        ButtonSegment(
          value: SymptomViewMode.daily,
          label: Text('Diario'),
        ),
        ButtonSegment(
          value: SymptomViewMode.weekly,
          label: Text('Semanal'),
        ),
        ButtonSegment(
          value: SymptomViewMode.monthly,
          label: Text('Mensual'),
        ),
      ],
    );
  }
}

class _ExerciseTrackingCard extends StatelessWidget {
  final String name;
  final String frequency;
  final int completed;
  final int totalLogs;

  const _ExerciseTrackingCard({
    required this.name,
    required this.frequency,
    required this.completed,
    required this.totalLogs,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalLogs == 0 ? 0.0 : completed / totalLogs;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.softGreen,
            child: Icon(
              Icons.directions_walk,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  frequency,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: AppTheme.background,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '$completed',
            style: const TextStyle(
              color: AppTheme.success,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionnaireEvolutionCard extends StatelessWidget {
  final String title;
  final List<dynamic> responses;
  final int Function(dynamic response) scoreBuilder;
  final String Function(dynamic dateText) dateBuilder;

  const _QuestionnaireEvolutionCard({
    required this.title,
    required this.responses,
    required this.scoreBuilder,
    required this.dateBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...responses];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
              color: AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: _QuestionnaireLineChart(
              responses: sorted,
              scoreBuilder: scoreBuilder,
            ),
          ),
          const SizedBox(height: 14),
          ...sorted.map((response) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dateBuilder(response['created_at']),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '${scoreBuilder(response)} puntos',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SymptomCard extends StatelessWidget {
  final String date;
  final List<String> symptoms;
  final String otherText;
  final String notes;

  const _SymptomCard({
    required this.date,
    required this.symptoms,
    required this.otherText,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSymptoms = symptoms.where((s) => s.trim().isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          if (visibleSymptoms.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visibleSymptoms.map((symptom) {
                final style = symptomStyle(symptom);

                return _SymptomChip(
                  label: symptom,
                  color: style.color,
                );
              }).toList(),
            ),
          ],
          if (otherText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              otherText,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 13,
              ),
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              notes,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SymptomChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _LegendItem(color: Color(0xFF2F6F8F), label: 'Vértigo'),
        _LegendItem(color: Color(0xFFF2A65A), label: 'Mareo'),
        _LegendItem(color: Color(0xFF4CAF88), label: 'Inestabilidad'),
        _LegendItem(color: Color(0xFF5D8AA8), label: 'Audición'),
        _LegendItem(color: Color(0xFF9575CD), label: 'Zumbidos'),
        _LegendItem(color: Color(0xFF8D6E63), label: 'Presión ótica'),
        _LegendItem(color: Color(0xFFE57373), label: 'Cefalea'),
        _LegendItem(color: Color(0xFF78909C), label: 'Otro'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 5,
          backgroundColor: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({
    required this.text,
  });

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
        style: const TextStyle(
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}

class _SymptomBubbleChart extends StatelessWidget {
  final List<dynamic> entries;
  final SymptomViewMode mode;

  const _SymptomBubbleChart({
    required this.entries,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SymptomBubblePainter(entries: entries, mode: mode),
      child: Container(),
    );
  }
}

class _SymptomBubblePainter extends CustomPainter {
  final List<dynamic> entries;
  final SymptomViewMode mode;

  _SymptomBubblePainter({
    required this.entries,
    required this.mode,
  });

  List<String> symptomsFromEntry(dynamic entry) {
    final raw = entry['symptoms'];

    if (raw is List) {
      return raw.map((item) => item.toString()).toList();
    }

    return [];
  }

  int bucketForDate(DateTime date) {
    final now = DateTime.now();

    switch (mode) {
      case SymptomViewMode.daily:
        return now.difference(date).inDays;
      case SymptomViewMode.weekly:
        return now.difference(date).inDays ~/ 7;
      case SymptomViewMode.monthly:
        return ((now.year - date.year) * 12) + now.month - date.month;
    }
  }

  int maxBuckets() {
    switch (mode) {
      case SymptomViewMode.daily:
        return 14;
      case SymptomViewMode.weekly:
        return 8;
      case SymptomViewMode.monthly:
        return 6;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );

    canvas.drawLine(
      Offset(34, size.height - 24),
      Offset(size.width, size.height - 24),
      axisPaint,
    );

    canvas.drawLine(
      const Offset(34, 0),
      Offset(34, size.height - 24),
      axisPaint,
    );

    final points = <_SymptomPoint>[];

    for (final entry in entries) {
      final date = DateTime.tryParse(entry['created_at']?.toString() ?? '');
      if (date == null) continue;

      final bucket = bucketForDate(date);
      if (bucket < 0 || bucket >= maxBuckets()) continue;

      final symptoms = symptomsFromEntry(entry);

      for (final symptom in symptoms) {
        final style = symptomStyle(symptom);
        points.add(
          _SymptomPoint(
            bucket: bucket,
            lane: style.lane,
            color: style.color,
          ),
        );
      }
    }

    final totalBuckets = maxBuckets();
    const laneCount = 8;

    for (int i = 0; i < totalBuckets; i++) {
      final x = 42 + ((size.width - 70) / math.max(totalBuckets - 1, 1)) * i;

      canvas.drawCircle(
        Offset(x, size.height - 24),
        2,
        Paint()..color = Colors.grey.shade300,
      );
    }

    for (final point in points) {
      final reversedBucket = totalBuckets - 1 - point.bucket;

      final x = 42 +
          ((size.width - 70) / math.max(totalBuckets - 1, 1)) * reversedBucket;

      final y =
          18 + ((size.height - 56) / math.max(laneCount - 1, 1)) * point.lane;

      canvas.drawCircle(
        Offset(x, y),
        7,
        Paint()..color = point.color.withOpacity(0.82),
      );
    }

    final label = switch (mode) {
      SymptomViewMode.daily => 'últimos 14 días',
      SymptomViewMode.weekly => 'últimas 8 semanas',
      SymptomViewMode.monthly => 'últimos 6 meses',
    };

    labelPaint.text = TextSpan(
      text: label,
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 11,
      ),
    );

    labelPaint.layout();
    labelPaint.paint(
      canvas,
      Offset(size.width - labelPaint.width, size.height - 16),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SymptomPoint {
  final int bucket;
  final int lane;
  final Color color;

  const _SymptomPoint({
    required this.bucket,
    required this.lane,
    required this.color,
  });
}

class _QuestionnaireLineChart extends StatelessWidget {
  final List<dynamic> responses;
  final int Function(dynamic response) scoreBuilder;

  const _QuestionnaireLineChart({
    required this.responses,
    required this.scoreBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _QuestionnaireLinePainter(
        responses: responses,
        scoreBuilder: scoreBuilder,
      ),
      child: Container(),
    );
  }
}

class _QuestionnaireLinePainter extends CustomPainter {
  final List<dynamic> responses;
  final int Function(dynamic response) scoreBuilder;

  _QuestionnaireLinePainter({
    required this.responses,
    required this.scoreBuilder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final valid = responses.toList();

    if (valid.length < 2) return;

    final scores = valid.map(scoreBuilder).toList();

    final maxScore = math.max(scores.reduce(math.max), 1);

    final axisPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(28, size.height - 20),
      Offset(size.width, size.height - 20),
      axisPaint,
    );

    canvas.drawLine(
      const Offset(28, 0),
      Offset(28, size.height - 20),
      axisPaint,
    );

    final path = Path();

    for (int i = 0; i < valid.length; i++) {
      final score = scoreBuilder(valid[i]).toDouble();

      final x = 32 + ((size.width - 52) / math.max(valid.length - 1, 1)) * i;

      final y = (size.height - 24) - ((size.height - 42) * (score / maxScore));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = AppTheme.primary,
      );
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
