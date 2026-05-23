import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class EditPatientScreen extends StatefulWidget {
  final String patientId;
  final String currentName;
  final String currentEmail;
  final String currentDiagnosis;

  const EditPatientScreen({
    super.key,
    required this.patientId,
    required this.currentName,
    required this.currentEmail,
    required this.currentDiagnosis,
  });

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();

  bool isSaving = false;
  bool isLoadingDoctors = true;

  List<Map<String, dynamic>> doctors = [];
  String? selectedDoctorId;

  @override
  void initState() {
    super.initState();

    nameController.text = widget.currentName;
    diagnosisController.text =
        widget.currentDiagnosis == 'Sin diagnóstico registrado'
            ? ''
            : widget.currentDiagnosis;

    loadDoctors();
  }

  @override
  void dispose() {
    nameController.dispose();
    diagnosisController.dispose();
    super.dispose();
  }

  Future<void> loadDoctors() async {
    final response = await Supabase.instance.client
        .from('user_profiles')
        .select()
        .eq('role', 'Médico')
        .order('full_name');

    final loadedDoctors = List<Map<String, dynamic>>.from(response);

    setState(() {
      doctors = loadedDoctors;
      selectedDoctorId =
          doctors.isNotEmpty ? doctors.first['id'] as String : null;
      isLoadingDoctors = false;
    });
  }

  Future<void> savePatient() async {
    setState(() {
      isSaving = true;
    });

    try {
      final selectedDoctor = doctors.firstWhere(
        (doctor) => doctor['id'] == selectedDoctorId,
        orElse: () => <String, dynamic>{},
      );

      await Supabase.instance.client.from('user_profiles').update({
        'full_name': nameController.text.trim(),
        'diagnosis': diagnosisController.text.trim(),
        'doctor_id': selectedDoctorId,
        'doctor_name':
            selectedDoctor['full_name'] ?? selectedDoctor['email'] ?? '',
      }).eq('id', widget.patientId);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Editar paciente'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Datos clínicos básicos',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Completa la información principal del paciente.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 28),
          _FieldCard(
            label: 'Nombre completo',
            controller: nameController,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _FieldCard(
            label: 'Diagnóstico',
            controller: diagnosisController,
            icon: Icons.medical_information_outlined,
            hint: 'Ej. PPPD, VPPB, migraña vestibular...',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: isLoadingDoctors
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Cargando médicos...'),
                  )
                : DropdownButtonFormField<String>(
                    value: selectedDoctorId,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.badge_outlined),
                      labelText: 'Médico tratante',
                      border: InputBorder.none,
                    ),
                    items: doctors.map((doctor) {
                      final doctorId = doctor['id'] as String;
                      final doctorName = doctor['full_name'] ??
                          doctor['email'] ??
                          'Médico sin nombre';

                      return DropdownMenuItem<String>(
                        value: doctorId,
                        child: Text(doctorName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDoctorId = value;
                      });
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.softBlue,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              widget.currentEmail,
              style: const TextStyle(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : savePatient,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isSaving ? 'Guardando...' : 'Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData icon;
  final TextEditingController controller;

  const _FieldCard({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppTheme.primary),
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
