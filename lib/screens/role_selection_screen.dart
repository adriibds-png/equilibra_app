import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/role_card.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void goToLogin(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.balance, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 24),
              const Text(
                'Equilibra',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rehabilitación vestibular y seguimiento clínico',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 48),
              RoleCard(
                title: 'Ingresar como paciente',
                subtitle: 'Cuestionarios, ejercicios y diario de síntomas',
                icon: Icons.person_outline,
                onTap: () => goToLogin(context, 'Paciente'),
              ),
              const SizedBox(height: 16),
              RoleCard(
                title: 'Ingresar como médico',
                subtitle: 'Pacientes, resultados y dashboard clínico',
                icon: Icons.medical_services_outlined,
                onTap: () => goToLogin(context, 'Médico'),
              ),
              const Spacer(),
              const Text(
                'Uso clínico institucional',
                style: TextStyle(fontSize: 13, color: AppTheme.lightText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
