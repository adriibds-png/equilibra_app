import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class AssignQuestionnaireScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const AssignQuestionnaireScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<AssignQuestionnaireScreen> createState() =>
      _AssignQuestionnaireScreenState();
}

class _AssignQuestionnaireScreenState extends State<AssignQuestionnaireScreen> {
  bool isSaving = false;

  final List<Map<String, String>> questionnaires = const [
    {
      'code': 'DHI',
      'name': 'Dizziness Handicap Inventory',
    },
    {
      'code': 'ABC',
      'name': 'Activities-specific Balance Confidence Scale',
    },
    {
      'code': 'HADS',
      'name': 'Hospital Anxiety and Depression Scale',
    },
    {
      'code': 'EVA',
      'name': 'Escala Visual Analógica',
    },
    {
      'code': 'VRBQ',
      'name': 'Vestibular Rehabilitation Benefit Questionnaire',
    },
  ];

  String phase = 'Inicial';

  Future<void> assignQuestionnaire(
    Map<String, String> questionnaire,
  ) async {
    setState(() {
      isSaving = true;
    });

    try {
      await Supabase.instance.client.from('assigned_questionnaires').insert({
        'patient_id': widget.patientId,
        'questionnaire_code': questionnaire['code'],
        'questionnaire_name': questionnaire['name'],
        'phase': phase,
        'status': 'PENDING',
      });

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar cuestionario: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Asignar cuestionario'),
      ),
      body: ListView(
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
            'Selecciona el cuestionario que el paciente deberá responder.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: DropdownButtonFormField<String>(
              value: phase,
              decoration: const InputDecoration(
                labelText: 'Momento de evaluación',
                border: InputBorder.none,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Inicial',
                  child: Text('Inicial'),
                ),
                DropdownMenuItem(
                  value: '5 semanas',
                  child: Text('5 semanas'),
                ),
                DropdownMenuItem(
                  value: '10 semanas',
                  child: Text('10 semanas'),
                ),
                DropdownMenuItem(
                  value: '3 meses',
                  child: Text('3 meses'),
                ),
                DropdownMenuItem(
                  value: 'Seguimiento',
                  child: Text('Seguimiento'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  phase = value;
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          ...questionnaires.map((questionnaire) {
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
                    questionnaire['code'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    questionnaire['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () {
                              assignQuestionnaire(questionnaire);
                            },
                      icon: const Icon(Icons.assignment_outlined),
                      label: Text(
                        isSaving ? 'Asignando...' : 'Asignar',
                      ),
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
