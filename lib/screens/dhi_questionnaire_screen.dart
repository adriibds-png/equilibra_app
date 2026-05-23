import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class DhiQuestionnaireScreen extends StatefulWidget {
  final dynamic questionnaire;

  const DhiQuestionnaireScreen({
    super.key,
    required this.questionnaire,
  });

  @override
  State<DhiQuestionnaireScreen> createState() => _DhiQuestionnaireScreenState();
}

class _DhiQuestionnaireScreenState extends State<DhiQuestionnaireScreen> {
  final FocusNode focusNode = FocusNode();

  int currentQuestionIndex = 0;
  bool isSubmitting = false;

  final List<Map<String, dynamic>> questions = [
    {
      'question': '¿Mirar hacia arriba aumenta su problema?',
      'domain': 'Física'
    },
    {
      'question': '¿Por su problema se siente frustrado/a?',
      'domain': 'Emocional'
    },
    {
      'question':
          '¿Por su problema restringe sus viajes de trabajo o recreación?',
      'domain': 'Funcional'
    },
    {
      'question':
          '¿Caminar por el pasillo de un supermercado aumenta su problema?',
      'domain': 'Física'
    },
    {
      'question':
          '¿Por su problema tiene dificultad para acostarse o levantarse de la cama?',
      'domain': 'Funcional'
    },
    {
      'question':
          '¿Su problema restringe de forma importante su participación en actividades sociales?',
      'domain': 'Funcional'
    },
    {
      'question': '¿Por su problema tiene dificultad para leer?',
      'domain': 'Funcional'
    },
    {
      'question':
          '¿Realizar actividades más exigentes, como deportes, bailar o tareas domésticas, aumenta su problema?',
      'domain': 'Física'
    },
    {
      'question': '¿Por su problema tiene miedo de salir solo/a de casa?',
      'domain': 'Emocional'
    },
    {
      'question':
          '¿Por su problema se siente avergonzado/a frente a otras personas?',
      'domain': 'Emocional'
    },
    {
      'question': '¿Los movimientos rápidos de la cabeza aumentan su problema?',
      'domain': 'Física'
    },
    {'question': '¿Por su problema evita las alturas?', 'domain': 'Funcional'},
    {
      'question': '¿Darse vuelta en la cama aumenta su problema?',
      'domain': 'Física'
    },
    {
      'question':
          '¿Por su problema le resulta difícil hacer trabajos domésticos o de jardinería?',
      'domain': 'Funcional'
    },
    {
      'question':
          '¿Por su problema teme que otras personas piensen que está intoxicado/a?',
      'domain': 'Emocional'
    },
    {
      'question': '¿Por su problema le resulta difícil caminar solo/a?',
      'domain': 'Funcional'
    },
    {
      'question': '¿Caminar sobre una banqueta aumenta su problema?',
      'domain': 'Física'
    },
    {
      'question': '¿Por su problema le resulta difícil concentrarse?',
      'domain': 'Emocional'
    },
    {
      'question':
          '¿Por su problema le resulta difícil caminar dentro de su casa en la oscuridad?',
      'domain': 'Funcional'
    },
    {
      'question': '¿Por su problema tiene miedo de quedarse solo/a en casa?',
      'domain': 'Emocional'
    },
    {
      'question': '¿Por su problema se siente limitado/a?',
      'domain': 'Emocional'
    },
    {
      'question':
          '¿Su problema ha generado tensión en sus relaciones con familiares o amigos?',
      'domain': 'Emocional'
    },
    {
      'question': '¿Por su problema se siente deprimido/a?',
      'domain': 'Emocional'
    },
    {
      'question':
          '¿Su problema interfiere con su trabajo o responsabilidades familiares?',
      'domain': 'Funcional'
    },
    {
      'question': '¿Inclinarse hacia adelante aumenta su problema?',
      'domain': 'Física'
    },
  ];

  final Map<int, int> answers = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  int get totalScore => answers.values.fold(0, (sum, value) => sum + value);

  int scoreByDomain(String domain) {
    int total = 0;

    for (int i = 0; i < questions.length; i++) {
      if (questions[i]['domain'] == domain) {
        total += answers[i] ?? 0;
      }
    }

    return total;
  }

