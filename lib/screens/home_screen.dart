import 'package:flutter/material.dart';
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
  int currentIndex = 0;

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
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

    return Scaffold(
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
    );
  }
}

class PatientHomeScreen extends StatelessWidget {
  final void Function(int index) onNavigate;

  const PatientHomeScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          const Text(
            'Hola',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este es tu espacio de rehabilitación vestibular.',
            style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          _InfoCard(
            title: '¿Cómo te sientes hoy?',
            subtitle: 'Registra tus síntomas del día',
            icon: Icons.favorite_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SymptomDiaryScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Ejercicios',
            subtitle: 'Ver ejercicios asignados por tu médico',
            icon: Icons.directions_walk,
            onTap: () => onNavigate(2),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Cuestionarios',
            subtitle: 'Completa las escalas clínicas pendientes',
            icon: Icons.assignment_outlined,
            onTap: () => onNavigate(1),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Mi progreso',
            subtitle: 'Consulta tu constancia y adherencia',
            icon: Icons.bar_chart,
            onTap: () => onNavigate(3),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.softBlue,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'Recuerda realizar tus ejercicios en un lugar seguro y seguir únicamente las indicaciones de tu médico.',
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
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
              backgroundColor: AppTheme.softBlue,
              child: Icon(icon, color: AppTheme.primary, size: 30),
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
            const Icon(Icons.chevron_right, color: AppTheme.lightText),
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
                style: const TextStyle(fontSize: 16, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
