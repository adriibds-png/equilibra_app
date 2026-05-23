import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class SymptomDiaryScreen extends StatefulWidget {
  const SymptomDiaryScreen({super.key});

  @override
  State<SymptomDiaryScreen> createState() => _SymptomDiaryScreenState();
}

class _SymptomDiaryScreenState extends State<SymptomDiaryScreen> {
  final List<String> symptoms = [
    'Vértigo',
    'Mareo',
    'Inestabilidad al caminar',
    'Cambios en la audición',
    'Zumbidos',
    'Presión ótica',
    'Dolor de cabeza',
    'Otro',
  ];

  final Set<String> selectedSymptoms = {};
  final TextEditingController otherController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool isSaving = false;
  List<dynamic> entries = [];

  @override
  void initState() {
    super.initState();
    loadEntries();
  }

  @override
  void dispose() {
    otherController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> loadEntries() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('symptom_diary_entries')
        .select()
        .eq('patient_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      entries = response;
    });
  }

  Future<void> saveEntry() async {
    if (selectedSymptoms.isEmpty &&
        otherController.text.trim().isEmpty &&
        notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un síntoma o comentario.'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('symptom_diary_entries').insert({
        'patient_id': user.id,
        'symptoms': selectedSymptoms.toList(),
        'other_text': otherController.text.trim(),
        'notes': notesController.text.trim(),
      });

      selectedSymptoms.clear();
      otherController.clear();
      notesController.clear();

      await loadEntries();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro guardado')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  String readableDate(dynamic dateText) {
    if (dateText == null) return '';

    final date = DateTime.tryParse(dateText.toString());
    if (date == null) return '';

    return '${date.day}/${date.month}/${date.year}';
  }

  Color symptomColor(String symptom) {
    switch (symptom) {
      case 'Vértigo':
        return const Color(0xFF2F6F8F);
      case 'Mareo':
        return const Color(0xFFF2A65A);
      case 'Inestabilidad al caminar':
        return const Color(0xFF4CAF88);
      case 'Cambios en la audición':
        return const Color(0xFF5D8AA8);
      case 'Zumbidos':
        return const Color(0xFF9575CD);
      case 'Presión ótica':
        return const Color(0xFF8D6E63);
      case 'Dolor de cabeza':
        return const Color(0xFFE57373);
      case 'Otro':
        return const Color(0xFF78909C);
      default:
        return AppTheme.primary;
    }
  }

  IconData symptomIcon(String symptom) {
    switch (symptom) {
      case 'Vértigo':
        return Icons.rotate_right_rounded;
      case 'Mareo':
        return Icons.blur_circular_rounded;
      case 'Inestabilidad al caminar':
        return Icons.directions_walk_rounded;
      case 'Cambios en la audición':
        return Icons.hearing_rounded;
      case 'Zumbidos':
        return Icons.graphic_eq_rounded;
      case 'Presión ótica':
        return Icons.radio_button_checked_rounded;
      case 'Dolor de cabeza':
        return Icons.psychology_alt_rounded;
      case 'Otro':
        return Icons.more_horiz_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showOther = selectedSymptoms.contains('Otro');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Diario de síntomas'),
      ),
      body: RefreshIndicator(
        onRefresh: loadEntries,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.favorite_outline_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '¿Cómo te sientes hoy?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Selecciona los síntomas que presentaste para que tu médico pueda revisar tu evolución.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Síntomas de hoy',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: symptoms.map((symptom) {
                final bool selected = selectedSymptoms.contains(symptom);
                final Color color = symptomColor(symptom);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        selectedSymptoms.remove(symptom);
                      } else {
                        selectedSymptoms.add(symptom);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.18) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? color : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          symptomIcon(symptom),
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          symptom,
                          style: TextStyle(
                            color: selected ? color : AppTheme.textDark,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (showOther) ...[
              const SizedBox(height: 16),
              _WhiteInputCard(
                child: TextField(
                  controller: otherController,
                  decoration: const InputDecoration(
                    labelText: 'Describe el síntoma',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            _WhiteInputCard(
              child: TextField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales',
                  hintText:
                      'Ejemplo: apareció al levantarme, duró pocos minutos...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: isSaving ? null : saveEntry,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'Guardando...' : 'Guardar registro'),
              ),
            ),
            const SizedBox(height: 34),
            const Text(
              'Historial reciente',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Aún no hay registros.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              )
            else
              ...entries.map((entry) {
                final List symptomsList = entry['symptoms'] ?? [];
                final String notes = entry['notes'] ?? '';
                final String otherText = entry['other_text'] ?? '';

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
                        readableDate(entry['created_at']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      if (symptomsList.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: symptomsList.map((symptom) {
                            final String symptomText = symptom.toString();
                            final Color color = symptomColor(symptomText);

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
                                symptomText,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (otherText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          otherText,
                          style: const TextStyle(color: AppTheme.textDark),
                        ),
                      ],
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          notes,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
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

class _WhiteInputCard extends StatelessWidget {
  final Widget child;

  const _WhiteInputCard({
    required this.child,
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
      child: child,
    );
  }
}