  int get physicalScore => scoreByDomain('Física');
  int get emotionalScore => scoreByDomain('Emocional');
  int get functionalScore => scoreByDomain('Funcional');

  String get interpretation {
    if (totalScore <= 30) return 'Discapacidad leve';
    if (totalScore <= 60) return 'Discapacidad moderada';
    return 'Discapacidad severa';
  }

  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;
  bool get isFirstQuestion => currentQuestionIndex == 0;

  void selectAnswer(int value) {
    setState(() {
      answers[currentQuestionIndex] = value;
    });

    focusNode.requestFocus();

    if (!isLastQuestion) {
      Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;

        setState(() {
          currentQuestionIndex++;
        });

        focusNode.requestFocus();
      });
    }
  }

  void goNext() {
    if (answers[currentQuestionIndex] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una respuesta.')),
      );
      focusNode.requestFocus();
      return;
    }

    if (isLastQuestion) {
      submitQuestionnaire();
      return;
    }

    setState(() {
      currentQuestionIndex++;
    });

    focusNode.requestFocus();
  }

  void goBack() {
    if (!isFirstQuestion) {
      setState(() {
        currentQuestionIndex--;
      });

      focusNode.requestFocus();
    }
  }

  void handleKeyboard(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      selectAnswer(4);
      return;
    }

    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      selectAnswer(2);
      return;
    }

    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      selectAnswer(0);
      return;
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      goBack();
      return;
    }

    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      goNext();
      return;
    }
  }

  Future<void> submitQuestionnaire() async {
    if (isSubmitting) return;

    if (answers.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Responde todas las preguntas.')),
      );

      focusNode.requestFocus();
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('questionnaire_responses').insert({
        'patient_id': userId,
        'assigned_questionnaire_id': widget.questionnaire['id'],
        'questionnaire_code': widget.questionnaire['questionnaire_code'],
        'questionnaire_name': widget.questionnaire['questionnaire_name'],
        'phase': widget.questionnaire['phase'],
        'total_score': totalScore,
        'physical_score': physicalScore,
        'emotional_score': emotionalScore,
        'functional_score': functionalScore,
        'interpretation': interpretation,
        'answers': answers.map((key, value) => MapEntry(key.toString(), value)),
      });

      await Supabase.instance.client
          .from('assigned_questionnaires')
          .update({'status': 'COMPLETED'}).eq('id', widget.questionnaire['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuestionario enviado correctamente.')),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $error')),
      );

      focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestionIndex]['question'];
    final selectedAnswer = answers[currentQuestionIndex];
    final progress = currentQuestionIndex + 1;

    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: handleKeyboard,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => focusNode.requestFocus(),
        child: Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('DHI'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Dizziness Handicap Inventory',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pregunta $progress de ${questions.length}',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress / questions.length,
                color: AppTheme.primary,
                backgroundColor: AppTheme.softBlue,
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.softBlue,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Cuando lea “su problema”, se refiere a síntomas de mareo, vértigo o inestabilidad al caminar.',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AnswerButton(
                      label: '1. Sí',
                      value: 4,
                      selectedValue: selectedAnswer,
                      onTap: selectAnswer,
                    ),
                    const SizedBox(height: 12),
                    _AnswerButton(
                      label: '2. A veces',
                      value: 2,
                      selectedValue: selectedAnswer,
                      onTap: selectAnswer,
                    ),
                    const SizedBox(height: 12),
                    _AnswerButton(
                      label: '3. No',
                      value: 0,
                      selectedValue: selectedAnswer,
                      onTap: selectAnswer,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isFirstQuestion ? null : goBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Anterior'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isSubmitting ? null : goNext,
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(isLastQuestion
                              ? Icons.check
                              : Icons.arrow_forward),
                      label: Text(
                        isSubmitting
                            ? 'Enviando...'
                            : isLastQuestion
                                ? 'Enviar'
                                : 'Siguiente',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final int value;
  final int? selectedValue;
  final void Function(int value) onTap;

  const _AnswerButton({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedValue == value;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () => onTap(value),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? AppTheme.softBlue : Colors.white,
          side: BorderSide(
            color: selected ? AppTheme.primary : AppTheme.lightText,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primary : AppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
