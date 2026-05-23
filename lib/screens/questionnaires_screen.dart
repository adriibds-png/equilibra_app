import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import 'dhi_questionnaire_screen.dart';

class QuestionnairesScreen extends StatefulWidget {
  const QuestionnairesScreen({super.key});

  @override
  State<QuestionnairesScreen> createState() => _QuestionnairesScreenState();
}

class _QuestionnairesScreenState extends State<QuestionnairesScreen> {
  bool isLoading = true;

  List<dynamic> assignedQuestionnaires = [];

  @override
  void initState() {
    super.initState();
    loadQuestionnaires();
  }

  Future<void> loadQuestionnaires() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final response = await Supabase.instance.client
        .from('assigned_questionnaires')
        .select()
        .eq('patient_id', userId)
        .order('created_at', ascending: false);

    setState(() {
      assignedQuestionnaires = response;
      isLoading = false;
    });
  }

  void openQuestionnaire(dynamic questionnaire) async {
    if (questionnaire['questionnaire_code'] == 'DHI') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DhiQuestionnaireScreen(questionnaire: questionnaire),
        ),
      );

      loadQuestionnaires();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esta escala aún no está programada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Cuestionarios'),
        backgroundColor: AppTheme.background,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Cuestionarios asignados',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa únicamente las escalas indicadas por tu médico.',
                  style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 24),
                if (assignedQuestionnaires.isEmpty)
                  const Text(
                    'No tienes cuestionarios asignados.',
                    style: TextStyle(color: AppTheme.textMuted),
                  )
                else
                  ...assignedQuestionnaires.map((questionnaire) {
                    final bool completed =
                        questionnaire['status'] == 'COMPLETED';

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
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppTheme.softBlue,
                                child: Icon(
                                  Icons.assignment,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      questionnaire['questionnaire_code'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      questionnaire['questionnaire_name'] ?? '',
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
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
                              _Badge(
                                text: questionnaire['phase'] ?? '',
                                icon: Icons.calendar_today_outlined,
                              ),
                              const SizedBox(width: 10),
                              _Badge(
                                text: completed ? 'Completado' : 'Pendiente',
                                icon: completed
                                    ? Icons.check_circle_outline
                                    : Icons.schedule,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 54,
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: completed
                                  ? null
                                  : () {
                                      openQuestionnaire(questionnaire);
                                    },
                              child: Text(
                                completed
                                    ? 'Completado'
                                    : 'Responder cuestionario',
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

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Badge({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
