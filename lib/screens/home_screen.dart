import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import 'doctor_dashboard_screen.dart';
import 'symptom_diary_screen.dart';
import 'exercises_screen.dart';
import 'progress_screen.dart';
import 'questionnaires_screen.dart';
import 'role_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  final String role;

  const HomeScreen({super.key, required this.role});

  Future<void> logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDoctor = role == 'Médico';

    return Scaffold(
      appBar: AppBar(
        title: Text(isDoctor ? 'Panel médico' : 'Equilibra'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body:
          isDoctor ? const DoctorDashboardScreen() : const PatientMainScreen(),
    );
  }
}

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  final FocusNode focusNode = FocusNode();
  int currentIndex = 0;

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

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });

    focusNode.requestFocus();
  }

  void handleKeyboard(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      changeTab(0);
      return;
    }

    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      changeTab(1);
      return;
    }

    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      changeTab(2);
      return;
    }

    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      changeTab(3);
      return;
    }

    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      changeTab(4);
      return;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      final nextIndex = currentIndex == 4 ? 0 : currentIndex + 1;
      changeTab(nextIndex);
      return;
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      final previousIndex = currentIndex == 0 ? 4 : currentIndex - 1;
      changeTab(previousIndex);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      PatientHomeScreen(onNavigate: changeTab),
      const QuestionnairesScreen(),
      const ExercisesScreen(),
      const ProgressScreen(),
      const PlaceholderScreen(
        title: 'Perfil',
        subtitle: 'Aquí estarán tus datos básicos y opciones de cuenta.',
        icon: Icons.person_outline,
      ),
    ];

    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: handleKeyboard,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => focusNode.requestFocus(),
        child: Scaffold(
          body: screens[currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: changeTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: 'Cuestionarios',
              ),
              NavigationDestination(
                icon: Icon(Icons.directions_walk_outlined),
                selectedIcon: Icon(Icons.directions_walk),
                label: 'Ejercicios',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Progreso',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientHomeScreen extends StatefulWidget {
  final void Function(int index) onNavigate;

  const PatientHomeScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int pendingQuestionnaires = 0;
  int pendingExercises = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPendingData();
  }

  Future<void> loadPendingData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final questionnaires = await Supabase.instance.client
          .from('assigned_questionnaires')
          .select()
          .eq('patient_id', userId)
          .neq('status', 'COMPLETED');

      final assignedExercises = await Supabase.instance.client
          .from('assigned_exercises')
          .select()
          .eq('patient_id', userId);

      final logs = await Supabase.instance.client
          .from('exercise_logs')
          .select()
          .eq('patient_id', userId);

      final now = DateTime.now();
      final completedTodayNames = <String>{};

      for (final log in logs) {
        final name = log['exercise_name']?.toString() ?? '';
        final rawDate = log['created_at'];
        final date =
            rawDate == null ? null : DateTime.tryParse(rawDate.toString());

        final sameDay = date == null ||
            (date.year == now.year &&
                date.month == now.month &&
                date.day == now.day);

        if (sameDay && name.isNotEmpty) {
          completedTodayNames.add(name);
        }
      }

      final pendingExerciseList = assignedExercises.where((exercise) {
        final title = exercise['exercise_name'] ??
            exercise['title'] ??
            exercise['name'] ??
            'Ejercicio';

        return !completedTodayNames.contains(title);
      }).toList();

      setState(() {
        pendingQuestionnaires = questionnaires.length;
        pendingExercises = pendingExerciseList.length;
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        isLoading = false;
      });
    }
  }

  int get totalPending => pendingQuestionnaires + pendingExercises;

  Color get gaugeColor {
    if (totalPending == 0) return const Color(0xFF4CAF88);
    if (totalPending <= 2) return const Color(0xFFD6B64C);
    if (totalPending <= 4) return const Color(0xFFF2A65A);
    return const Color(0xFFE57373);
  }

  double get gaugeValue {
    if (totalPending == 0) return 0.18;
    if (totalPending <= 2) return 0.42;
    if (totalPending <= 4) return 0.68;
    return 0.92;
  }

  double get adherenceValue {
    if (totalPending == 0) return 1.0;
    if (totalPending <= 2) return 0.75;
    if (totalPending <= 4) return 0.55;
    return 0.35;
  }

  @override
  Widget build(BuildContext context) {
    final adherencePercent = (adherenceValue * 100).round();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadPendingData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Equilibra',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                totalPending == 0
                                    ? 'Hoy no tienes pendientes'
                                    : 'Hoy tienes $totalPending pendientes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Adherencia aproximada $adherencePercent%',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        _PendingGauge(
                          value: gaugeValue,
                          color: gaugeColor,
                          pendingCount: totalPending,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickStatCard(
                          title: 'Cuestionarios',
                          value: pendingQuestionnaires.toString(),
                          subtitle: 'Pendientes',
                          icon: Icons.assignment_outlined,
                          color: Colors.deepPurple,
                          onTap: () => widget.onNavigate(1),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _QuickStatCard(
                          title: 'Ejercicios',
                          value: pendingExercises.toString(),
                          subtitle: 'Pendientes',
                          icon: Icons.directions_walk,
                          color: Colors.teal,
                          onTap: () => widget.onNavigate(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Accesos rápidos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: '¿Cómo te sientes hoy?',
                    subtitle: 'Registra tus síntomas del día',
                    icon: Icons.favorite_outline,
                    color: Colors.pink,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SymptomDiaryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Ejercicios',
                    subtitle: 'Ver ejercicios pendientes',
                    icon: Icons.directions_walk,
                    color: Colors.teal,
                    onTap: () => widget.onNavigate(2),
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Cuestionarios',
                    subtitle: 'Completa las escalas clínicas pendientes',
                    icon: Icons.assignment_outlined,
                    color: Colors.deepPurple,
                    onTap: () => widget.onNavigate(1),
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Mi progreso',
                    subtitle: 'Consulta tu constancia y adherencia',
                    icon: Icons.bar_chart,
                    color: Colors.orange,
                    onTap: () => widget.onNavigate(3),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primary,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Recuerda realizar tus ejercicios en un lugar seguro y seguir únicamente las indicaciones de tu médico.',
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PendingGauge extends StatelessWidget {
  final double value;
  final Color color;
  final int pendingCount;

  const _PendingGauge({
    required this.value,
    required this.color,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(112, 112),
            painter: _GaugePainter(
              value: value,
              color: color,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$pendingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'pend.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;

  _GaugePainter({
    required this.value,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final radius = size.width * 0.38;

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final greenPaint = Paint()
      ..color = const Color(0xFF4CAF88)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final yellowPaint = Paint()
      ..color = const Color(0xFFD6B64C)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final orangePaint = Paint()
      ..color = const Color(0xFFF2A65A)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final redPaint = Paint()
      ..color = const Color(0xFFE57373)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi;
    const totalSweep = math.pi;

    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, startAngle, totalSweep, false, backgroundPaint);
    canvas.drawArc(rect, math.pi, math.pi * 0.25, false, greenPaint);
    canvas.drawArc(rect, math.pi * 1.27, math.pi * 0.22, false, yellowPaint);
    canvas.drawArc(rect, math.pi * 1.52, math.pi * 0.22, false, orangePaint);
    canvas.drawArc(rect, math.pi * 1.77, math.pi * 0.20, false, redPaint);

    final angle = startAngle + (totalSweep * value.clamp(0.0, 1.0));
    final needleLength = radius * 0.78;

    final needleEnd = Offset(
      center.dx + math.cos(angle) * needleLength,
      center.dy + math.sin(angle) * needleLength,
    );

    canvas.drawLine(center, needleEnd, needlePaint);

    canvas.drawCircle(
      center,
      6,
      Paint()..color = color,
    );

    canvas.drawCircle(
      center,
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
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
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.lightText,
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AppTheme.primary),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
