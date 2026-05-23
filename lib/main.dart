import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';
import 'screens/role_selection_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vtecmludbnaaiwhzdssg.supabase.co',
    anonKey: 'sb_publishable_HMwe7QgCImJ2L6Y44NGKSg_FcyswITD',
  );

  runApp(const EquilibraApp());
}

class EquilibraApp extends StatelessWidget {
  const EquilibraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equilibra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      routes: {
        '/patients': (context) => const PatientsScreen(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool isLoading = true;
  String? role;

  @override
  void initState() {
    super.initState();
    loadUserRole();
  }

  Future<void> loadUserRole() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      setState(() {
        isLoading = false;
        role = null;
      });
      return;
    }

    try {
      final user = session.user;

      final profile = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        await Supabase.instance.client.from('user_profiles').insert({
          'id': user.id,
          'email': user.email,
          'full_name': user.email,
          'role': 'Paciente',
        });

        role = 'Paciente';
      } else {
        role = profile['role'] ?? 'Paciente';
      }
    } catch (error) {
      role = 'Paciente';
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (role == null) {
      return const RoleSelectionScreen();
    }

    return HomeScreen(role: role!);
  }
}

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F7FA),
      appBar: AppBar(
        title: Text('Pacientes'),
        backgroundColor: Color(0xFF1D5C75),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Pantalla de pacientes',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
