import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();

    if (widget.role == 'Médico') {
      emailController.text = 'aof.benavides@gmail.com';
    } else {
      emailController.text = 'adriibds@hotmail.com';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(role: widget.role)),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar sesión: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void useDoctorAccount() {
    setState(() {
      emailController.text = 'aof.benavides@gmail.com';
    });
  }

  void usePatientAccount() {
    setState(() {
      emailController.text = 'adriibds@hotmail.com';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDoctor = widget.role == 'Médico';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Login ${widget.role}'),
        backgroundColor: AppTheme.background,
      ),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Icon(
              isDoctor ? Icons.medical_services_outlined : Icons.person_outline,
              size: 54,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Ingresar como ${widget.role}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDoctor
                  ? 'Acceso para profesionales autorizados.'
                  : 'Acceso para pacientes registrados por su médico.',
              style: const TextStyle(fontSize: 16, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cuentas de prueba',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: useDoctorAccount,
                    icon: const Icon(Icons.medical_services_outlined),
                    label: const Text('Médico'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: usePatientAccount,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Paciente'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: isLoading ? null : signIn,
                child: Text(isLoading ? 'Ingresando...' : 'Iniciar sesión'),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Chrome/Edge puede guardar tu contraseña cuando inicies sesión.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
